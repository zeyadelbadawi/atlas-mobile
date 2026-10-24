/// Quiz, assignment, results and certificate shapes. Field names follow the
/// backend contracts, checked against the local stack
/// (test/integration/assessment_shapes_probe_test.dart). Unknown fields are
/// ignored; missing optional ones fall back safely.
library;

DateTime? _date(Object? v) =>
    v is String ? DateTime.tryParse(v)?.toLocal() : null;
int _int(Object? v, [int fallback = 0]) => v is num ? v.toInt() : fallback;
int? _intOrNull(Object? v) => v is num ? v.toInt() : null;
double? _num(Object? v) => v is num ? v.toDouble() : null;
String _str(Object? v) => v is String ? v : '';
List<Map<String, dynamic>> _list(Object? v) => v is List
    ? v.whereType<Map>().map(Map<String, dynamic>.from).toList()
    : const [];
Map<String, dynamic> _map(Object? v) =>
    v is Map ? Map<String, dynamic>.from(v) : const {};
List<String> _strings(Object? v) =>
    v is List ? v.whereType<String>().toList() : const [];

/* ---------------------------------------------------------------- quiz */

const textQuestionTypes = {'short_answer', 'essay'};

class QuizOption {
  QuizOption.fromJson(Map<String, dynamic> j)
    : id = _str(j['id']),
      label = _str(j['label']);
  const QuizOption(this.id, this.label);
  final String id;
  final String label;
}

/// The settings a learner may see before starting.
class QuizSettings {
  QuizSettings.fromJson(Map<String, dynamic> j)
    : mode = j['mode'] as String? ?? 'practice',
      timeLimitSeconds = _intOrNull(j['timeLimitSeconds']),
      availableFrom = _date(j['availableFrom']),
      availableUntil = _date(j['availableUntil']),
      dueAt = _date(j['dueAt']),
      latePolicy = j['latePolicy'] as String? ?? 'block',
      gradingPolicy = j['gradingPolicy'] as String? ?? 'highest',
      layout = j['layout'] as String? ?? 'all_questions',
      integrityMode = j['integrityMode'] as String? ?? 'off',
      maxViolations = _int(j['maxViolations']),
      requireFullscreen = j['requireFullscreen'] == true,
      hideTimer = j['hideTimer'] == true,
      showScore = j['showScore'] as String? ?? 'immediately',
      showAnswers = j['showAnswers'] as String? ?? 'never';

  final String mode;
  final String showScore;
  final String showAnswers;
  final int? timeLimitSeconds;
  final DateTime? availableFrom;
  final DateTime? availableUntil;
  final DateTime? dueAt;
  final String latePolicy;
  final String gradingPolicy;
  final String layout;
  final String integrityMode;
  final int maxViolations;
  final bool requireFullscreen;
  final bool hideTimer;

  bool get integrityOn => integrityMode != 'off';
  bool get integrityWarns =>
      integrityMode == 'warn' || integrityMode == 'strict';
}

class Quiz {
  Quiz.fromJson(Map<String, dynamic> j)
    : id = _str(j['id']),
      courseId = _str(j['courseId']),
      title = _str(j['title']),
      description = j['description'] as String?,
      questionCount = _int(j['questionCount']),
      passingScore = _intOrNull(j['passingScore']),
      // `attemptsAllowed` is the learner's own allowance (extra attempts
      // included); null = unlimited. Older servers only send maxAttempts.
      attemptsAllowed = j.containsKey('attemptsAllowed')
          ? _intOrNull(j['attemptsAllowed'])
          : _intOrNull(j['maxAttempts']),
      settings = QuizSettings.fromJson(_map(j['settings'])),
      optionLabels = {
        for (final q in _list(j['questions']))
          for (final o in _list(q['options'])) _str(o['id']): _str(o['label']),
      };

  /// Option id → label, to show answers on the results screen.
  final Map<String, String> optionLabels;

  final String id;
  final String courseId;
  final String title;
  final String? description;
  final int questionCount;
  final int? passingScore;
  final int? attemptsAllowed;
  final QuizSettings settings;
}

/// One answer: option ids for choice questions, text for typed ones.
class QuizAnswer {
  const QuizAnswer({
    required this.questionId,
    this.selected = const [],
    this.text,
  });

  QuizAnswer.fromJson(Map<String, dynamic> j)
    : questionId = _str(j['questionId']),
      selected = _strings(j['selectedOptionIds']),
      text = j['text'] as String?;

  final String questionId;
  final List<String> selected;
  final String? text;

  bool get isAnswered =>
      selected.isNotEmpty || (text != null && text!.trim().isNotEmpty);

  Map<String, Object?> toJson() => {
    'questionId': questionId,
    if (selected.isNotEmpty) 'selectedOptionIds': selected,
    if (text != null) 'text': text,
  };

  /// Same selection (order-insensitive) and text.
  bool sameAs(QuizAnswer? other) {
    if (other == null) return false;
    final a = [...selected]..sort();
    final b = [...other.selected]..sort();
    return a.join(' ') == b.join(' ') && (text ?? '') == (other.text ?? '');
  }
}

const finishedAttemptStatuses = {
  'submitted',
  'passed',
  'failed',
  'expired',
  'invalidated',
};

class QuizAttempt {
  QuizAttempt.fromJson(Map<String, dynamic> j)
    : id = _str(j['id']),
      status = j['status'] as String? ?? 'in_progress',
      attemptNumber = _int(j['attemptNumber'], 1),
      score = _num(j['score']),
      passed = j['passed'] as bool?,
      submittedAt = _date(j['submittedAt']),
      gradingStatus = j['gradingStatus'] as String? ?? 'not_required';

  final String id;
  final String status;
  final int attemptNumber;
  final double? score;
  final bool? passed;
  final DateTime? submittedAt;
  final String gradingStatus;

  bool get isOpen => status == 'in_progress' || status == 'not_started';
}

class QuizSessionQuestion {
  QuizSessionQuestion.fromJson(Map<String, dynamic> j)
    : id = _str(j['id']),
      type = j['type'] as String? ?? 'single_choice',
      prompt = _str(j['prompt']),
      points = _num(j['points']) ?? 1,
      options = _list(j['options']).map(QuizOption.fromJson).toList();

  const QuizSessionQuestion({
    required this.id,
    required this.type,
    required this.prompt,
    this.points = 1,
    this.options = const [],
  });

  final String id;
  final String type;
  final String prompt;
  final double points;
  final List<QuizOption> options;

  bool get isText => textQuestionTypes.contains(type);
  bool get isMultiple => type == 'multiple_choice';
}

/// The settings frozen into the attempt when it started.
class AttemptSettings {
  AttemptSettings.fromJson(Map<String, dynamic> j)
    : layout = j['layout'] as String? ?? 'all_questions',
      hideTimer = j['hideTimer'] == true,
      integrityMode = j['integrityMode'] as String? ?? 'off',
      maxViolations = _int(j['maxViolations']),
      requireFullscreen = j['requireFullscreen'] == true,
      timeLimitSeconds = _intOrNull(j['timeLimitSeconds']);

  final String layout;
  final bool hideTimer;
  final String integrityMode;
  final int maxViolations;
  final bool requireFullscreen;
  final int? timeLimitSeconds;

  bool get integrityOn => integrityMode != 'off';
  bool get integrityWarns =>
      integrityMode == 'warn' || integrityMode == 'strict';
}

/// Everything needed to resume an attempt. The server is the clock: the
/// countdown runs from [serverNow] and [deadlineAt], never the phone's.
class QuizSession {
  QuizSession.fromJson(Map<String, dynamic> j)
    : attemptId = _str(j['attemptId']),
      status = j['status'] as String? ?? 'in_progress',
      attemptNumber = _int(j['attemptNumber'], 1),
      deadlineAt = j['deadlineAt'] as String?,
      serverNow = j['serverNow'] as String?,
      revision = _int(j['revision']),
      lastSavedAt = _date(j['lastSavedAt']),
      violationCount = _int(j['violationCount']),
      settings = AttemptSettings.fromJson(_map(j['settings'])),
      questions = _list(j['questions'])
          .map(QuizSessionQuestion.fromJson)
          .toList(),
      answers = _list(j['answers']).map(QuizAnswer.fromJson).toList();

  final String attemptId;
  final String status;
  final int attemptNumber;
  final String? deadlineAt;
  final String? serverNow;
  final int revision;
  final DateTime? lastSavedAt;
  final int violationCount;
  final AttemptSettings settings;
  final List<QuizSessionQuestion> questions;
  final List<QuizAnswer> answers;
}

class SaveAnswersResult {
  SaveAnswersResult.fromJson(Map<String, dynamic> j)
    : revision = _int(j['revision']),
      applied = j['applied'] != false,
      savedAt = _date(j['savedAt']),
      serverNow = j['serverNow'] as String?,
      deadlineAt = j['deadlineAt'] as String?,
      answers = j['answers'] is List
          ? _list(j['answers']).map(QuizAnswer.fromJson).toList()
          : null;

  final int revision;
  final bool applied;
  final DateTime? savedAt;
  final String? serverNow;
  final String? deadlineAt;

  /// Only when not applied: the newer answers the server holds.
  final List<QuizAnswer>? answers;
}

class EventsResult {
  EventsResult.fromJson(Map<String, dynamic> j)
    : violationCount = _int(j['violationCount']),
      maxViolations = _int(j['maxViolations']),
      action = j['action'] as String? ?? 'none',
      status = j['status'] as String? ?? 'in_progress';

  final int violationCount;
  final int maxViolations;
  final String action;
  final String status;
}

class QuizResultQuestion {
  QuizResultQuestion.fromJson(Map<String, dynamic> j)
    : questionId = _str(j['questionId']),
      prompt = _str(j['prompt']),
      type = j['type'] as String? ?? 'single_choice',
      points = _num(j['points']) ?? 0,
      answered = j['answered'] == true,
      correct = j['correct'] as bool?,
      pointsAwarded = _num(j['pointsAwarded']),
      yourAnswer = j['yourAnswer'] is Map
          ? QuizAnswer.fromJson(_map(j['yourAnswer']))
          : null,
      correctOptionIds = j['correctOptionIds'] is List
          ? _strings(j['correctOptionIds'])
          : null,
      acceptedAnswers = _strings(j['acceptedAnswers']),
      explanation = j['explanation'] as String?,
      relatedLessonId = j['relatedLessonId'] as String?,
      needsManualGrading = j['needsManualGrading'] == true;

  final String questionId;
  final String prompt;
  final String type;
  final double points;
  final bool answered;
  final bool? correct;
  final double? pointsAwarded;
  final QuizAnswer? yourAnswer;
  final List<String>? correctOptionIds;
  final List<String> acceptedAnswers;
  final String? explanation;
  final String? relatedLessonId;
  final bool needsManualGrading;
}

class QuizResults {
  QuizResults.fromJson(Map<String, dynamic> j)
    : attemptId = _str(j['attemptId']),
      status = j['status'] as String? ?? 'submitted',
      attemptNumber = _int(j['attemptNumber'], 1),
      submittedAt = _date(j['submittedAt']),
      autoSubmitted = j['autoSubmitted'] == true,
      autoSubmittedReason = j['autoSubmittedReason'] as String?,
      isLate = j['isLate'] == true,
      gradingStatus = j['gradingStatus'] as String? ?? 'not_required',
      showsScore = _map(j['disclosure'])['score'] == true,
      showsAnswers = _map(j['disclosure'])['answers'] == true,
      score = _num(j['score']),
      passed = j['passed'] as bool?,
      pointsEarned = _num(j['pointsEarned']),
      pointsTotal = _num(j['pointsTotal']),
      passingScore = _intOrNull(j['passingScore']),
      effectiveScore = _num(j['effectiveScore']),
      questions = _list(j['questions'])
          .map(QuizResultQuestion.fromJson)
          .toList(),
      canRetry = j['canRetry'] == true,
      attemptsUsed = _int(j['attemptsUsed']),
      attemptsAllowed = _intOrNull(j['attemptsAllowed']);

  final String attemptId;
  final String status;
  final int attemptNumber;
  final DateTime? submittedAt;
  final bool autoSubmitted;
  final String? autoSubmittedReason;
  final bool isLate;
  final String gradingStatus;
  final bool showsScore;
  final bool showsAnswers;
  final double? score;
  final bool? passed;
  final double? pointsEarned;
  final double? pointsTotal;
  final int? passingScore;
  final double? effectiveScore;
  final List<QuizResultQuestion> questions;
  final bool canRetry;
  final int attemptsUsed;
  final int? attemptsAllowed;

  bool get pendingGrading => gradingStatus == 'pending';
}

/* ---------------------------------------------------------- assignment */

const maxAssignmentResponseLength = 5000;
const maxAttachmentBytes = 10 * 1024 * 1024;
const allowedAttachmentTypes = {
  'application/pdf',
  'image/png',
  'image/jpeg',
  'image/jpg',
  'image/gif',
  'image/webp',
};

class Assignment {
  Assignment.fromJson(Map<String, dynamic> j)
    : id = _str(j['id']),
      courseId = _str(j['courseId']),
      title = _str(j['title']),
      description = j['description'] as String?,
      instructions = j['instructions'] as String?,
      dueAt = _date(j['dueAt']),
      allowResubmission = j['allowResubmission'] == true,
      latePolicy = j['latePolicy'] as String? ?? 'block';

  final String id;
  final String courseId;
  final String title;
  final String? description;
  final String? instructions;
  final DateTime? dueAt;
  final bool allowResubmission;
  final String latePolicy;

  bool get pastDue => dueAt != null && DateTime.now().isAfter(dueAt!);
  bool get blockedByDue => pastDue && latePolicy == 'block';
}

/// A protected attachment: [url] is a short-lived signed link.
class SubmissionAttachment {
  SubmissionAttachment.fromJson(Map<String, dynamic> j)
    : assetId = _str(j['assetId']),
      fileName = _str(j['fileName']),
      mimeType = _str(j['mimeType']),
      sizeBytes = _int(j['sizeBytes']),
      url = j['url'] as String?;

  const SubmissionAttachment({
    required this.assetId,
    required this.fileName,
    required this.mimeType,
    required this.sizeBytes,
    this.url,
  });

  final String assetId;
  final String fileName;
  final String mimeType;
  final int sizeBytes;
  final String? url;
}

class AssignmentSubmission {
  AssignmentSubmission.fromJson(Map<String, dynamic> j)
    : id = _str(j['id']),
      status = j['status'] as String? ?? 'draft',
      response = j['response'] as String?,
      attachment = j['attachment'] is Map
          ? SubmissionAttachment.fromJson(_map(j['attachment']))
          : null,
      submittedAt = _date(j['submittedAt']),
      isLate = j['isLate'] == true,
      draftResponse = j['draftResponse'] as String?,
      draftSavedAt = j['draftSavedAt'] as String?,
      submittedRevision = _int(j['submittedRevision']),
      gradingStatus = j['gradingStatus'] as String? ?? 'ungraded',
      score = _num(_map(j['grade'])['score']),
      feedback = _map(j['grade'])['feedback'] as String?,
      gradedAt = _date(_map(j['grade'])['gradedAt']);

  final String id;
  final String status;
  final String? response;
  final SubmissionAttachment? attachment;
  final DateTime? submittedAt;
  final bool isLate;
  final String? draftResponse;

  /// Kept as the server's string: it is the compare-and-set base.
  final String? draftSavedAt;
  final int submittedRevision;
  final String gradingStatus;
  final double? score;
  final String? feedback;
  final DateTime? gradedAt;

  bool get isSubmitted => status == 'submitted';
  bool get isGraded => gradingStatus == 'graded';
}

/* ------------------------------------------------------------- results */

class QuizResultRow {
  QuizResultRow.fromJson(Map<String, dynamic> j)
    : quizId = _str(j['quizId']),
      title = _str(j['quizTitle']),
      attemptNumber = _int(j['attemptNumber'], 1),
      score = _num(j['score']),
      passed = j['passed'] as bool?,
      submittedAt = _date(j['submittedAt']);

  final String quizId;
  final String title;
  final int attemptNumber;
  final double? score;
  final bool? passed;
  final DateTime? submittedAt;
}

class AssignmentResultRow {
  AssignmentResultRow.fromJson(Map<String, dynamic> j)
    : assignmentId = _str(j['assignmentId']),
      title = _str(j['assignmentTitle']),
      graded = j['gradingStatus'] == 'graded',
      score = _num(j['score']),
      hasFeedback = j['hasFeedback'] == true,
      submittedAt = _date(j['submittedAt']);

  final String assignmentId;
  final String title;
  final bool graded;
  final double? score;
  final bool hasFeedback;
  final DateTime? submittedAt;
}

class CourseResults {
  CourseResults.fromJson(Map<String, dynamic> j)
    : courseId = _str(j['courseId']),
      courseTitle = _str(j['courseTitle']),
      percentage = _num(_map(j['progress'])['percentage']),
      quizzes = _list(j['quizResults']).map(QuizResultRow.fromJson).toList(),
      assignments = _list(j['assignmentResults'])
          .map(AssignmentResultRow.fromJson)
          .toList();

  final String courseId;
  final String courseTitle;
  final double? percentage;
  final List<QuizResultRow> quizzes;
  final List<AssignmentResultRow> assignments;
}

class StudentResults {
  StudentResults.fromJson(Map<String, dynamic> j)
    : coursesEnrolled = _int(_map(j['summary'])['coursesEnrolled']),
      coursesCompleted = _int(_map(j['summary'])['coursesCompleted']),
      quizzesAttempted = _int(_map(j['summary'])['quizzesAttempted']),
      quizzesPassed = _int(_map(j['summary'])['quizzesPassed']),
      assignmentsSubmitted = _int(_map(j['summary'])['assignmentsSubmitted']),
      averageQuizScore = _num(_map(j['summary'])['averageQuizScore']),
      courses = _list(j['courses']).map(CourseResults.fromJson).toList();

  final int coursesEnrolled;
  final int coursesCompleted;
  final int quizzesAttempted;
  final int quizzesPassed;
  final int assignmentsSubmitted;

  /// Null when nothing is scored yet — never shown as 0.
  final double? averageQuizScore;
  final List<CourseResults> courses;

  bool get isEmpty =>
      courses.every((c) => c.quizzes.isEmpty && c.assignments.isEmpty);
}

/* -------------------------------------------------------- certificates */

class Certificate {
  Certificate.fromJson(Map<String, dynamic> j)
    : id = _str(j['id']),
      courseId = _str(j['courseId']),
      courseTitle = _str(j['courseTitle']),
      serial = _str(j['serial']),
      verificationCode = _str(j['verificationCode']),
      codeDisplay =
          j['verificationCodeDisplay'] as String? ??
          _str(j['verificationCode']),
      status = j['status'] as String? ?? 'issued',
      renderStatus = j['renderStatus'] as String? ?? 'pending',
      issuedAt = _date(j['issuedAt']),
      revokedAt = _date(j['revokedAt']),
      revokeReason = j['revokeReason'] as String?,
      overallScore = _num(j['overallScore']),
      nameOnCertificate =
          j['learnerNameOnCertificate'] as String? ?? _str(j['studentName']);

  final String id;
  final String courseId;
  final String courseTitle;
  final String serial;
  final String verificationCode;
  final String codeDisplay;
  final String status;
  final String renderStatus;
  final DateTime? issuedAt;
  final DateTime? revokedAt;
  final String? revokeReason;
  final double? overallScore;
  final String nameOnCertificate;

  bool get revoked => status == 'revoked';
  bool get downloadable => !revoked && renderStatus == 'ready';
}

class LearnerCertificates {
  LearnerCertificates.fromJson(Map<String, dynamic> j)
    : enabled = j['enabled'] == true,
      items = _list(j['items']).map(Certificate.fromJson).toList();

  /// False when the academy issues no certificates at all.
  final bool enabled;
  final List<Certificate> items;
}

/// A short-lived signed link to the rendered PDF.
class CertificateDownload {
  CertificateDownload.fromJson(Map<String, dynamic> j)
    : url = _str(j['url']),
      expiresAt = _date(j['expiresAt']),
      fileName = j['fileName'] as String? ?? 'certificate.pdf';

  final String url;
  final DateTime? expiresAt;
  final String fileName;
}
