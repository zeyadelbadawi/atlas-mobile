import '../api/atlas_api_client.dart';
import 'learning_models.dart';

/// Learner reads and writes for one academy (the client's host).
class LearningRepository {
  LearningRepository(this.client, {this.academyId});

  final AtlasApiClient client;

  /// The signed-in academy. One account can learn in several academies, and
  /// `GET /enrollments` lists all of them unless narrowed to this one.
  final String? academyId;

  Future<LearnerOverview> overview() async => LearnerOverview.fromJson(
    await client.get<Map<String, dynamic>>('learning/overview'),
  );

  Future<List<EnrolledCourse>> enrollments() async {
    final body = await client.get<Map<String, dynamic>>(
      'enrollments',
      query: {'pageSize': 100, 'academyId': ?academyId},
    );
    final items = body['items'];
    return items is List
        ? items
              .whereType<Map>()
              .map((m) => EnrolledCourse.fromJson(Map<String, dynamic>.from(m)))
              .toList()
        : const [];
  }

  Future<CourseSequence> sequence(String courseId) async =>
      CourseSequence.fromJson(
        await client.get<Map<String, dynamic>>(
          'learning/courses/$courseId/sequence',
        ),
      );

  Future<LessonGrant> grant(String courseId, String lessonId) async =>
      LessonGrant.fromJson(
        await client.get<Map<String, dynamic>>(
          'learning/courses/$courseId/lessons/$lessonId/content',
        ),
      );

  /// Marks a lesson done. Returns the course percentage after it.
  ///
  /// [opId] and [clientOpAt] (epoch ms) stamp an operation that may arrive
  /// late (sent from the offline queue): the server keeps the newest per
  /// lesson and answers an older one without applying it.
  Future<double> completeLesson(
    String courseId,
    String lessonId, {
    String? opId,
    int? clientOpAt,
  }) async {
    final body = await client.post<Map<String, dynamic>>(
      'courses/$courseId/progress/complete-lesson',
      data: {'lessonId': lessonId, 'opId': ?opId, 'clientOpAt': ?clientOpAt},
    );
    return (body['percentage'] as num?)?.toDouble() ?? 0;
  }

  /// Takes back a completion (a lesson marked done by mistake). The
  /// server keeps what was watched and leaves later lessons unlocked.
  Future<void> undoCompleteLesson(
    String courseId,
    String lessonId, {
    String? opId,
    int? clientOpAt,
  }) => client.delete<dynamic>(
    'learning/courses/$courseId/progress/complete-lesson/$lessonId',
    query: {'opId': ?opId, 'clientOpAt': ?clientOpAt},
  );

  Future<CourseCompletion> completion(String courseId) async =>
      CourseCompletion.fromJson(
        await client.get<Map<String, dynamic>>(
          'learning/courses/$courseId/completion',
        ),
      );

  Future<LearnerDevices> devices() async => LearnerDevices.fromJson(
    await client.get<Map<String, dynamic>>('learning/devices'),
  );

  Future<void> removeDevice(String id) =>
      client.delete<dynamic>('learning/devices/$id');

  /// Moves the single learning session to this phone (after the learner
  /// confirmed). Returns the new lease.
  Future<Map<String, dynamic>> takeover({String? courseId, String? lessonId}) =>
      client.post<Map<String, dynamic>>(
        'learning/session/takeover',
        data: {'courseId': ?courseId, 'lessonId': ?lessonId},
      );
}
