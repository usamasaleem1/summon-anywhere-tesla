import 'package:dio/dio.dart';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../logging/app_logger.dart';
import '../storage/secure_storage.dart';

part 'auth_service.g.dart';

/// Set via `--dart-define-from-file=secrets.json` (see secrets.json.example).
///
/// "Client authentication failed" on Tesla's sign-in page usually means:
/// - client_id is wrong or still the placeholder below
/// - redirect_uri does not exactly match what is registered in the Tesla portal
///   (scheme, host, path — including trailing slashes)
/// - the OAuth app is not enabled / approved for the Fleet API audience
const teslaClientId = String.fromEnvironment(
  'TESLA_CLIENT_ID',
  defaultValue: 'YOUR_TESLA_CLIENT_ID',
);

/// Required for Fleet API token exchange. Set via secrets.json at build time.
///
/// Must match the client secret from the Tesla developer portal for [teslaClientId].
const teslaClientSecret = String.fromEnvironment(
  'TESLA_CLIENT_SECRET',
  defaultValue: 'YOUR_TESLA_CLIENT_SECRET',
);

/// Must be registered verbatim in the Tesla developer portal under Redirect URIs.
/// Custom scheme format: `com.summonanywhere.auth://app/callback`
const teslaRedirectUri = 'com.summonanywhere.auth://app/callback';

const teslaFleetAudience = 'https://fleet-api.prd.na.vn.cloud.tesla.com';

const teslaScopes = [
  'openid',
  'offline_access',
  'user_data',
  'vehicle_device_data',
  'vehicle_cmds',
  'vehicle_location',
];

@Riverpod(keepAlive: true)
AuthService authService(Ref ref) {
  return AuthService(ref.watch(secureStorageProvider));
}

class AuthService {
  AuthService(this._storage);

  final SecureStorage _storage;
  final FlutterAppAuth _appAuth = const FlutterAppAuth();
  final Dio _tokenDio = Dio(
    BaseOptions(contentType: Headers.formUrlEncodedContentType),
  );

  static const _authorizationEndpoint =
      'https://auth.tesla.com/oauth2/v3/authorize';
  static const _tokenEndpoint =
      'https://fleet-auth.prd.vn.cloud.tesla.com/oauth2/v3/token';

  AuthorizationServiceConfiguration get _serviceConfig =>
      const AuthorizationServiceConfiguration(
        authorizationEndpoint: _authorizationEndpoint,
        tokenEndpoint: _tokenEndpoint,
      );

  /// Logs OAuth configuration at startup (secrets masked). Call from main().
  static void logOAuthConfigSummary() {
    AppLogger.info('AUTH', 'OAuth configuration summary:');
    AppLogger.info('AUTH', '  client_id: ${maskClientId(teslaClientId)}');
    AppLogger.info(
      'AUTH',
      '  client_secret: ${isPlaceholder(teslaClientSecret) ? "(PLACEHOLDER — not configured)" : "(set, ${teslaClientSecret.length} chars)"}',
    );
    AppLogger.info('AUTH', '  redirect_uri: $teslaRedirectUri');
    AppLogger.info('AUTH', '  audience: $teslaFleetAudience');
    AppLogger.info('AUTH', '  scopes: ${teslaScopes.join(" ")}');
    AppLogger.info('AUTH', '  authorize_endpoint: $_authorizationEndpoint');
    AppLogger.info('AUTH', '  token_endpoint: $_tokenEndpoint');

    if (isPlaceholder(teslaClientId) || isPlaceholder(teslaClientSecret)) {
      AppLogger.warn(
        'AUTH',
        'Tesla credentials are still placeholders — OAuth will fail with '
        '"client authentication failed" until real values are set in secrets.json '
        'and passed via --dart-define-from-file=secrets.json',
      );
    }
  }

  static String maskClientId(String clientId) => AppLogger.maskClientId(clientId);

  static bool isPlaceholder(String value) => AppLogger.isPlaceholder(value);

  Future<bool> isAuthenticated() async {
    final hasTokens = await _storage.hasTokens();
    AppLogger.debug('AUTH', 'isAuthenticated: $hasTokens');
    return hasTokens;
  }

  Future<void> signIn() async {
    AppLogger.info('AUTH', 'Starting Tesla OAuth sign-in');
    _logAuthorizeParams();

    try {
      AppLogger.debug('AUTH', 'Calling authorize…');
      final authResult = await _appAuth.authorize(
        AuthorizationRequest(
          teslaClientId,
          teslaRedirectUri,
          serviceConfiguration: _serviceConfig,
          scopes: teslaScopes,
          additionalParameters: {'audience': teslaFleetAudience},
        ),
      );

      final code = authResult.authorizationCode;
      if (code == null) {
        AppLogger.error('AUTH', 'OAuth failed — no authorization code returned');
        throw AuthException('Tesla OAuth failed — no authorization code returned.');
      }

      AppLogger.debug('AUTH', 'Authorization code received — exchanging for tokens');
      final tokens = await _exchangeAuthorizationCode(
        code: code,
        codeVerifier: authResult.codeVerifier,
      );

      AppLogger.info(
        'AUTH',
        'Token exchange returned: '
        'accessToken=${AppLogger.maskToken(tokens.accessToken)}, '
        'refreshToken=${AppLogger.maskToken(tokens.refreshToken)}, '
        'expiry=${tokens.expiry}',
      );

      if (tokens.accessToken == null || tokens.refreshToken == null) {
        AppLogger.error('AUTH', 'OAuth failed — no tokens returned');
        throw AuthException('Tesla OAuth failed — no tokens returned.');
      }

      await _storage.saveTokens(
        accessToken: tokens.accessToken!,
        refreshToken: tokens.refreshToken!,
        expiry: tokens.expiry,
      );
      AppLogger.info(
        'AUTH',
        'Tokens saved; access=${AppLogger.maskToken(tokens.accessToken)}, '
        'expiry=${tokens.expiry}',
      );
    } catch (e, st) {
      AppLogger.error(
        'AUTH',
        'OAuth sign-in failed',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  void _logAuthorizeParams() {
    AppLogger.debug('AUTH', 'Authorization request parameters:');
    AppLogger.debug('AUTH', '  client_id: ${maskClientId(teslaClientId)}');
    AppLogger.debug('AUTH', '  redirect_uri: $teslaRedirectUri');
    AppLogger.debug('AUTH', '  scope: ${teslaScopes.join(" ")}');
    AppLogger.debug('AUTH', '  audience: $teslaFleetAudience');
    AppLogger.debug('AUTH', '  authorize_endpoint: $_authorizationEndpoint');
    AppLogger.debug('AUTH', '  token_endpoint: $_tokenEndpoint');
    AppLogger.debug(
      'AUTH',
      '  PKCE: flutter_appauth uses S256 code_challenge by default',
    );
    AppLogger.debug(
      'AUTH',
      '  Expected authorize URL shape: '
      '$_authorizationEndpoint?client_id=<id>&redirect_uri=$teslaRedirectUri'
      '&response_type=code&scope=${teslaScopes.join("%20")}'
      '&audience=${Uri.encodeComponent(teslaFleetAudience)}&code_challenge=…&code_challenge_method=S256',
    );
  }

  Future<String?> getValidAccessToken() async {
    final accessToken = await _storage.getAccessToken();
    if (accessToken == null) {
      AppLogger.debug('AUTH', 'No stored access token');
      return null;
    }

    AppLogger.debug(
      'AUTH',
      'Stored access token present: ${AppLogger.maskToken(accessToken)}',
    );

    final expiry = await _storage.getTokenExpiry();
    if (expiry != null &&
        expiry.isAfter(DateTime.now().add(const Duration(minutes: 2)))) {
      AppLogger.debug('AUTH', 'Access token still valid until $expiry');
      return accessToken;
    }

    AppLogger.info('AUTH', 'Access token expired or expiring soon — refreshing');
    return _refreshAccessToken();
  }

  Future<String?> _refreshAccessToken() async {
    final refreshToken = await _storage.getRefreshToken();
    if (refreshToken == null) {
      AppLogger.warn('AUTH', 'No refresh token available');
      return null;
    }

    AppLogger.debug(
      'AUTH',
      'Refreshing token; refresh=${AppLogger.maskToken(refreshToken)}',
    );

    try {
      final tokens = await _refreshTokens(refreshToken);

      AppLogger.info(
        'AUTH',
        'Token refresh response: '
        'accessToken=${AppLogger.maskToken(tokens.accessToken)}, '
        'expiry=${tokens.expiry}',
      );

      if (tokens.accessToken == null) {
        AppLogger.warn('AUTH', 'Token refresh returned no access token');
        return null;
      }

      await _storage.saveTokens(
        accessToken: tokens.accessToken!,
        refreshToken: tokens.refreshToken ?? refreshToken,
        expiry: tokens.expiry,
      );
      AppLogger.info(
        'AUTH',
        'Refreshed tokens saved; access=${AppLogger.maskToken(tokens.accessToken)}',
      );

      return tokens.accessToken;
    } catch (e, st) {
      AppLogger.error(
        'AUTH',
        'Token refresh failed',
        error: e,
        stackTrace: st,
      );
      return null;
    }
  }

  Future<void> signOut() async {
    AppLogger.info('AUTH', 'Signing out — clearing stored tokens');
    await _storage.clearTokens();
  }

  Future<_TeslaTokens> _exchangeAuthorizationCode({
    required String code,
    String? codeVerifier,
  }) async {
    final body = <String, String>{
      'grant_type': 'authorization_code',
      'client_id': teslaClientId,
      'client_secret': teslaClientSecret,
      'code': code,
      'audience': teslaFleetAudience,
      'redirect_uri': teslaRedirectUri,
    };
    if (codeVerifier != null) {
      body['code_verifier'] = codeVerifier;
    }

    return _requestTokens(body);
  }

  Future<_TeslaTokens> _refreshTokens(String refreshToken) {
    return _requestTokens({
      'grant_type': 'refresh_token',
      'client_id': teslaClientId,
      'refresh_token': refreshToken,
    });
  }

  Future<_TeslaTokens> _requestTokens(Map<String, String> body) async {
    try {
      final response = await _tokenDio.post<Map<String, dynamic>>(
        _tokenEndpoint,
        data: body,
      );
      return _TeslaTokens.fromJson(response.data);
    } on DioException catch (e) {
      final data = e.response?.data;
      final description = data is Map
          ? '${data['error']}: ${data['error_description'] ?? data['message']}'
          : e.message;
      AppLogger.error('AUTH', 'Token request failed: $description');
      rethrow;
    }
  }
}

class _TeslaTokens {
  const _TeslaTokens({
    required this.accessToken,
    required this.refreshToken,
    required this.expiry,
  });

  final String? accessToken;
  final String? refreshToken;
  final DateTime expiry;

  factory _TeslaTokens.fromJson(Map<String, dynamic>? json) {
    final expiresIn = json?['expires_in'];
    final expiry = expiresIn is num
        ? DateTime.now().add(Duration(seconds: expiresIn.round()))
        : DateTime.now().add(const Duration(hours: 8));

    return _TeslaTokens(
      accessToken: json?['access_token'] as String?,
      refreshToken: json?['refresh_token'] as String?,
      expiry: expiry,
    );
  }
}

class AuthException implements Exception {
  AuthException(this.message);
  final String message;

  @override
  String toString() => message;
}
