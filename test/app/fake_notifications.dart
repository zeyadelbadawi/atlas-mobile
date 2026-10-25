import 'package:atlas_mobile/core/account/account_repository.dart';

import '../design/golden_harness.dart' show testNow;

import 'package:atlas_mobile/core/api/academy_endpoint.dart';
import 'package:atlas_mobile/core/api/atlas_api_client.dart';
import 'package:atlas_mobile/core/notifications/notifications_repository.dart';
import 'package:cookie_jar/cookie_jar.dart';

AtlasApiClient _client() => AtlasApiClient(
  endpoint: AcademyEndpoint.parse('ziadd.atlass.dpdns.org'),
  cookieJar: CookieJar(),
  userAgent: 'test',
);

String _ago(Duration d) => testNow.toUtc().subtract(d).toIso8601String();

/// Sample feed for screen goldens (illustrative, not real learners).
class FakeNotificationsRepository extends NotificationsRepository {
  FakeNotificationsRepository() : super(_client());

  @override
  Future<NotificationPage> list({int page = 1}) async => NotificationPage(
    hasMore: false,
    items: [
      for (final j in [
        {
          'id': 'n1',
          'type': 'activity',
          'titleKey': 'notifications:events.assignmentGraded.title',
          'messageKey': 'notifications:events.assignmentGraded.message',
          'values': {'assignmentTitle': 'واجب: تمارين النهايات', 'score': 9},
          'isRead': false,
          'actionUrl': '/my/courses/c-calc/activities/l6',
          'createdAt': _ago(const Duration(minutes: 20)),
        },
        {
          'id': 'n2',
          'type': 'announcement',
          'titleKey': 'notifications:events.announcementPublished.title',
          'messageKey': 'notifications:events.announcementPublished.message',
          'values': {
            'academyName': 'أكاديمية زياد',
            'title': 'تأجيل حصة الخميس',
          },
          'isRead': false,
          'actionUrl': '/my/courses/c-calc',
          'createdAt': _ago(const Duration(hours: 3)),
        },
        {
          'id': 'n3',
          'type': 'activity',
          'titleKey': 'notifications:events.certificateIssued.title',
          'messageKey': 'notifications:events.certificateIssued.message',
          'values': {'courseTitle': 'الفيزياء: الكهربية الحديثة'},
          'isRead': true,
          'actionUrl': '/my/certificates',
          'createdAt': _ago(const Duration(days: 2)),
        },
        {
          'id': 'n4',
          'type': 'activity',
          'titleKey': 'notifications:events.enrollmentGranted.title',
          'messageKey': 'notifications:events.enrollmentGranted.message',
          'values': {
            'courseTitle': 'التفاضل والتكامل',
            'academyName': 'أكاديمية زياد',
          },
          'isRead': true,
          'actionUrl': '/my/courses/c-calc',
          'createdAt': _ago(const Duration(days: 9)),
        },
      ])
        AppNotification.fromJson(j),
    ],
  );

  @override
  Future<int> unreadCount() async => 2;

  @override
  Future<List<Announcement>> announcements() async => [
    Announcement.fromJson({
      'id': 'a1',
      'audience': 'course',
      'authorName': 'أ. زياد',
      'title': 'تأجيل حصة الخميس',
      'body': 'تم تأجيل حصة المراجعة إلى يوم السبت الساعة ٧ مساءً.',
      'publishedAt': _ago(const Duration(hours: 3)),
    }),
    Announcement.fromJson({
      'id': 'a2',
      'audience': 'academy',
      'authorName': 'أكاديمية زياد',
      'title': 'جدول امتحانات الشهر',
      'body': 'تجد جدول امتحانات الشهر في صفحة كل كورس.',
      'publishedAt': _ago(const Duration(days: 4)),
    }),
  ];
}

class FakeAccountRepository extends AccountRepository {
  FakeAccountRepository() : super(_client());

  @override
  Future<AccountPhone> phone() async => AccountPhone.fromJson({
    'phone': {'nationalNumber': '1012345678', 'country': 'EG'},
  });

  @override
  Future<List<AccountSession>> sessions() async => [
    AccountSession.fromJson({
      'id': 's1',
      'deviceLabel': 'Atlas app on iOS',
      'lastUsedAt': _ago(Duration.zero),
      'isCurrent': true,
    }),
    AccountSession.fromJson({
      'id': 's2',
      'deviceLabel': 'Chrome on Windows',
      'lastUsedAt': _ago(const Duration(days: 1)),
    }),
  ];

  @override
  Future<bool> learningEmails() async => true;

  @override
  Future<List<PrivacyRequest>> privacyRequests() async => const [];

  @override
  Future<bool> canDeleteFromApp() async => true;
}
