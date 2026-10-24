import 'dart:async';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';

import 'academy_endpoint.dart';
import 'api_error.dart';

/// Called when the session cannot be refreshed any more (expired, revoked,
/// signed out elsewhere). The app sends the learner back to sign-in.
typedef SessionLostCallback = void Function(AtlasApiException reason);

/// HTTP client for ONE academy.
///
/// How the session works, without any backend change:
///
/// * The 15-minute access token comes back in JSON bodies and lives only in
///   memory here ([accessToken]).
/// * The refresh token never appears in a body: the backend puts it in the
///   HttpOnly session cookie. HttpOnly only hides a cookie from JavaScript in
///   a browser; this client reads `Set-Cookie` and keeps it in [cookieJar].
/// * `/auth/refresh` and `/auth/sign-out` only accept the cookie together
///   with an `Origin` equal to the academy's own origin. Browsers add that
///   header themselves; this client adds it to those two routes.
/// * Refresh tokens rotate and a reused one is treated as theft, so at most
///   one refresh runs at a time ([refreshSession] is single-flight).
class AtlasApiClient {
  AtlasApiClient({
    required this.endpoint,
    required this.cookieJar,
    required String userAgent,
    String? acceptLanguage,
    this.onSessionLost,
    HttpClientAdapter? httpClientAdapter,
    Duration connectTimeout = const Duration(seconds: 15),
    Duration receiveTimeout = const Duration(seconds: 30),
  }) : dio = Dio(
         BaseOptions(
           baseUrl: endpoint.apiBase,
           connectTimeout: connectTimeout,
           receiveTimeout: receiveTimeout,
           headers: {
             'User-Agent': userAgent,
             'Accept': 'application/json',
             'Accept-Language': ?acceptLanguage,
           },
           contentType: Headers.jsonContentType,
         ),
       ) {
    if (httpClientAdapter != null) dio.httpClientAdapter = httpClientAdapter;
    dio.interceptors
      ..add(CookieManager(cookieJar))
      ..add(_AuthInterceptor(this));
  }

  /// Paths (relative to `/api/v1/`) that authenticate with the cookie and
  /// therefore need the `Origin` header.
  static const cookieRoutes = {'auth/refresh', 'auth/sign-out'};

  /// Paths that must never trigger an automatic refresh-and-retry.
  static const _noRetryPrefixes = ['auth/'];

  final AcademyEndpoint endpoint;
  final CookieJar cookieJar;
  final Dio dio;
  final SessionLostCallback? onSessionLost;

  String? _accessToken;
  Future<Map<String, dynamic>>? _refreshInFlight;

  String? get accessToken => _accessToken;

  /// Stores a token from a sign-in, OTP or 2FA response.
  void setAccessToken(String? token) => _accessToken = token;

  /// Rotates the session from the cookie. Concurrent callers share one
  /// request. Returns the refresh body (`accessToken`, `expiresIn`, `user?`).
  Future<Map<String, dynamic>> refreshSession() {
    return _refreshInFlight ??= _doRefresh().whenComplete(() {
      _refreshInFlight = null;
    });
  }

  Future<Map<String, dynamic>> _doRefresh() async {
    try {
      final response = await dio.post<Map<String, dynamic>>(
        'auth/refresh',
        data: const <String, dynamic>{},
        options: Options(extra: const {_skipAuth: true}),
      );
      final body = response.data ?? const {};
      _accessToken = body['accessToken'] as String?;
      return body;
    } on DioException catch (e) {
      final error = AtlasApiException.fromDio(e);
      // A transport failure is not a lost session: keep the cookie and let
      // the caller retry when the network is back.
      if (error.status == 401 || error.status == 403) {
        _accessToken = null;
        onSessionLost?.call(error);
      }
      throw error;
    }
  }

  /// Ends the session on the server and forgets this academy's cookies.
  Future<void> signOut() async {
    try {
      await dio.post<void>('auth/sign-out', data: const <String, dynamic>{});
    } on DioException {
      // Signing out of a session the server already dropped is fine.
    } finally {
      _accessToken = null;
      await cookieJar.delete(endpoint.origin, true);
    }
  }

  // --- small helpers so feature code never touches Dio errors -------------

  Future<T> get<T>(String path, {Map<String, dynamic>? query}) =>
      _wrap(() => dio.get<T>(path, queryParameters: query));

  Future<T> post<T>(String path, {Object? data}) =>
      _wrap(() => dio.post<T>(path, data: data ?? const <String, dynamic>{}));

  Future<T> put<T>(String path, {Object? data}) =>
      _wrap(() => dio.put<T>(path, data: data ?? const <String, dynamic>{}));

  Future<T> patch<T>(String path, {Object? data}) =>
      _wrap(() => dio.patch<T>(path, data: data ?? const <String, dynamic>{}));

  Future<T> delete<T>(String path) => _wrap(() => dio.delete<T>(path));

  Future<T> _wrap<T>(Future<Response<T>> Function() call) async {
    try {
      final response = await call();
      return response.data as T;
    } on DioException catch (e) {
      throw e.error is AtlasApiException
          ? e.error! as AtlasApiException
          : AtlasApiException.fromDio(e);
    }
  }

  static bool _canRetry(String path) =>
      !_noRetryPrefixes.any((prefix) => path.startsWith(prefix));
}

const _skipAuth = 'atlas.skipAuth';
const _retried = 'atlas.retried';

class _AuthInterceptor extends Interceptor {
  _AuthInterceptor(this.client);

  final AtlasApiClient client;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (AtlasApiClient.cookieRoutes.contains(options.path)) {
      options.headers['Origin'] = client.endpoint.originHeader;
    }
    final token = client.accessToken;
    if (token != null && options.extra[_skipAuth] != true) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final options = err.requestOptions;
    final shouldRetry =
        err.response?.statusCode == 401 &&
        options.extra[_retried] != true &&
        options.extra[_skipAuth] != true &&
        AtlasApiClient._canRetry(options.path);
    if (!shouldRetry) return handler.next(err);

    try {
      await client.refreshSession();
    } on AtlasApiException catch (refreshError) {
      return handler.next(
        DioException(
          requestOptions: options,
          response: err.response,
          type: err.type,
          error: refreshError,
        ),
      );
    }

    try {
      options.extra[_retried] = true;
      options.headers['Authorization'] = 'Bearer ${client.accessToken}';
      final retried = await client.dio.fetch<dynamic>(options);
      handler.resolve(retried);
    } on DioException catch (retryError) {
      handler.next(retryError);
    }
  }
}
