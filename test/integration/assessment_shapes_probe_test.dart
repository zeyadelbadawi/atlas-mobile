// Prints the assessment API's real response shapes from the LOCAL stack
// (phase 4 reference): quiz attempt lifecycle, assignment draft/upload/
// submit/grade, results and certificates. Env as local_stack.dart, plus
// ATLAS_PROBE_OUT=<file>.
@Tags(['integration'])
library;

import 'dart:convert';
import 'dart:io';

import 'package:atlas_mobile/core/api/api_error.dart';
import 'package:test/test.dart';

import 'local_stack.dart';

// 1×1 transparent PNG.
const _png =
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==';

void main() {
  final env = Platform.environment;
  final skip = env['ATLAS_PROBE_OUT'] == null ? 'probe not requested' : null;

  test(
    'assessment shapes',
    () async {
      final staff = await localStaff();
      final c = await authorAssessedCourse(staff);
      final me = await newLocalLearner('probe4');
      final learner = me.client;
      final out = <String, Object?>{'ids': c.toString()};
      Future<dynamic> grab(String name, Future<dynamic> Function() call) async {
        try {
          final v = await call();
          out[name] = v;
          return v;
        } on AtlasApiException catch (e) {
          out[name] = {
            'ERROR': e.messageKey,
            'status': e.status,
            'details': e.details,
          };
          return null;
        }
      }

      try {
        await staff.post<dynamic>(
          'academies/$localAcademyId/students/${me.userId}/enrollments',
          data: {'courseId': c.courseId},
        );
        final base = 'courses/${c.courseId}';
        await grab(
          'sequence',
          () => learner.get<dynamic>('learning/courses/${c.courseId}/sequence'),
        );
        await grab(
          'learning_quizzes',
          () => learner.get<dynamic>('learning/quizzes'),
        );
        await grab(
          'learning_assignments',
          () => learner.get<dynamic>('learning/assignments'),
        );
        await grab(
          'quiz_before_lesson',
          () => learner.get<dynamic>('$base/quizzes/${c.quizId}'),
        );
        await grab(
          'complete_lesson',
          () => learner.post<dynamic>(
            '$base/progress/complete-lesson',
            data: {'lessonId': c.lessonId},
          ),
        );
        final quiz = await grab(
          'quiz',
          () => learner.get<dynamic>('$base/quizzes/${c.quizId}'),
        );
        await grab(
          'attempts_empty',
          () => learner.get<dynamic>('$base/quizzes/${c.quizId}/attempts'),
        );
        final attempt = await grab(
          'start',
          () => learner.post<dynamic>('$base/quizzes/${c.quizId}/attempts'),
        ) as Map?;
        final aid = attempt!['id'];
        final qa = '$base/quizzes/${c.quizId}/attempts/$aid';
        final session =
            await grab('session', () => learner.get<dynamic>(qa)) as Map;
        final questions = (session['questions'] as List).cast<Map>();
        final answers = <Map<String, Object?>>[];
        for (final q in questions) {
          final opts = (q['options'] as List).cast<Map>();
          switch (q['type']) {
            case 'short_answer':
              answers.add({'questionId': q['id'], 'text': 'ستة'});
            case 'multiple_choice':
              answers.add({
                'questionId': q['id'],
                'selectedOptionIds': [
                  for (final o in opts)
                    if (o['label'] != '٣') o['id'],
                ],
              });
            default:
              answers.add({
                'questionId': q['id'],
                'selectedOptionIds': [
                  opts.firstWhere(
                    (o) => o['label'] == '٣' || o['label'] == 'صح',
                    orElse: () => opts.first,
                  )['id'],
                ],
              });
          }
        }
        await grab(
          'save',
          () => learner.put<dynamic>(
            '$qa/answers',
            data: {
              'revision': (session['revision'] as int) + 1,
              'answers': answers,
            },
          ),
        );
        await grab(
          'save_stale',
          () => learner.put<dynamic>(
            '$qa/answers',
            data: {'revision': 1, 'answers': answers.take(1).toList()},
          ),
        );
        await Future<void>.delayed(const Duration(seconds: 6));
        await grab(
          'events',
          () => learner.post<dynamic>(
            '$qa/events',
            data: {
              'events': [
                {
                  'type': 'fullscreen_enter',
                  'clientAt': DateTime.now().toUtc().toIso8601String(),
                },
                {
                  'type': 'visibility_hidden',
                  'clientAt': DateTime.now().toUtc().toIso8601String(),
                },
              ],
            },
          ),
        );
        await grab(
          'submit',
          () => learner.post<dynamic>(
            '$qa/submit',
            data: {'answers': answers, 'revision': 3},
          ),
        );
        await grab(
          'submit_again',
          () => learner.post<dynamic>('$qa/submit', data: {}),
        );
        await grab('results', () => learner.get<dynamic>('$qa/results'));
        await grab(
          'attempts_after',
          () => learner.get<dynamic>('$base/quizzes/${c.quizId}/attempts'),
        );

        // Assignment.
        final as = '$base/assignments/${c.assignmentId}';
        await grab('assignment', () => learner.get<dynamic>(as));
        await grab(
          'submission_none',
          () => learner.get<dynamic>('$as/submission'),
        );
        await grab(
          'draft',
          () => learner.put<dynamic>(
            '$as/submission/draft',
            data: {'response': 'الحل في الصورة', 'baseDraftSavedAt': null},
          ),
        );
        await grab(
          'draft_conflict',
          () => learner.put<dynamic>(
            '$as/submission/draft',
            data: {'response': 'نسخة قديمة', 'baseDraftSavedAt': null},
          ),
        );
        final upload = await grab(
          'upload',
          () => learner.post<dynamic>(
            '$as/submission/attachment',
            data: {
              'fileName': 'solution.png',
              'mimeType': 'image/png',
              'sizeBytes': base64Decode(_png).length,
              'dataUrl': 'data:image/png;base64,$_png',
            },
          ),
        ) as Map?;
        final submitted = await grab(
          'assignment_submit',
          () => learner.post<dynamic>(
            '$as/submission',
            data: {
              'response': 'الحل في الصورة',
              'attachmentAssetId': upload?['assetId'],
              'idempotencyKey':
                  'probe-${DateTime.now().microsecondsSinceEpoch}',
              'baseRevision': 0,
            },
          ),
        ) as Map?;
        if (submitted != null) {
          await grab(
            'grade',
            () => staff.post<dynamic>(
              'review/$as/submissions/${submitted['id']}/grade',
              data: {'score': 90, 'feedback': 'ممتاز، راجع المعادلة الرابعة.'},
            ),
          );
        }
        await grab(
          'submission_graded',
          () => learner.get<dynamic>('$as/submission'),
        );
        await grab(
          'completion',
          () =>
              learner.get<dynamic>('learning/courses/${c.courseId}/completion'),
        );
        await grab(
          'results_all',
          () => learner.get<dynamic>('learning/results'),
        );
        Map? certs;
        for (var i = 0; i < 20; i++) {
          certs = await grab(
            'certificates',
            () => learner.get<dynamic>('learning/certificates'),
          ) as Map?;
          final list = (certs?['items'] as List? ?? const []).cast<Map>();
          if (list.isNotEmpty && list.first['renderStatus'] == 'ready') break;
          await Future<void>.delayed(const Duration(seconds: 1));
        }
        final items = (certs?['items'] as List? ?? const []).cast<Map>();
        if (items.isNotEmpty) {
          final id = items.first['id'];
          await grab(
            'certificate',
            () => learner.get<dynamic>('learning/certificates/$id'),
          );
          await grab(
            'certificate_download',
            () => learner.get<dynamic>('learning/certificates/$id/download'),
          );
          await grab(
            'verify',
            () => learner.get<dynamic>(
              'verify/${items.first['verificationCode']}',
            ),
          );
        }
        await grab('overview', () => learner.get<dynamic>('learning/overview'));
        out['quiz_raw_type'] = quiz.runtimeType.toString();
      } finally {
        File(env['ATLAS_PROBE_OUT']!)
            .writeAsStringSync(const JsonEncoder.withIndent('  ').convert(out));
      }
    },
    skip: skip,
    timeout: const Timeout(Duration(minutes: 4)),
  );
}
