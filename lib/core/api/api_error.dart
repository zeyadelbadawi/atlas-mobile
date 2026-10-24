import 'package:dio/dio.dart';

/// The backend's `NormalizedApiError` (`{ error: { kind, messageKey, status,
/// requestId, retryable, fields? } }`), or a transport failure mapped onto
/// the same shape so screens handle one error type.
class AtlasApiException implements Exception {
  const AtlasApiException({
    required this.kind,
    required this.messageKey,
    this.status,
    this.requestId,
    this.retryable = false,
    this.fields = const {},
  });

  /// Parses a Dio failure. Never throws.
  factory AtlasApiException.fromDio(DioException error) {
    final response = error.response;
    final body = response?.data;
    if (body is Map && body['error'] is Map) {
      final e = body['error'] as Map;
      return AtlasApiException(
        kind: (e['kind'] as String?) ?? 'unknown',
        messageKey: (e['messageKey'] as String?) ?? 'errors.unknown',
        status: (e['status'] as num?)?.toInt() ?? response?.statusCode,
        requestId: e['requestId'] as String?,
        retryable: e['retryable'] == true,
        fields: _fields(e['fields']),
      );
    }
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const AtlasApiException(
          kind: 'timeout',
          messageKey: 'errors.network.timeout',
          retryable: true,
        );
      case DioExceptionType.connectionError:
        return const AtlasApiException(
          kind: 'network',
          messageKey: 'errors.network.offline',
          retryable: true,
        );
      default:
        return AtlasApiException(
          kind: 'unknown',
          messageKey: 'errors.unknown',
          status: response?.statusCode,
          retryable: (response?.statusCode ?? 0) >= 500,
        );
    }
  }

  final String kind;

  /// An i18n key from the backend's catalogue (`errors.auth.phoneTaken`, …).
  final String messageKey;
  final int? status;
  final String? requestId;
  final bool retryable;

  /// Field name → message key, for form errors.
  final Map<String, String> fields;

  static Map<String, String> _fields(Object? raw) {
    if (raw is! Map) return const {};
    final out = <String, String>{};
    raw.forEach((key, value) {
      if (value is String) out['$key'] = value;
      if (value is Map && value['messageKey'] is String) {
        out['$key'] = value['messageKey'] as String;
      }
    });
    return out;
  }

  @override
  String toString() => 'AtlasApiException($status $kind $messageKey)';
}
