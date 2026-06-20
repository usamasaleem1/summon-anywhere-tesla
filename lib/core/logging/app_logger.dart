import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

/// Centralized logging for `flutter run` terminal output.
abstract final class AppLogger {
  static void debug(
    String category,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) =>
      _log('DEBUG', category, message, error: error, stackTrace: stackTrace);

  static void info(
    String category,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) =>
      _log('INFO', category, message, error: error, stackTrace: stackTrace);

  static void warn(
    String category,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) =>
      _log('WARN', category, message, error: error, stackTrace: stackTrace);

  static void error(
    String category,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) =>
      _log('ERROR', category, message, error: error, stackTrace: stackTrace);

  /// Masks a secret to show only the last 4 characters.
  static String maskToken(String? token) {
    if (token == null || token.isEmpty) return '(none)';
    if (token.length <= 4) return '****';
    return '****${token.substring(token.length - 4)}';
  }

  /// Partially masks a client ID for debugging without exposing the full value.
  static String maskClientId(String clientId) {
    if (clientId.isEmpty) return '(empty)';
    if (clientId.startsWith('YOUR_')) return '$clientId (PLACEHOLDER — not configured)';
    if (clientId.length <= 8) return '${clientId.substring(0, 2)}****';
    return '${clientId.substring(0, 4)}...${clientId.substring(clientId.length - 4)}';
  }

  /// Returns true when the value is still a placeholder constant.
  static bool isPlaceholder(String value) =>
      value.isEmpty || value.startsWith('YOUR_');

  static void _log(
    String level,
    String category,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    final line = '[$level][$category] $message';
    developer.log(
      line,
      name: 'SummonAnywhere',
      error: error,
      stackTrace: stackTrace,
    );
    if (kDebugMode) {
      // Some IDE/terminal setups filter developer.log; print ensures visibility.
      // ignore: avoid_print
      print(line);
      if (error != null) {
        // ignore: avoid_print
        print('  error: $error');
      }
      if (stackTrace != null) {
        // ignore: avoid_print
        print('  $stackTrace');
      }
    }
  }
}
