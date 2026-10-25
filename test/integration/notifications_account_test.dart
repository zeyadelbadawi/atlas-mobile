// Phase 5 against the LOCAL stack, through the app's own repositories: a
// graded assignment and a published announcement reach the learner's feed
// with texts the app can render, read state works, push devices register
// and unregister, and the account endpoints answer. Env as local_stack.dart.
@Tags(['integration'])
library;

import 'dart:convert';
import 'dart:io';

import 'package:atlas_mobile/core/account/account_repository.dart';
import 'package:atlas_mobile/core/notifications/notification_catalog.dart';
import 'package:atlas_mobile/core/notifications/notifications_repository.dart';
import 'package:test/test.dart';

import 'local_stack.dart';

void main() {
  final skip = Platform.environment['ATLAS_SPIKE_ORIGIN'] == null
      ? 'needs the local stack'
      : null;

  test(
    'notifications, announcements, push device and account',
    () async {
      final staff = await localStaff();
      final c = await authorAssessedCourse(staff);
      final me = await newLocalLearner('p5');
      await staff.post<dynamic>(
        'academies/$localAcademyId/students/${me.userId}/enrollments',
        data: {'courseId': c.courseId},
      );
      final sub = await me.client.post<Map<String, dynamic>>(
        'courses/${c.courseId}/assignments/${c.assignmentId}/submission',
        data: {'response': 'حل', 'idempotencyKey': 'p5-${me.userId}'},
      );
      await staff.post<dynamic>(
        'review/courses/${c.courseId}/assignments/${c.assignmentId}/submissions/${sub['id']}/grade',
        data: {'score': 8},
      );
      final ann = await staff.post<Map<String, dynamic>>(
        'courses/${c.courseId}/announcements',
        data: {'title': 'تأجيل الحصة', 'body': 'الحصة يوم الخميس.'},
      );
      await staff.post<dynamic>(
        'courses/${c.courseId}/announcements/${ann['id']}/publish',
      );

      final repo = NotificationsRepository(me.client);
      final catalog = NotificationCatalog({
        for (final l in ['en', 'ar'])
          l: jsonDecode(
            File('assets/l10n/notifications_$l.json').readAsStringSync(),
          ) as Map<String, dynamic>,
      });

      // The feed is written by an outbox worker: give it a moment.
      List<AppNotification> items = const [];
      for (var i = 0; i < 20; i++) {
        items = (await repo.list()).items;
        final hasGrade = items.any(
          (n) => n.titleKey.contains('assignmentGraded'),
        );
        final hasAnn = items.any(
          (n) => n.titleKey.contains('announcementPublished'),
        );
        if (hasGrade && hasAnn) break;
        await Future<void>.delayed(const Duration(milliseconds: 500));
      }
      final graded = items.firstWhere(
        (n) => n.titleKey.contains('assignmentGraded'),
      );
      expect(catalog.text(graded.titleKey, 'ar'), isNotNull);
      expect(
        catalog.text(graded.messageKey, 'ar', graded.values),
        contains('واجب: حل خمس معادلات'),
      );
      expect(graded.actionUrl, contains(c.assignmentId));

      final before = await repo.unreadCount();
      expect(before, greaterThan(0));
      await repo.markRead(graded.id);
      expect(await repo.unreadCount(), before - 1);
      await repo.markAllRead();
      expect(await repo.unreadCount(), 0);

      final anns = await repo.announcements();
      expect(anns.map((a) => a.id), contains(ann['id']));
      expect(
        (await repo.announcement(ann['id'] as String)).title,
        'تأجيل الحصة',
      );

      final deviceId = await repo.registerPushDevice(
        token: 'it-token-${me.userId}-abcdefghijklmnopqrstuvwxyz0123456789',
        platform: 'android',
        appVersion: '1.0.0',
        locale: 'ar',
      );
      expect(deviceId, isNotNull);
      await repo.removePushDevice(deviceId!);

      final account = AccountRepository(me.client);
      // Names are unique within an academy (errors.profile.nameTakenInAcademy).
      final name = 'طالب ${me.userId.substring(0, 6)}';
      final profile = await account.updateName(name);
      expect(profile.name, name);
      // Phone numbers are unique too (errors.auth.phoneTaken).
      final digits = DateTime.now().microsecondsSinceEpoch % 100000000;
      final number = '015${digits.toString().padLeft(8, '0')}';
      final phone = await account.setPhone(number, 'EG');
      expect(phone.e164, '+20${number.substring(1)}');
      final sessions = await account.sessions();
      expect(sessions.where((s) => s.isCurrent), hasLength(1));
      expect(await account.learningEmails(), isTrue);
      await account.setLearningEmails(false);
      expect(await account.learningEmails(), isFalse);
      expect(await account.canDeleteFromApp(), isTrue);
      expect(await account.privacyRequests(), isEmpty);
    },
    skip: skip,
    timeout: const Timeout(Duration(minutes: 4)),
  );
}
