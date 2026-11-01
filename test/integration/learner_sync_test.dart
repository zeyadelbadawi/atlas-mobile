// Against the LOCAL stack: the server side of the learner's profile photo,
// notes sync, study days and the due-date push opt-in, through the app's
// own repositories. Same env as learner_full_cycle_test.dart.
@Tags(['integration'])
library;

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:atlas_mobile/core/account/account_repository.dart';
import 'package:atlas_mobile/core/api/api_error.dart';
import 'package:atlas_mobile/core/learning/learning_repository.dart';
import 'package:atlas_mobile/core/notifications/notifications_repository.dart';
import 'package:dio/dio.dart';
import 'package:test/test.dart';

import 'local_stack.dart';

/// 80 x 60, not square: the server crops it.
final _jpeg = Uint8List.fromList(
  base64Decode(
    '/9j/4AAQSkZJRgABAQAAAQABAAD/2wBDAAoHBwgHBgoICAgLCgoLDhgQDg0NDh0VFhEYIx8lJCIfIiEmKzcvJik0KSEiMEExNDk7Pj4+JS5ESUM8SDc9Pjv/2wBDAQoLCw4NDhwQEBw7KCIoOzs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozv/wAARCAA8AFADASIAAhEBAxEB/8QAHwAAAQUBAQEBAQEAAAAAAAAAAAECAwQFBgcICQoL/8QAtRAAAgEDAwIEAwUFBAQAAAF9AQIDAAQRBRIhMUEGE1FhByJxFDKBkaEII0KxwRVS0fAkM2JyggkKFhcYGRolJicoKSo0NTY3ODk6Q0RFRkdISUpTVFVWV1hZWmNkZWZnaGlqc3R1dnd4eXqDhIWGh4iJipKTlJWWl5iZmqKjpKWmp6ipqrKztLW2t7i5usLDxMXGx8jJytLT1NXW19jZ2uHi4+Tl5ufo6erx8vP09fb3+Pn6/8QAHwEAAwEBAQEBAQEBAQAAAAAAAAECAwQFBgcICQoL/8QAtREAAgECBAQDBAcFBAQAAQJ3AAECAxEEBSExBhJBUQdhcRMiMoEIFEKRobHBCSMzUvAVYnLRChYkNOEl8RcYGRomJygpKjU2Nzg5OkNERUZHSElKU1RVVldYWVpjZGVmZ2hpanN0dXZ3eHl6goOEhYaHiImKkpOUlZaXmJmaoqOkpaanqKmqsrO0tba3uLm6wsPExcbHyMnK0tPU1dbX2Nna4uPk5ebn6Onq8vP09fb3+Pn6/9oADAMBAAIRAxEAPwDh6KKK+mPNCiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigD//2Q==',
  ),
);

void main() {
  final env = Platform.environment;
  final missing = [
    'ATLAS_SPIKE_ORIGIN',
    'ATLAS_SPIKE_ACADEMY_ID',
    'ATLAS_SPIKE_OTP_ENV',
    'ATLAS_SPIKE_OWNER_EMAIL',
    'ATLAS_SPIKE_OWNER_PASSWORD',
  ].where((k) => env[k] == null).toList();

  test(
    'photo, notes, study days and the due reminder opt-in',
    () async {
      final staff = await localStaff();
      final course = await authorAssessedCourse(staff);
      final learner = await newLocalLearner('sync');
      await staff.post<dynamic>(
        'academies/$localAcademyId/students/${learner.userId}/enrollments',
        data: {'courseId': course.courseId},
      );

      // --- profile photo ---------------------------------------------------
      final account = AccountRepository(learner.client);
      final withPhoto = await account.uploadAvatar(_jpeg);
      final path = withPhoto.avatar!;
      expect(
        path,
        matches(
          RegExp(r'^/api/v1/public/media/users/avatars/[0-9a-f-]{36}\.webp$'),
        ),
      );
      expect((await account.me()).avatar, path);
      final image = await Dio().get<List<int>>(
        '${localAcademy.origin}$path',
        options: Options(responseType: ResponseType.bytes),
      );
      expect(image.headers.value('content-type'), 'image/webp');
      expect(image.headers.value('cache-control'), contains('public'));
      final bytes = image.data!;
      expect(utf8.decode(bytes.sublist(8, 12)), 'WEBP');

      final second = await account.uploadAvatar(_jpeg);
      expect(second.avatar, isNot(path));
      // The previous photo is deleted when it is replaced.
      await expectLater(
        Dio().get<dynamic>('${localAcademy.origin}$path'),
        throwsA(isA<DioException>()),
      );
      final removed = await account.removeAvatar();
      expect(removed.avatar, isNull);

      await expectLater(
        account.uploadAvatar(Uint8List.fromList(utf8.encode('not an image'))),
        throwsA(isA<AtlasApiException>()),
      );

      // --- notes -------------------------------------------------------------
      final repo = LearningRepository(learner.client);
      expect(await repo.notes(), isEmpty);
      final t0 = DateTime.now().toUtc().subtract(const Duration(minutes: 5));
      final put = await repo.putNote(
        courseId: course.courseId,
        lessonId: course.lessonId,
        note: 'راجع المثال الثاني',
        saved: true,
        editedAt: t0,
      );
      expect(put.note, 'راجع المثال الثاني');
      expect(put.lessonTitle, isNotEmpty);
      expect(put.courseTitle, isNotEmpty);
      // An older edit from another phone loses.
      final stale = await repo.putNote(
        courseId: course.courseId,
        lessonId: course.lessonId,
        note: 'قديم',
        saved: false,
        editedAt: t0.subtract(const Duration(minutes: 1)),
      );
      expect(stale.note, 'راجع المثال الثاني');
      // A newer delete wins and is listed, so other phones drop it.
      await repo.putNote(
        courseId: course.courseId,
        lessonId: course.lessonId,
        note: '',
        saved: false,
        editedAt: t0.add(const Duration(minutes: 1)),
      );
      final listed = await repo.notes();
      expect(listed, hasLength(1));
      expect(listed.single.note, isEmpty);
      expect(listed.single.saved, isFalse);
      // Not a lesson of the learner's course: refused.
      await expectLater(
        repo.putNote(
          courseId: course.courseId,
          lessonId: '00000000-0000-4000-8000-000000000000',
          note: 'x',
          saved: true,
          editedAt: t0,
        ),
        throwsA(
          isA<AtlasApiException>().having((e) => e.status, 'status', 404),
        ),
      );
      // Another learner sees none of it.
      final other = await newLocalLearner('sync-other');
      expect(await LearningRepository(other.client).notes(), isEmpty);

      // --- study days --------------------------------------------------------
      expect(await repo.studyDays('Africa/Cairo'), isEmpty);
      await repo.completeLesson(course.courseId, course.lessonId);
      final days = await repo.studyDays('Africa/Cairo');
      final cairoToday = DateTime.now().toUtc().add(const Duration(hours: 2));
      expect(days, hasLength(1));
      expect(
        days.single,
        anyOf(
          cairoToday.toIso8601String().substring(0, 10),
          cairoToday
              .add(const Duration(hours: 1))
              .toIso8601String()
              .substring(0, 10),
        ),
      );
      await expectLater(
        repo.studyDays('Not/AZone'),
        throwsA(
          isA<AtlasApiException>().having((e) => e.status, 'status', 400),
        ),
      );

      // --- due reminder opt-in ----------------------------------------------
      final push = NotificationsRepository(learner.client);
      final token = 'probe-token-${DateTime.now().microsecondsSinceEpoch}-xyz';
      await push.registerPushDevice(
        token: token,
        platform: 'android',
        appVersion: '1.0.0',
        locale: 'ar',
        dueReminders: true,
      );
      // Re-registering without the field keeps it on.
      await push.registerPushDevice(
        token: token,
        platform: 'android',
        appVersion: '1.0.1',
        locale: 'ar',
      );
      // An assignment due in two hours, for the sweep check that follows.
      await staff.patch<dynamic>(
        'courses/${course.courseId}/assignments/${course.assignmentId}',
        data: {
          'dueAt': DateTime.now()
              .add(const Duration(hours: 2))
              .toUtc()
              .toIso8601String(),
        },
      );
      stdout.writeln('SWEEP_USER=${learner.userId}');
      stdout.writeln('SWEEP_ASSIGNMENT=${course.assignmentId}');
    },
    skip: missing.isEmpty ? false : 'needs ${missing.join(', ')}',
    timeout: const Timeout(Duration(minutes: 3)),
  );
}
