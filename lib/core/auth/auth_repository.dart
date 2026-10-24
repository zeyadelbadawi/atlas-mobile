import '../api/atlas_api_client.dart';

/// What a sign-in step answered. The backend returns one of three shapes
/// from the same routes; screens switch on this instead of on raw JSON.
sealed class SignInOutcome {
  const SignInOutcome();
}

/// A real session: the access token is already stored on the client.
class SignedIn extends SignInOutcome {
  const SignedIn({required this.user, required this.authMethod});
  final Map<String, dynamic> user;
  final String? authMethod;
}

/// The academy wants the code it just emailed.
class EmailCodeRequired extends SignInOutcome {
  const EmailCodeRequired({
    required this.challengeId,
    required this.maskedEmail,
    required this.expiresAt,
    required this.resendAvailableAt,
    required this.resendsRemaining,
  });
  final String challengeId;
  final String maskedEmail;
  final DateTime expiresAt;
  final DateTime resendAvailableAt;
  final int resendsRemaining;
}

/// The account has an authenticator app.
class AuthenticatorCodeRequired extends SignInOutcome {
  const AuthenticatorCodeRequired({
    required this.challengeId,
    required this.expiresIn,
  });
  final String challengeId;
  final int expiresIn;
}

/// Sign-in, sign-up and code steps on the academy surface.
///
/// Request bodies match the backend DTOs field for field: the backend
/// rejects unknown fields (`forbidNonWhitelisted`).
class AuthRepository {
  AuthRepository(this.client, {required this.academyId});

  final AtlasApiClient client;
  final String academyId;

  Future<SignInOutcome> signIn({
    required String email,
    required String password,
  }) async {
    final body = await client.post<Map<String, dynamic>>(
      'auth/sign-in',
      data: {
        'email': email,
        'password': password,
        'surface': 'academy',
        'academyId': academyId,
      },
    );
    return _outcome(body);
  }

  Future<SignInOutcome> verifyEmailCode({
    required String challengeId,
    required String code,
    required bool rememberDevice,
  }) async {
    final body = await client.post<Map<String, dynamic>>(
      'auth/otp/verify',
      data: {
        'challengeId': challengeId,
        'code': code,
        'rememberDevice': rememberDevice,
        'surface': 'academy',
        'academyId': academyId,
      },
    );
    return _outcome(body);
  }

  /// `{ "account": "new" | "existing" }`. Does not sign in.
  Future<String> register({
    required String name,
    required String email,
    required String password,
    required String phoneNumber,
    required String phoneCountry,
  }) async {
    final body = await client.post<Map<String, dynamic>>(
      'auth/register',
      data: {
        'name': name,
        'email': email,
        'password': password,
        'academyId': academyId,
        'phoneNumber': phoneNumber,
        'phoneCountry': phoneCountry,
      },
    );
    return body['account'] as String? ?? 'new';
  }

  /// Restores a session from the stored cookie (app start).
  Future<Map<String, dynamic>?> restore() async {
    final body = await client.refreshSession();
    final user = body['user'];
    if (user is Map<String, dynamic>) return user;
    return client.get<Map<String, dynamic>>('users/me');
  }

  Future<void> signOut() => client.signOut();

  SignInOutcome _outcome(Map<String, dynamic> body) {
    if (body['emailOtpRequired'] == true) {
      return EmailCodeRequired(
        challengeId: body['challengeId'] as String,
        maskedEmail: body['maskedEmail'] as String? ?? '',
        expiresAt: DateTime.parse(body['expiresAt'] as String),
        resendAvailableAt: DateTime.parse(body['resendAvailableAt'] as String),
        resendsRemaining: (body['resendsRemaining'] as num?)?.toInt() ?? 0,
      );
    }
    if (body['twoFactorRequired'] == true) {
      return AuthenticatorCodeRequired(
        challengeId: body['challengeId'] as String,
        expiresIn: (body['expiresIn'] as num?)?.toInt() ?? 0,
      );
    }
    client.setAccessToken(body['accessToken'] as String?);
    return SignedIn(
      user: (body['user'] as Map<String, dynamic>?) ?? const {},
      authMethod: body['authMethod'] as String?,
    );
  }
}
