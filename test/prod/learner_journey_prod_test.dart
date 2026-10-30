// A learner's whole journey on PRODUCTION, through the app's own
// repositories, on a demo academy and learner account the owner provided.
// Run after `production_session_check_test.dart` (stage signin) has sent the
// emailed code; this completes the code and walks every phase:
// catalog → join → lessons → quiz → assignment → results → certificates →
// announcements → notifications → account. It records what each step
// returned in ATLAS_PROD_STATE_DIR/journey.json and never deletes the account.
//
//   ATLAS_PROD_STAGE=journey ATLAS_PROD_STATE_DIR=… ATLAS_PROD_ORIGIN=host
//   ATLAS_PROD_CODE=123456 (first run only; later runs reuse the cookies)
//
// Credentials and codes come only from the environment.
@Tags(['production'])
library;

import 'dart:convert';
import 'dart:io';

import 'package:atlas_mobile/core/account/account_repository.dart';
import 'package:atlas_mobile/core/api/academy_endpoint.dart';
import 'package:atlas_mobile/core/api/atlas_api_client.dart';
import 'package:atlas_mobile/core/auth/auth_repository.dart';
import 'package:atlas_mobile/core/learning/assessment_models.dart';
import 'package:atlas_mobile/core/learning/assessment_repository.dart';
import 'package:atlas_mobile/core/learning/catalog_repository.dart';
import 'package:atlas_mobile/core/learning/learning_repository.dart';
import 'package:atlas_mobile/core/notifications/notifications_repository.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:test/test.dart';

const _png =
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==';

void main() {
  final env = Platform.environment;
  final dir = env['ATLAS_PROD_STATE_DIR'];
  final skip = env['ATLAS_PROD_STAGE'] != 'journey' || dir == null
      ? 'production journey not requested'
      : null;

  test(
    'learner journey on production',
    () async {
      final log = <String, Object?>{};
      final problems = <String>[];
      void note(String step, Object? value) {
        log[step] = value;
        stdout.writeln('✓ $step');
      }

      Future<T?> step<T>(String name, Future<T> Function() run) async {
        try {
          final v = await run();
          note(name, v.toString());
          return v;
        } on Object catch (e) {
          problems.add('$name: $e');
          stdout.writeln('✗ $name: $e');
          return null;
        }
      }

      final endpoint = AcademyEndpoint.parse(env['ATLAS_PROD_ORIGIN']!);
      final jar = PersistCookieJar(storage: FileStorage('$dir/jar/'));
      final client = AtlasApiClient(
        endpoint: endpoint,
        cookieJar: jar,
        userAgent: 'AtlasApp/1.0-review (iPhone; iOS 18.0)',
      );
      final resolved = await client.get<Map<String, dynamic>>(
        'public/websites/resolve',
        query: {'hostname': endpoint.host},
      );
      final academyId = resolved['academyId'] as String;
      note('academy', '${resolved['academyName']} $academyId');
      final auth = AuthRepository(client, academyId: academyId);

      // Sign in: complete the emailed code once, then reuse the cookies.
      final code = env['ATLAS_PROD_CODE'];
      if (code != null) {
        final challengeId =
            (jsonDecode(File('$dir/challenge.json').readAsStringSync())
                    as Map)['challengeId']
                as String;
        final out = await auth.verifyEmailCode(
          challengeId: challengeId,
          code: code,
          rememberDevice: true,
        );
        expect(out, isA<SignedIn>());
      }
      await client.refreshSession();
      note('signed in', 'ok');

      final learning = LearningRepository(client, academyId: academyId);
      final catalog = CatalogRepository(client, academyId);
      final assess = AssessmentRepository(client, academyId: academyId);
      final notes = NotificationsRepository(client);
      final account = AccountRepository(client);

      // Home before joining anything.
      await step('overview (empty)', learning.overview);
      final before = await step('enrollments (before)', learning.enrollments);

      // Catalog: free courses, preview, curriculum, join.
      final page = await step('catalog', () => catalog.freeCourses());
      for (final c in page?.items ?? const <CatalogCourse>[]) {
        await step('preview ${c.title}', () => catalog.course(c.id));
        await step('curriculum ${c.title}', () => catalog.curriculum(c.id));
      }
      // Join every free course not joined yet (joining twice is harmless).
      final joined = {for (final e in before ?? const []) e.courseId};
      for (final c in page?.items ?? const <CatalogCourse>[]) {
        if (!joined.contains(c.id)) {
          await step('join ${c.title}', () => catalog.enroll(c.id));
        }
      }
      final courses = await step('enrollments', learning.enrollments) ?? [];

      for (final ec in courses) {
        // Like a learner: open the next available item, again and again,
        // so items unlock as earlier ones are completed.
        final handled = <String>{};
        for (var round = 0; round < 40; round++) {
          final s = await step(
            'sequence ${ec.courseId} r$round',
            () => learning.sequence(ec.courseId),
          );
          if (s == null) break;
          final item = s.items
              .where((i) => !i.isLocked && !handled.contains(i.id))
              .firstOrNull;
          if (item == null) {
            final locked = s.items.where((i) => i.isLocked).toList();
            note(
              'progress ${s.courseTitle}',
              '${s.completedCount}/${s.totalCount} finished=${s.finished} '
                  'locked=${[for (final l in locked) '${l.title} (${l.lockReason})']}',
            );
            break;
          }
          handled.add(item.id);
          final where = '${s.courseTitle} #${item.position + 1} ${item.type}';
          switch (item.type) {
            case 'lesson':
              final g = await step(
                '$where grant',
                () => learning.grant(ec.courseId, item.id),
              );
              if (g != null && !item.isDone) {
                await step(
                  '$where complete',
                  () => learning.completeLesson(ec.courseId, item.id),
                );
              }
            case 'quiz':
              if (item.isDone) break;
              final quiz = await step(
                '$where quiz',
                () => assess.quiz(ec.courseId, item.id),
              );
              if (quiz == null) break;
              final attempt = await step(
                '$where start',
                () => assess.start(ec.courseId, item.id),
              );
              if (attempt == null) break;
              final session = await step(
                '$where session',
                () => assess.session(ec.courseId, item.id, attempt.id),
              );
              if (session == null) break;
              final answers = [
                for (final q in session.questions)
                  q.options.isEmpty
                      ? QuizAnswer(questionId: q.id, text: 'إجابة')
                      : QuizAnswer(
                          questionId: q.id,
                          selected: [q.options.first.id],
                        ),
              ];
              final saved = await step(
                '$where save',
                () => assess.saveAnswers(
                  ec.courseId,
                  item.id,
                  attempt.id,
                  revision: session.revision + 1,
                  answers: answers,
                ),
              );
              final done = await step(
                '$where submit',
                () => assess.submit(
                  ec.courseId,
                  item.id,
                  attempt.id,
                  answers: answers,
                  revision: (saved?.revision ?? session.revision) + 1,
                ),
              );
              if (done != null) {
                await step(
                  '$where results',
                  () => assess.results(ec.courseId, item.id, attempt.id),
                );
              }
            case 'assignment':
              if (item.isDone) break;
              await step(
                '$where assignment',
                () => assess.assignment(ec.courseId, item.id),
              );
              final draft = await step(
                '$where draft',
                () => assess.saveDraft(
                  ec.courseId,
                  item.id,
                  response: 'تسليم من مراجعة التطبيق.',
                  attachmentAssetId: null,
                  baseDraftSavedAt: null,
                ),
              );
              final up = await step(
                '$where attach',
                () => assess.uploadAttachment(
                  ec.courseId,
                  item.id,
                  fileName: 'review.png',
                  mimeType: 'image/png',
                  sizeBytes: base64Decode(_png).length,
                  dataUrl: 'data:image/png;base64,$_png',
                ),
              );
              await step(
                '$where draft 2',
                () => assess.saveDraft(
                  ec.courseId,
                  item.id,
                  response: 'تسليم من مراجعة التطبيق.',
                  attachmentAssetId: up?.assetId,
                  baseDraftSavedAt: draft?.draftSavedAt,
                ),
              );
              await step(
                '$where submit',
                () => assess.submitAssignment(
                  ec.courseId,
                  item.id,
                  response: 'تسليم من مراجعة التطبيق.',
                  attachmentAssetId: up?.assetId,
                  idempotencyKey: 'review-${item.id}',
                  baseRevision: 0,
                ),
              );
            default:
              note('$where (opens on the website)', item.title);
          }
        }
        await step(
          'completion ${ec.courseId}',
          () => learning.completion(ec.courseId),
        );
      }

      await step('overview', learning.overview);
      await step('results', assess.studentResults);
      await step('certificates', assess.certificates);
      await step('announcements', notes.announcements);
      final n = await step('notifications', () => notes.list());
      await step('unread', notes.unreadCount);
      if (n != null) note('notification count', n.items.length);
      await step('me', account.me);
      await step('phone', account.phone);
      await step('sessions', account.sessions);
      await step('learning emails', account.learningEmails);
      await step('privacy requests', account.privacyRequests);
      await step('can delete from app', account.canDeleteFromApp);
      await step('devices', learning.devices);

      File('$dir/journey.json').writeAsStringSync(
        const JsonEncoder.withIndent('  ')
            .convert({'log': log, 'problems': problems}),
      );
      stdout.writeln('PROBLEMS ${problems.length}');
      for (final p in problems) {
        stdout.writeln('  - $p');
      }
    },
    skip: skip,
    timeout: const Timeout(Duration(minutes: 5)),
  );
}
