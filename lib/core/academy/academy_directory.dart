import 'package:dio/dio.dart';

import '../api/academy_endpoint.dart';
import '../api/api_error.dart';
import '../config/app_env.dart';
import 'academy.dart';

/// Turns what a learner typed (a link, a host, or a short name) into an
/// academy, using the public resolve route on Atlas's own host.
class AcademyDirectory {
  AcademyDirectory({Dio? dio, this.platformHost = AppEnv.platformHost})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 20),
              headers: {'Accept': 'application/json'},
            ),
          );

  final Dio _dio;
  final String platformHost;

  /// `ziadd` → `ziadd.<platformHost>`; links and hosts are used as given.
  /// Returns null when the text cannot be a host.
  String? hostFor(String input) {
    final text = input.trim().toLowerCase();
    if (text.isEmpty) return null;
    if (RegExp(r'^[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?$').hasMatch(text)) {
      return '$text.$platformHost';
    }
    try {
      final host = AcademyEndpoint.parse(text).host;
      return host.contains('.') ? host : null;
    } on FormatException {
      return null;
    }
  }

  Future<Academy> resolve(String host) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        'https://$platformHost/api/v1/public/websites/resolve',
        queryParameters: {'hostname': host},
      );
      final body = res.data;
      if (body == null || body['academyId'] is! String) {
        throw const AtlasApiException(
          kind: 'not_found',
          messageKey: 'errors.academy.notFound',
          status: 404,
        );
      }
      return Academy.fromResolve(body, fallbackHost: host);
    } on DioException catch (e) {
      final err = AtlasApiException.fromDio(e);
      if (err.status == 404) {
        throw const AtlasApiException(
          kind: 'not_found',
          messageKey: 'errors.academy.notFound',
          status: 404,
        );
      }
      throw err;
    }
  }

  /// `GET /public/mobile/config` (B5). Null when it cannot be read; the app
  /// then runs with defaults.
  Future<Map<String, dynamic>?> mobileConfig() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        'https://$platformHost/api/v1/public/mobile/config',
      );
      return res.data;
    } on DioException {
      return null;
    }
  }
}
