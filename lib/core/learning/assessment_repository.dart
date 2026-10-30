import '../api/atlas_api_client.dart';
import 'assessment_models.dart';

/// Quizzes, assignments, results and certificates for one academy (the
/// client's host). Every decision — grading, deadlines, what is disclosed,
/// integrity verdicts — is the server's; this only carries requests.
class AssessmentRepository {
  AssessmentRepository(this.client, {this.academyId});

  final AtlasApiClient client;

  /// The signed-in academy: results are narrowed to it (an account can
  /// learn in several academies).
  final String? academyId;

  String _quiz(String courseId, String quizId) =>
      'courses/$courseId/quizzes/$quizId';
  String _attempt(String courseId, String quizId, String attemptId) =>
      '${_quiz(courseId, quizId)}/attempts/$attemptId';
  String _assignment(String courseId, String id) =>
      'courses/$courseId/assignments/$id';

  /* ---- quiz ---- */

  Future<Quiz> quiz(String courseId, String quizId) async => Quiz.fromJson(
    await client.get<Map<String, dynamic>>(_quiz(courseId, quizId)),
  );

  Future<List<QuizAttempt>> attempts(String courseId, String quizId) async {
    final body = await client.get<Map<String, dynamic>>(
      '${_quiz(courseId, quizId)}/attempts',
      query: {'pageSize': 100},
    );
    final items = body['items'];
    final list = items is List
        ? items
              .whereType<Map>()
              .map((m) => QuizAttempt.fromJson(Map<String, dynamic>.from(m)))
              .toList()
        : <QuizAttempt>[];
    return list..sort((a, b) => b.attemptNumber.compareTo(a.attemptNumber));
  }

  /// Starts a new attempt, or returns the open one.
  Future<QuizAttempt> start(String courseId, String quizId) async =>
      QuizAttempt.fromJson(
        await client.post<Map<String, dynamic>>(
          '${_quiz(courseId, quizId)}/attempts',
        ),
      );

  Future<QuizSession> session(
    String courseId,
    String quizId,
    String attemptId,
  ) async => QuizSession.fromJson(
    await client.get<Map<String, dynamic>>(
      _attempt(courseId, quizId, attemptId),
    ),
  );

  Future<SaveAnswersResult> saveAnswers(
    String courseId,
    String quizId,
    String attemptId, {
    required int revision,
    required List<QuizAnswer> answers,
  }) async => SaveAnswersResult.fromJson(
    await client.put<Map<String, dynamic>>(
      '${_attempt(courseId, quizId, attemptId)}/answers',
      data: {
        'revision': revision,
        'answers': [for (final a in answers) a.toJson()],
      },
    ),
  );

  Future<QuizAttempt> submit(
    String courseId,
    String quizId,
    String attemptId, {
    required List<QuizAnswer> answers,
    required int revision,
  }) async => QuizAttempt.fromJson(
    await client.post<Map<String, dynamic>>(
      '${_attempt(courseId, quizId, attemptId)}/submit',
      data: {
        'answers': [for (final a in answers) a.toJson()],
        'revision': revision,
      },
    ),
  );

  Future<EventsResult> recordEvents(
    String courseId,
    String quizId,
    String attemptId,
    List<Map<String, Object?>> events,
  ) async => EventsResult.fromJson(
    await client.post<Map<String, dynamic>>(
      '${_attempt(courseId, quizId, attemptId)}/events',
      data: {'events': events},
    ),
  );

  Future<QuizResults> results(
    String courseId,
    String quizId,
    String attemptId,
  ) async => QuizResults.fromJson(
    await client.get<Map<String, dynamic>>(
      '${_attempt(courseId, quizId, attemptId)}/results',
    ),
  );

  /* ---- assignment ---- */

  Future<Assignment> assignment(String courseId, String id) async =>
      Assignment.fromJson(
        await client.get<Map<String, dynamic>>(_assignment(courseId, id)),
      );

  /// Null until the learner saved a draft or submitted.
  Future<AssignmentSubmission?> submission(String courseId, String id) async {
    final body = await client.get<dynamic>(
      '${_assignment(courseId, id)}/submission',
    );
    return body is Map
        ? AssignmentSubmission.fromJson(Map<String, dynamic>.from(body))
        : null;
  }

  /// Compare-and-set on [baseDraftSavedAt]: a draft changed elsewhere
  /// meanwhile is refused with `errors.assignment.draftConflict`.
  Future<AssignmentSubmission> saveDraft(
    String courseId,
    String id, {
    required String response,
    required String? attachmentAssetId,
    required String? baseDraftSavedAt,
  }) async => AssignmentSubmission.fromJson(
    await client.put<Map<String, dynamic>>(
      '${_assignment(courseId, id)}/submission/draft',
      data: {
        'response': response,
        'attachmentAssetId': attachmentAssetId,
        'baseDraftSavedAt': baseDraftSavedAt,
      },
    ),
  );

  /// Uploads into protected storage; answers with the asset to reference.
  Future<SubmissionAttachment> uploadAttachment(
    String courseId,
    String id, {
    required String fileName,
    required String mimeType,
    required int sizeBytes,
    required String dataUrl,
  }) async => SubmissionAttachment.fromJson(
    await client.post<Map<String, dynamic>>(
      '${_assignment(courseId, id)}/submission/attachment',
      data: {
        'fileName': fileName,
        'mimeType': mimeType,
        'sizeBytes': sizeBytes,
        'dataUrl': dataUrl,
      },
    ),
  );

  /// [idempotencyKey] is the same on every retry of one submit, so a retry
  /// after a dropped connection never submits twice.
  Future<AssignmentSubmission> submitAssignment(
    String courseId,
    String id, {
    required String? response,
    required String? attachmentAssetId,
    required String idempotencyKey,
    required int baseRevision,
  }) async => AssignmentSubmission.fromJson(
    await client.post<Map<String, dynamic>>(
      '${_assignment(courseId, id)}/submission',
      data: {
        'response': ?response,
        'attachmentAssetId': ?attachmentAssetId,
        'idempotencyKey': idempotencyKey,
        'baseRevision': baseRevision,
      },
    ),
  );

  /* ---- results & certificates ---- */

  Future<StudentResults> studentResults() async => StudentResults.fromJson(
    await client.get<Map<String, dynamic>>(
      'learning/results',
      query: {'academyId': ?academyId},
    ),
  );

  Future<LearnerCertificates> certificates() async =>
      LearnerCertificates.fromJson(
        await client.get<Map<String, dynamic>>('learning/certificates'),
      );

  /// A fresh signed link, asked for at the moment of opening.
  Future<CertificateDownload> certificateDownload(String id) async =>
      CertificateDownload.fromJson(
        await client.get<Map<String, dynamic>>(
          'learning/certificates/$id/download',
        ),
      );
}
