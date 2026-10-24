// Phase 4 exit criterion: a complete learning cycle through the app's own
// repositories, on the LOCAL stack — lesson, quiz (autosave + integrity +
// submit + results), assignment (draft + attachment + submit), the
// reviewer's grade, course completion and the certificate with a working
// PDF link and public verification. Env as local_stack.dart.
@Tags(['integration'])
library;

import 'dart:convert';
import 'dart:io';

import 'package:atlas_mobile/core/learning/assessment_models.dart';
import 'package:atlas_mobile/core/learning/assessment_repository.dart';
import 'package:atlas_mobile/core/learning/learning_repository.dart';
import 'package:atlas_mobile/features/quiz/quiz_engine.dart';
import 'package:test/test.dart';

import 'local_stack.dart';

const _png =
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==';

void main() {
  final skip = Platform.environment['ATLAS_SPIKE_ORIGIN'] == null
      ? 'needs the local stack'
      : null;

  test(
    'a learner completes the full cycle and gets a certificate',
    () async {
      final staff = await localStaff();
      final c = await authorAssessedCourse(staff);
      final me = await newLocalLearner('cycle');
      await staff.post<dynamic>(
        'academies/$localAcademyId/students/${me.userId}/enrollments',
        data: {'courseId': c.courseId},
      );
      final learning = LearningRepository(me.client);
      final repo = AssessmentRepository(me.client);

      // 1. Lesson.
      await learning.completeLesson(c.courseId, c.lessonId);

      // 2. Quiz, the way the runner does it.
      final quiz = await repo.quiz(c.courseId, c.quizId);
      expect(quiz.settings.integrityMode, 'warn');
      expect(quiz.optionLabels, isNotEmpty);
      final attempt = await repo.start(c.courseId, c.quizId);
      final session = await repo.session(c.courseId, c.quizId, attempt.id);
      expect(session.deadlineAt, isNotNull);
      final answers = <QuizAnswer>[
        for (final q in session.questions)
          switch (q.type) {
            'short_answer' => QuizAnswer(questionId: q.id, text: 'ستة'),
            'multiple_choice' => QuizAnswer(
              questionId: q.id,
              selected: [
                for (final o in q.options)
                  if (o.label != '٣') o.id,
              ],
            ),
            _ => QuizAnswer(
              questionId: q.id,
              selected: [
                q.options
                    .firstWhere((o) => o.label == '٣' || o.label == 'صح')
                    .id,
              ],
            ),
          },
      ];
      final autosave = QuizAutosave(
        save: (rev, a) => repo.saveAnswers(
          c.courseId,
          c.quizId,
          attempt.id,
          revision: rev,
          answers: a,
        ),
        initialRevision: session.revision,
        confirmed: session.answers,
      );
      autosave.schedule(answers);
      await autosave.flush();
      expect(autosave.state.value, AutosaveState.saved);

      final integrity = QuizIntegrity(
        record: (e) => repo.recordEvents(c.courseId, c.quizId, attempt.id, e),
        mode: session.settings.integrityMode,
      )..start();
      await integrity.flush();
      integrity.dispose();

      final submitted = await repo.submit(
        c.courseId,
        c.quizId,
        attempt.id,
        answers: answers,
        revision: autosave.nextRevision,
      );
      expect(submitted.status, 'passed');
      final results = await repo.results(c.courseId, c.quizId, attempt.id);
      expect(results.showsScore, isTrue);
      expect(results.score, 100);
      expect(results.questions.first.correctOptionIds, isNotEmpty);
      // Submitting again is idempotent, never a second attempt.
      final again = await repo.submit(
        c.courseId,
        c.quizId,
        attempt.id,
        answers: answers,
        revision: autosave.nextRevision,
      );
      expect(again.id, attempt.id);

      // 3. Assignment: draft, attachment, submit (twice with one key).
      final draft = await repo.saveDraft(
        c.courseId,
        c.assignmentId,
        response: 'الحل في الصورة',
        attachmentAssetId: null,
        baseDraftSavedAt: null,
      );
      final upload = await repo.uploadAttachment(
        c.courseId,
        c.assignmentId,
        fileName: 'solution.png',
        mimeType: 'image/png',
        sizeBytes: base64Decode(_png).length,
        dataUrl: 'data:image/png;base64,$_png',
      );
      await repo.saveDraft(
        c.courseId,
        c.assignmentId,
        response: 'الحل في الصورة',
        attachmentAssetId: upload.assetId,
        baseDraftSavedAt: draft.draftSavedAt,
      );
      const key = 'cycle-submit-0001';
      final sub = await repo.submitAssignment(
        c.courseId,
        c.assignmentId,
        response: 'الحل في الصورة',
        attachmentAssetId: upload.assetId,
        idempotencyKey: key,
        baseRevision: 0,
      );
      final retry = await repo.submitAssignment(
        c.courseId,
        c.assignmentId,
        response: 'الحل في الصورة',
        attachmentAssetId: upload.assetId,
        idempotencyKey: key,
        baseRevision: 0,
      );
      expect(retry.submittedRevision, sub.submittedRevision);
      expect(sub.attachment?.url, isNotNull);

      // 4. The reviewer grades it; the learner sees the grade.
      await staff.post<dynamic>(
        'review/courses/${c.courseId}/assignments/${c.assignmentId}/submissions/${sub.id}/grade',
        data: {'score': 90, 'feedback': 'ممتاز'},
      );
      final graded = await repo.submission(c.courseId, c.assignmentId);
      expect(graded!.isGraded, isTrue);
      expect(graded.score, 90);
      expect(graded.feedback, 'ممتاز');

      // 5. Course complete, results, certificate.
      final completion = await learning.completion(c.courseId);
      expect(completion.completed, isTrue);
      final all = await repo.studentResults();
      final row = all.courses.firstWhere((x) => x.courseId == c.courseId);
      expect(row.quizzes.single.score, 100);
      expect(row.assignments.single.score, 90);

      Certificate? cert;
      for (var i = 0; i < 30 && cert?.renderStatus != 'ready'; i++) {
        final list = await repo.certificates();
        cert = list.items.where((x) => x.courseId == c.courseId).firstOrNull;
        if (cert?.renderStatus != 'ready') {
          await Future<void>.delayed(const Duration(seconds: 1));
        }
      }
      expect(cert, isNotNull, reason: 'certificate issued');
      expect(cert!.downloadable, isTrue);
      final link = await repo.certificateDownload(cert.id);
      final pdf = await HttpClient()
          .getUrl(Uri.parse(link.url))
          .then((r) => r.close());
      expect(pdf.statusCode, 200);
      final verify = await me.client.get<Map<String, dynamic>>(
        'verify/${cert.verificationCode}',
      );
      expect(verify['valid'], isTrue);
    },
    skip: skip,
    timeout: const Timeout(Duration(minutes: 4)),
  );
}
