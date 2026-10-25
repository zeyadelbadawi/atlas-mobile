// Phase 6 against the LOCAL stack, through the app's own repository: a
// public free course is listed in the catalog, opens by id and by slug with
// its outline, and a learner joins it (twice, idempotently). A private
// course is never listed. Env as local_stack.dart.
@Tags(['integration'])
library;

import 'dart:io';

import 'package:atlas_mobile/core/learning/catalog_repository.dart';
import 'package:atlas_mobile/core/learning/learning_repository.dart';
import 'package:test/test.dart';

import 'local_stack.dart';

void main() {
  final skip = Platform.environment['ATLAS_SPIKE_ORIGIN'] == null
      ? 'needs the local stack'
      : null;

  test(
    'free catalog, preview and joining',
    () async {
      final staff = await localStaff();
      final open = await authorAssessedCourse(staff, visibility: 'public');
      final hidden = await authorAssessedCourse(staff);
      final me = await newLocalLearner('p6');
      final catalog = CatalogRepository(me.client, localAcademyId);

      final page = await catalog.freeCourses(search: open.slug.split('-').last);
      expect(page.items.map((c) => c.id), contains(open.courseId));
      expect(page.items.every((c) => c.isFree), isTrue);
      final all = await catalog.freeCourses(search: 'أساسيات الجبر');
      expect(all.items.map((c) => c.id), isNot(contains(hidden.courseId)));

      final byId = await catalog.course(open.courseId);
      final bySlug = await catalog.course(open.slug);
      expect(bySlug.id, byId.id);
      expect(byId.isFree, isTrue);
      expect(byId.totalLessons, 1);
      expect(byId.totalQuizzes, 1);
      expect(byId.totalAssignments, 1);
      expect(byId.certificatesEnabled, isTrue);
      final outline = await catalog.curriculum(open.courseId);
      expect(outline.single.lessons.single.title, 'المعادلات من الدرجة الأولى');

      expect(await catalog.isEnrolled(open.courseId), isFalse);
      await catalog.enroll(open.courseId);
      await catalog.enroll(open.courseId);
      expect(await catalog.isEnrolled(open.courseId), isTrue);
      final mine = await LearningRepository(me.client).enrollments();
      expect(mine.where((e) => e.courseId == open.courseId), hasLength(1));
    },
    skip: skip,
    timeout: const Timeout(Duration(minutes: 4)),
  );
}
