import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/learning/assessment_models.dart';
import '../core/learning/assessment_repository.dart';
import '../core/learning/catalog_repository.dart';
import '../core/learning/learning_models.dart';
import '../core/learning/learning_repository.dart';
import 'providers.dart';
import 'reminders.dart';

/// The learning API for the signed-in academy. Rebuilt when the session
/// changes academy or user, which also refreshes every read below.
final learningRepositoryProvider = Provider<LearningRepository>((ref) {
  ref.watch(sessionProvider.select((s) => (s.academy, s.user?['id'])));
  final client = ref.read(sessionProvider.notifier).client;
  if (client == null) throw StateError('no academy session');
  return LearningRepository(
    client,
    academyId: ref.read(sessionProvider).academy?.id,
  );
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

/// The same, from a provider (the offline queue after it sends).
void refreshCourse(Ref ref, String courseId) {
  ref.invalidate(sequenceProvider(courseId));
  ref.invalidate(completionProvider(courseId));
  ref.invalidate(overviewProvider);
  ref.invalidate(enrollmentsProvider);
}

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
  return AssessmentRepository(
    client,
    academyId: ref.read(sessionProvider).academy?.id,
  );
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
  // A submitted quiz or assignment no longer needs its reminders.
  unawaited(ref.read(remindersProvider.notifier).sync(force: true));
}

/* ---- free catalog (phase 6) ---- */

final catalogRepositoryProvider = Provider<CatalogRepository>((ref) {
  final academy = ref.watch(sessionProvider.select((s) => s.academy));
  ref.watch(sessionProvider.select((s) => s.user?['id']));
  final client = ref.read(sessionProvider.notifier).client;
  if (client == null || academy == null) {
    throw StateError('no academy session');
  }
  return CatalogRepository(client, academy.id);
});

final catalogCourseProvider = FutureProvider.autoDispose
    .family<CatalogCourse, String>(
      (ref, idOrSlug) => ref.watch(catalogRepositoryProvider).course(idOrSlug),
    );

final curriculumProvider = FutureProvider.autoDispose
    .family<List<CurriculumSection>, String>(
      (ref, courseId) =>
          ref.watch(catalogRepositoryProvider).curriculum(courseId),
    );

final isEnrolledProvider = FutureProvider.autoDispose.family<bool, String>(
  (ref, courseId) => ref.watch(catalogRepositoryProvider).isEnrolled(courseId),
);

/// The Tasks tab: quizzes and assignments with where each stands.
final tasksProvider = FutureProvider.autoDispose<List<LearnerTask>>(
  (ref) => ref.watch(assessmentRepositoryProvider).tasks(),
);

final courseRatingProvider = FutureProvider.autoDispose
    .family<RatingSummary, String>(
      (ref, courseId) => ref.watch(catalogRepositoryProvider).rating(courseId),
    );

/// The few newest reviews the course preview shows.
final latestReviewsProvider = FutureProvider.autoDispose
    .family<ReviewsPage, String>(
      (ref, courseId) =>
          ref.watch(catalogRepositoryProvider).reviews(courseId, pageSize: 3),
    );
