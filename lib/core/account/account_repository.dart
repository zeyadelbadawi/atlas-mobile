import '../api/atlas_api_client.dart';

DateTime? _date(Object? v) =>
    v is String ? DateTime.tryParse(v)?.toLocal() : null;

class AccountProfile {
  AccountProfile.fromJson(Map<String, dynamic> j)
    : id = j['id'] as String? ?? '',
      name = j['name'] as String? ?? '',
      email = j['email'] as String? ?? '',
      raw = j;

  final String id;
  final String name;
  final String email;

  final Map<String, dynamic> raw;
}

class AccountPhone {
  AccountPhone.fromJson(Map<String, dynamic> j)
    : nationalNumber = (j['phone'] as Map?)?['nationalNumber'] as String?,
      country = (j['phone'] as Map?)?['country'] as String? ?? 'EG',
      e164 = (j['phone'] as Map?)?['e164'] as String?;

  final String? nationalNumber;
  final String country;
  final String? e164;
}

class AccountSession {
  AccountSession.fromJson(Map<String, dynamic> j)
    : id = j['id'] as String? ?? '',
      deviceLabel = j['deviceLabel'] as String? ?? '',
      lastUsedAt = _date(j['lastUsedAt']) ?? _date(j['startedAt']),
      isCurrent = j['isCurrent'] == true;

  final String id;
  final String deviceLabel;
  final DateTime? lastUsedAt;
  final bool isCurrent;
}

class PrivacyRequest {
  PrivacyRequest.fromJson(Map<String, dynamic> j)
    : id = j['id'] as String? ?? '',
      type = j['type'] as String? ?? 'export',
      status = j['status'] as String? ?? 'submitted',
      createdAt = _date(j['createdAt']),
      exportAvailableUntil = _date(j['exportAvailableUntil']),
      canDownload = j['canDownload'] == true;

  final String id;
  final String type;
  final String status;
  final DateTime? createdAt;
  final DateTime? exportAvailableUntil;
  final bool canDownload;
}

/// An emailed 6-digit code that confirms a deletion or an export.
class EmailChallenge {
  EmailChallenge.fromJson(Map<String, dynamic> j)
    : challengeId = j['challengeId'] as String? ?? '',
      maskedEmail = j['maskedEmail'] as String? ?? '';

  final String challengeId;
  final String maskedEmail;
}

/// The signed-in learner's own account: profile, phone, password, sign-in
/// sessions, email preferences, data export and deletion.
class AccountRepository {
  AccountRepository(this.client);

  final AtlasApiClient client;

  Future<AccountProfile> me() async => AccountProfile.fromJson(
    await client.get<Map<String, dynamic>>('users/me'),
  );

  Future<AccountProfile> updateName(String name) async =>
      AccountProfile.fromJson(
        await client.patch<Map<String, dynamic>>(
          'users/me',
          data: {'name': name},
        ),
      );

  Future<AccountPhone> phone() async => AccountPhone.fromJson(
    await client.get<Map<String, dynamic>>('users/me/phone'),
  );

  Future<AccountPhone> setPhone(String number, String country) async =>
      AccountPhone.fromJson(
        await client.put<Map<String, dynamic>>(
          'users/me/phone',
          data: {'phoneNumber': number, 'phoneCountry': country},
        ),
      );

  /// The server then ends EVERY session, this one included.
  Future<void> changePassword(String current, String next) =>
      client.post<dynamic>(
        'users/me/password',
        data: {'currentPassword': current, 'newPassword': next},
      );

  Future<void> resendEmailVerification() =>
      client.post<dynamic>('auth/verify-email/resend', data: const {});

  Future<List<AccountSession>> sessions() async {
    final body = await client.get<List<dynamic>>('auth/sessions');
    return body
        .whereType<Map>()
        .map((m) => AccountSession.fromJson(Map<String, dynamic>.from(m)))
        .toList();
  }

  Future<void> revokeSession(String id) =>
      client.delete<dynamic>('auth/sessions/$id');

  Future<void> revokeOtherSessions() =>
      client.post<dynamic>('auth/sessions/revoke-others', data: const {});

  /// Learning emails (grades, announcements, reminders); security and
  /// account emails cannot be turned off.
  Future<bool> learningEmails() async {
    final body = await client.get<Map<String, dynamic>>(
      'users/me/communication-preferences',
    );
    final engagement = (body['categories'] as Map?)?['engagement'];
    return engagement is Map ? engagement['email'] != false : true;
  }

  Future<void> setLearningEmails(bool on) => client.patch<dynamic>(
    'users/me/communication-preferences',
    data: {
      'engagement': {'email': on},
    },
  );

  Future<List<PrivacyRequest>> privacyRequests() async {
    final body = await client.get<List<dynamic>>('privacy-requests/mine');
    return body
        .whereType<Map>()
        .map((m) => PrivacyRequest.fromJson(Map<String, dynamic>.from(m)))
        .toList();
  }

  Future<EmailChallenge> requestPrivacyCode() async => EmailChallenge.fromJson(
    await client.post<Map<String, dynamic>>(
      'privacy-requests/code',
      data: const {},
    ),
  );

  Future<PrivacyRequest> fileExport(EmailChallenge c, String code) async =>
      PrivacyRequest.fromJson(
        await client.post<Map<String, dynamic>>(
          'privacy-requests',
          data: {'type': 'export', 'challengeId': c.challengeId, 'code': code},
        ),
      );

  /// The export bundle (JSON), while its download window is open.
  Future<Object?> downloadExport(String id) =>
      client.get<dynamic>('privacy-requests/mine/$id/export');

  Future<bool> canDeleteFromApp() async {
    final body = await client.get<Map<String, dynamic>>(
      'users/me/learner-deletion',
    );
    return body['allowed'] == true;
  }

  Future<EmailChallenge> requestDeletionCode() async => EmailChallenge.fromJson(
    await client.post<Map<String, dynamic>>(
      'users/me/learner-deletion/request',
      data: const {},
    ),
  );

  Future<void> deleteAccount(EmailChallenge c, String code) =>
      client.post<dynamic>(
        'users/me/learner-deletion',
        data: {'confirm': true, 'challengeId': c.challengeId, 'code': code},
      );
}
