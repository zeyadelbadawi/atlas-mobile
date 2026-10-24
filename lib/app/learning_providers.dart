import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/learning/assessment_models.dart';
import '../core/learning/assessment_repository.dart';
import '../core/learning/learning_models.dart';
import '../core/learning/learning_repository.dart';
import 'providers.dart';

/// The learning API for the signed-in academy. Rebuilt when the session
/// changes academy or user, which also refreshes every read below.
final learningRepositoryProvider = Provider<LearningRepository>((ref) {
  ref.watch(sessionProvider.select((s) => (s.academy, s.user?['id'])));
  final client = ref.read(sessionProvider.notifier).client;
  if (client == null) throw StateError('no academy session');
  return LearningRepository(client);
});

final overviewProvider = FutureProvider.autoDispose<LearnerOverview>(
  (ref) => ref.watch(learningRepositoryProvider).overview(),
);

final enrollmentsProvider = FutureProvider.autoDispose<List<EnrolledCourse>>(
  (ref) => ref.watch(learningRepositoryProvider).enrollments(),
);

final sequenceProvider = FutureProvider.autoDispose
    .family<CourseSequence, String>(
      (ref, courseId) =>
          ref.watch(learningRepositoryProvider).sequence(courseId),
    );

final completionProvider = FutureProvider.autoDispose
    .family<CourseCompletion, String>(
      (ref, courseId) =>
          ref.watch(learningRepositoryProvider).completion(courseId),
    );

final devicesProvider = FutureProvider.autoDispose<LearnerDevices>(
  (ref) => ref.watch(learningRepositoryProvider).devices(),
);

/// After a lesson completes: everything that shows progress reloads.
void refreshLearning(WidgetRef ref, String courseId) {
  ref.invalidate(sequenceProvider(courseId));
  ref.invalidate(completionProvider(courseId));
  ref.invalidate(overviewProvider);
  ref.invalidate(enrollmentsProvider);
}

/* ---- assessments (phase 4) ---- */

final assessmentRepositoryProvider = Provider<AssessmentRepository>((ref) {
  ref.watch(sessionProvider.select((s) => (s.academy, s.user?['id'])));
  final client = ref.read(sessionProvider.notifier).client;
  if (client == null) throw StateError('no academy session');
  return AssessmentRepository(client);
});

final studentResultsProvider = FutureProvider.autoDispose<StudentResults>(
  (ref) => ref.watch(assessmentRepositoryProvider).studentResults(),
);

final certificatesProvider = FutureProvider.autoDispose<LearnerCertificates>(
  (ref) => ref.watch(assessmentRepositoryProvider).certificates(),
);

/// After a quiz or assignment is submitted: the course moves on too.
void refreshAssessments(WidgetRef ref, String courseId) {
  refreshLearning(ref, courseId);
  ref.invalidate(studentResultsProvider);
  ref.invalidate(certificatesProvider);
}
