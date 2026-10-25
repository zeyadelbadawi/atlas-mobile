// Prints the phase 5 API shapes from the LOCAL stack: notifications,
// announcements, profile, phone, password, sessions, privacy requests,
// learner deletion and push devices. Env as local_stack.dart, plus
// ATLAS_PROBE_OUT=<file>.
@Tags(['integration'])
library;

import 'dart:convert';
import 'dart:io';

import 'package:atlas_mobile/core/api/api_error.dart';
import 'package:test/test.dart';

import 'local_stack.dart';

void main() {
  final env = Platform.environment;
  final skip = env['ATLAS_PROBE_OUT'] == null ? 'probe not requested' : null;

  test(
    'account shapes',
    () async {
      final out = <String, Object?>{};
      try {
        final staff = await localStaff();
        final c = await authorAssessedCourse(staff);
        final me = await newLocalLearner('probe5');
        final learner = me.client;
        Future<dynamic> grab(
          String name,
          Future<dynamic> Function() call,
        ) async {
          try {
            final v = await call();
            out[name] = v;
            return v;
          } on AtlasApiException catch (e) {
            out[name] = {
              'ERROR': e.messageKey,
              'status': e.status,
              'details': e.details,
              'fields': e.fields,
            };
            return null;
          }
        }

        await staff.post<dynamic>(
          'academies/$localAcademyId/students/${me.userId}/enrollments',
          data: {'courseId': c.courseId},
        );
        // Something to notify about: a graded assignment, an announcement.
        final sub = await learner.post<Map<String, dynamic>>(
          'courses/${c.courseId}/assignments/${c.assignmentId}/submission',
          data: {'response': 'حل', 'idempotencyKey': 'p5-${me.userId}'},
        );
        await staff.post<dynamic>(
          'review/courses/${c.courseId}/assignments/${c.assignmentId}/submissions/${sub['id']}/grade',
          data: {'score': 8, 'feedback': 'جيد'},
        );
        final ann = await grab(
          'announcement_create',
          () => staff.post<dynamic>(
            'courses/${c.courseId}/announcements',
            data: {
              'title': 'تأجيل الحصة',
              'body': 'الحصة يوم الخميس بدل الأربعاء.',
            },
          ),
        ) as Map?;
        if (ann != null) {
          await grab(
            'announcement_publish',
            () => staff.post<dynamic>(
              'courses/${c.courseId}/announcements/${ann['id']}/publish',
            ),
          );
        }
        await Future<void>.delayed(const Duration(seconds: 4));

        await grab(
          'notifications',
          () => learner.get<dynamic>('notifications'),
        );
        await grab(
          'notifications_summary',
          () => learner.get<dynamic>('notifications/summary'),
        );
        await grab(
          'notification_prefs',
          () => learner.get<dynamic>('notifications/preferences'),
        );
        final list = out['notifications'];
        final first =
            list is Map &&
                list['items'] is List &&
                (list['items'] as List).isNotEmpty
            ? (list['items'] as List).first as Map
            : null;
        if (first != null) {
          await grab(
            'mark_read',
            () => learner.patch<dynamic>('notifications/${first['id']}/read'),
          );
        }
        await grab(
          'read_all',
          () => learner.post<dynamic>('notifications/read-all', data: {}),
        );
        await grab(
          'announcements',
          () => learner.get<dynamic>('announcements'),
        );
        if (ann != null) {
          await grab(
            'announcement',
            () => learner.get<dynamic>('announcements/${ann['id']}'),
          );
        }
        await grab(
          'comm_prefs',
          () => learner.get<dynamic>('users/me/communication-preferences'),
        );

        await grab('me', () => learner.get<dynamic>('users/me'));
        await grab(
          'me_patch',
          () =>
              learner.patch<dynamic>('users/me', data: {'name': 'طالب تجريبي'}),
        );
        await grab('phone', () => learner.get<dynamic>('users/me/phone'));
        await grab(
          'phone_put',
          () => learner.put<dynamic>(
            'users/me/phone',
            data: {'phoneNumber': '01012345678', 'phoneCountry': 'EG'},
          ),
        );
        await grab(
          'password_wrong',
          () => learner.post<dynamic>(
            'users/me/password',
            data: {
              'currentPassword': 'nope-nope-1',
              'newPassword': 'New-Passw0rd!x2',
            },
          ),
        );
        await grab('sessions', () => learner.get<dynamic>('auth/sessions'));
        await grab('consents', () => learner.get<dynamic>('users/me/consents'));
        await grab(
          'sign_in_methods',
          () => learner.get<dynamic>('users/me/sign-in-methods'),
        );
        await grab(
          'privacy_mine',
          () => learner.get<dynamic>('privacy-requests/mine'),
        );
        await grab(
          'privacy_code',
          () => learner.post<dynamic>('privacy-requests/code', data: {}),
        );
        await grab(
          'learner_deletion',
          () => learner.get<dynamic>('users/me/learner-deletion'),
        );
        await grab(
          'learner_deletion_request',
          () => learner.post<dynamic>(
            'users/me/learner-deletion/request',
            data: {},
          ),
        );
        final dev = await grab(
          'push_register',
          () => learner.put<dynamic>(
            'users/me/push-devices',
            data: {
              'token':
                  'probe-token-${me.userId}-abcdefghijklmnopqrstuvwxyz0123456789',
              'platform': 'android',
              'appVersion': '1.0.0',
              'locale': 'ar',
            },
          ),
        ) as Map?;
        if (dev != null) {
          await grab(
            'push_remove',
            () => learner.delete<dynamic>('users/me/push-devices/${dev['id']}'),
          );
        }
        await grab(
          'password',
          () => learner.post<dynamic>(
            'users/me/password',
            data: {
              'currentPassword': 'Probe-Passw0rd!x',
              'newPassword': 'New-Passw0rd!x2',
            },
          ),
        );
        await grab('after_password', () => learner.get<dynamic>('users/me'));
        await grab(
          'revoke_others',
          () => learner.post<dynamic>('auth/sessions/revoke-others', data: {}),
        );
      } finally {
        File(env['ATLAS_PROBE_OUT']!)
            .writeAsStringSync(const JsonEncoder.withIndent('  ').convert(out));
      }
    },
    skip: skip,
    timeout: const Timeout(Duration(minutes: 4)),
  );
}
