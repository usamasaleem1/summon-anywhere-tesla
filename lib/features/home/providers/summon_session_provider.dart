import 'dart:async';

import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/logging/app_logger.dart';
import '../../../core/storage/prefs_storage.dart';
import '../../../core/storage/secure_storage.dart';
import '../../background/summon_task_handler.dart';

part 'summon_session_provider.g.dart';

const summonSessionDuration = Duration(minutes: 5);

class SummonSessionState {
  const SummonSessionState({
    this.isActive = false,
    this.remaining = summonSessionDuration,
    this.error,
  });

  final bool isActive;
  final Duration remaining;
  final String? error;

  SummonSessionState copyWith({
    bool? isActive,
    Duration? remaining,
    String? error,
    bool clearError = false,
  }) {
    return SummonSessionState(
      isActive: isActive ?? this.isActive,
      remaining: remaining ?? this.remaining,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

@riverpod
class SummonSession extends _$SummonSession {
  Timer? _countdownTimer;
  DateTime? _sessionEnd;

  @override
  SummonSessionState build() {
    ref.onDispose(() {
      _countdownTimer?.cancel();
    });
    return const SummonSessionState();
  }

  Future<bool> start() async {
    AppLogger.info('SUMMON', 'Session start requested');

    final vehicleId = ref.read(prefsStorageProvider).selectedVehicleId;
    if (vehicleId == null || vehicleId.isEmpty) {
      AppLogger.warn('SUMMON', 'Start blocked — no vehicle selected');
      state = state.copyWith(error: 'No vehicle selected');
      return false;
    }

    final storage = ref.read(secureStorageProvider);
    final accessToken = await storage.getAccessToken();
    if (accessToken == null) {
      AppLogger.warn('SUMMON', 'Start blocked — not authenticated');
      state = state.copyWith(error: 'Not authenticated');
      return false;
    }

    AppLogger.debug(
      'SUMMON',
      'Saving task data — vehicleId=$vehicleId, '
          'token=${AppLogger.maskToken(accessToken)}',
    );
    await FlutterForegroundTask.saveData(key: 'vehicleId', value: vehicleId);
    await FlutterForegroundTask.saveData(
      key: 'accessToken',
      value: accessToken,
    );

    AppLogger.info('SUMMON', 'Starting foreground service…');
    final result = await FlutterForegroundTask.startService(
      notificationTitle: 'Summon Anywhere',
      notificationText: 'Syncing vehicle GPS to phone…',
      callback: startSummonCallback,
    );

    if (result case ServiceRequestFailure(:final error)) {
      AppLogger.error(
        'SUMMON',
        'Foreground service failed to start',
        error: error,
      );
      state = state.copyWith(error: 'Failed to start background service');
      return false;
    }

    _sessionEnd = DateTime.now().add(summonSessionDuration);
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _tick();
    });

    state = const SummonSessionState(isActive: true);
    AppLogger.info(
      'SUMMON',
      'Session active — ends at $_sessionEnd (${summonSessionDuration.inMinutes} min)',
    );
    return true;
  }

  void _tick() {
    final end = _sessionEnd;
    if (end == null) return;

    final remaining = end.difference(DateTime.now());
    if (remaining <= Duration.zero) {
      AppLogger.info('SUMMON', 'Session timer expired — stopping');
      stop();
      return;
    }

    state = state.copyWith(remaining: remaining);
  }

  Future<void> stop() async {
    AppLogger.info('SUMMON', 'Session stop requested');
    _countdownTimer?.cancel();
    _sessionEnd = null;
    await FlutterForegroundTask.stopService();
    state = const SummonSessionState();
    AppLogger.info('SUMMON', 'Session stopped');
  }
}
