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

/// Sign in with Apple needs one more step: `link_required` (an existing
/// account; ask for its password) or `create_account` (new; ask for phone and
/// consents).
class AppleStepRequired extends SignInOutcome {
  const AppleStepRequired({
    required this.step,
    required this.pending,
    required this.email,
    this.name,
  });
  final String step;
  final String pending;
  final String email;
  final String? name;
  bool get linkRequired => step == 'link_required';
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
  ///
  /// [consents] is what the sign-up screen showed and the learner accepted
  /// (B4): `{source, termsVersion, privacyVersion, ageConfirmed: true}`.
  Future<String> register({
    required String name,
    required String email,
    required String password,
    required String phoneNumber,
    required String phoneCountry,
    Map<String, Object>? consents,
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
        'consents': ?consents,
      },
    );
    return body['account'] as String? ?? 'new';
  }

  /// An existing Atlas account joins this academy with its own password.
  /// Does not sign in; call [signIn] next.
  Future<void> joinAcademy({required String email, required String password}) =>
      client.post<dynamic>(
        'auth/academy-join',
        data: {'email': email, 'password': password, 'academyId': academyId},
      );

  Future<void> requestPasswordReset(String email) => client.post<dynamic>(
    'auth/password-reset/request',
    data: {'email': email},
  );

  /// `{resendAvailableAt, resendsRemaining}`.
  Future<(DateTime, int)> resendEmailCode(String challengeId) async {
    final body = await client.post<Map<String, dynamic>>(
      'auth/otp/resend',
      data: {'challengeId': challengeId},
    );
    return (
      DateTime.parse(body['resendAvailableAt'] as String),
      (body['resendsRemaining'] as num?)?.toInt() ?? 0,
    );
  }

  Future<SignInOutcome> verifyAuthenticatorCode({
    required String challengeId,
    String? token,
    String? recoveryCode,
  }) async {
    final body = await client.post<Map<String, dynamic>>(
      'auth/2fa/verify',
      data: {
        'challengeId': challengeId,
        'token': ?token,
        'recoveryCode': ?recoveryCode,
        'surface': 'academy',
        'academyId': academyId,
      },
    );
    return _outcome(body);
  }

  /// Sign in with Apple (B2). [rawNonce] is the value whose SHA-256 was
  /// given to Apple.
  Future<SignInOutcome> appleNative({
    required String identityToken,
    required String rawNonce,
    String? authorizationCode,
    String? givenName,
    String? familyName,
  }) async {
    final body = await client.post<Map<String, dynamic>>(
      'auth/apple/native',
      data: {
        'identityToken': identityToken,
        'rawNonce': rawNonce,
        'authorizationCode': ?authorizationCode,
        'givenName': ?givenName,
        'familyName': ?familyName,
        'academyId': academyId,
      },
    );
    return _outcome(body);
  }

  Future<SignInOutcome> appleLink({
    required String pending,
    required String password,
  }) async {
    final body = await client.post<Map<String, dynamic>>(
      'auth/apple/link',
      data: {'pending': pending, 'password': password},
    );
    return _outcome(body);
  }

  Future<SignInOutcome> appleCreateAccount({
    required String pending,
    required String name,
    required String phoneNumber,
    required String phoneCountry,
    required Map<String, Object> consents,
  }) async {
    final body = await client.post<Map<String, dynamic>>(
      'auth/apple/create-account',
      data: {
        'pending': pending,
        'name': name,
        'phoneNumber': phoneNumber,
        'phoneCountry': phoneCountry,
        'consents': consents,
      },
    );
    return _outcome(body);
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
    if (body['appleStep'] is String) {
      return AppleStepRequired(
        step: body['appleStep'] as String,
        pending: body['pending'] as String,
        email: body['email'] as String? ?? '',
        name: body['name'] as String?,
      );
    }
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
