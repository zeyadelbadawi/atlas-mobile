/// Learning API shapes the app reads. Field names follow the backend
/// contracts (checked against the local stack, see
/// test/integration/learning_shapes_probe_test.dart). Unknown fields are
/// ignored; missing optional ones fall back safely.
library;

DateTime? _date(Object? v) =>
    v is String ? DateTime.tryParse(v)?.toLocal() : null;
int _int(Object? v, [int fallback = 0]) => v is num ? v.toInt() : fallback;
double _double(Object? v) => v is num ? v.toDouble() : 0;
List<Map<String, dynamic>> _list(Object? v) => v is List
    ? v.whereType<Map>().map(Map<String, dynamic>.from).toList()
    : const [];

class ContinueItem {
  ContinueItem.fromJson(Map<String, dynamic> j)
    : courseId = j['courseId'] as String,
      courseTitle = j['courseTitle'] as String? ?? '',
      thumbnailUrl = j['courseThumbnailUrl'] as String?,
      percentage = _double(j['percentage']),
      completed = _int(j['completedItems'] ?? j['completedLessons']),
      total = _int(j['totalItems'] ?? j['totalLessons']),
      nextItemId = j['nextItemId'] as String?,
      nextItemTitle = j['nextItemTitle'] as String?,
      lastActivityAt = _date(j['lastActivityAt']);

  final String courseId;
  final String courseTitle;
  final String? thumbnailUrl;
  final double percentage;
  final int completed;
  final int total;
  final String? nextItemId;
  final String? nextItemTitle;
  final DateTime? lastActivityAt;
}

class Deadline {
  Deadline.fromJson(Map<String, dynamic> j)
    : id = j['id'] as String,
      type = j['type'] as String? ?? 'assignment',
      title = j['title'] as String? ?? '',
      courseId = j['courseId'] as String? ?? '',
      courseTitle = j['courseTitle'] as String? ?? '',
      dueAt = _date(j['dueAt']) ?? DateTime.now(),
      overdue = j['overdue'] == true;

  final String id;
  final String type;
  final String title;
  final String courseId;
  final String courseTitle;
  final DateTime dueAt;
  final bool overdue;
}

class Announcement {
  Announcement.fromJson(Map<String, dynamic> j)
    : id = j['id'] as String,
      title = j['title'] as String? ?? '',
      body = j['body'] as String? ?? '',
      publishedAt = _date(j['publishedAt']),
      courseId = j['courseId'] as String?;

  final String id;
  final String title;
  final String body;
  final DateTime? publishedAt;
  final String? courseId;
}

class LearnerOverview {
  LearnerOverview.fromJson(Map<String, dynamic> j)
    : continueLearning = _list(j['continueLearning'])
          .map(ContinueItem.fromJson)
          .toList(),
      deadlines = _list(j['upcomingDeadlines']).map(Deadline.fromJson).toList(),
      announcements = _list(j['announcements'])
          .map(Announcement.fromJson)
          .toList(),
      allCourses = _int((j['courseCounts'] as Map?)?['all']);

  final List<ContinueItem> continueLearning;
  final List<Deadline> deadlines;
  final List<Announcement> announcements;
  final int allCourses;
}

class EnrolledCourse {
  EnrolledCourse.fromJson(Map<String, dynamic> j)
    : enrollmentId = j['id'] as String,
      courseId = j['courseId'] as String,
      title = (j['course'] as Map?)?['title'] as String? ?? '',
      thumbnailUrl = (j['course'] as Map?)?['thumbnail'] as String?,
      instructors = _list((j['course'] as Map?)?['instructors'])
          .map((i) => i['name'] as String? ?? '')
          .where((n) => n.isNotEmpty)
          .toList(),
      completed = _int(
        (j['progress'] as Map?)?['completedItems'] ??
            (j['progress'] as Map?)?['completedLessons'],
      ),
      total = _int(
        (j['progress'] as Map?)?['totalItems'] ??
            (j['progress'] as Map?)?['totalLessons'],
      ),
      percentage = _double((j['progress'] as Map?)?['percentage']),
      learningState =
          (j['progress'] as Map?)?['learningState'] as String? ?? 'not_started',
      isActive = j['isActive'] != false,
      expiresAt = _date(j['expiresAt']);

  final String enrollmentId;
  final String courseId;
  final String title;
  final String? thumbnailUrl;
  final List<String> instructors;
  final int completed;
  final int total;
  final double percentage;

  /// not_started | in_progress | completed
  final String learningState;
  final bool isActive;
  final DateTime? expiresAt;
}

/// One lesson, quiz, assignment or live session in course order.
class SequenceItem {
  SequenceItem.fromJson(Map<String, dynamic> j)
    : id = j['id'] as String,
      type = j['type'] as String? ?? 'lesson',
      title = j['title'] as String? ?? '',
      sectionId = j['sectionId'] as String? ?? '',
      sectionTitle = j['sectionTitle'] as String? ?? '',
      unitNumber = _int(j['unitNumber'], 1),
      itemNumber = _int(j['itemNumber'], 1),
      position = _int(j['position']),
      state = j['state'] as String? ?? 'available',
      lockReason = j['lockReason'] as String?,
      durationSeconds = j['durationSeconds'] is num
          ? (j['durationSeconds'] as num).toInt()
          : null,
      isPreview = j['isPreview'] == true,
      dueAt = _date(j['dueAt']),
      availableAt = _date(j['availableAt']);

  final String id;
  final String type;
  final String title;
  final String sectionId;
  final String sectionTitle;
  final int unitNumber;
  final int itemNumber;
  final int position;

  /// locked | available | in_progress | completed | passed | failed |
  /// submitted | graded | overdue
  final String state;
  final String? lockReason;
  final int? durationSeconds;
  final bool isPreview;
  final DateTime? dueAt;
  final DateTime? availableAt;

  bool get isLesson => type == 'lesson';
  bool get isLocked => state == 'locked';
  bool get isDone =>
      const {'completed', 'passed', 'submitted', 'graded'}.contains(state);
}

class CourseSequence {
  CourseSequence.fromJson(Map<String, dynamic> j)
    : courseId = j['courseId'] as String,
      courseTitle = j['courseTitle'] as String? ?? '',
      items = _list(j['items']).map(SequenceItem.fromJson).toList(),
      continueItemId = j['continueItemId'] as String?,
      completedCount = _int(j['completedCount']),
      totalCount = _int(j['totalCount']);

  final String courseId;
  final String courseTitle;
  final List<SequenceItem> items;
  final String? continueItemId;
  final int completedCount;
  final int totalCount;

  SequenceItem? get continueItem =>
      items.where((i) => i.id == continueItemId).firstOrNull;

  bool get finished => totalCount > 0 && completedCount >= totalCount;

  SequenceItem? after(String id) {
    final i = items.indexWhere((e) => e.id == id);
    return i >= 0 && i + 1 < items.length ? items[i + 1] : null;
  }
}

class GrantResource {
  GrantResource.fromJson(Map<String, dynamic> j)
    : id = j['id'] as String,
      title = j['title'] as String? ?? '',
      url = (j['url'] ?? j['externalUrl']) as String?;

  final String id;
  final String title;
  final String? url;
}

/// `GET learning/courses/:id/lessons/:lessonId/content`.
class LessonGrant {
  LessonGrant.fromJson(this.raw)
    : lessonId = raw['lessonId'] as String,
      courseId = raw['courseId'] as String,
      title = raw['title'] as String? ?? '',
      kind = raw['kind'] as String? ?? 'text',
      completionRule = raw['completionRule'] as String? ?? 'manual',
      minimumWatchedRatio = (raw['minimumWatchedRatio'] as num?)?.toDouble(),
      bodyHtml = raw['bodyHtml'] as String?,
      fileUrl = raw['fileUrl'] as String?,
      fileName = raw['fileName'] as String?,
      externalUrl = raw['externalUrl'] as String?,
      youtubeId = (raw['externalEmbed'] as Map?)?['provider'] == 'youtube'
          ? (raw['externalEmbed'] as Map)['videoId'] as String?
          : null,
      hostedVideoUrl = (raw['video'] as Map?)?['url'] as String?,
      resources = _list(raw['resources']).map(GrantResource.fromJson).toList(),
      watermarkCode = (raw['watermark'] as Map?)?['code'] as String?,
      watermarkIdentity =
          (raw['watermark'] as Map?)?['maskedIdentity'] as String?,
      resumeSeconds = _int(raw['resumePositionSeconds']);

  final Map<String, dynamic> raw;
  final String lessonId;
  final String courseId;
  final String title;

  /// text | video | file | external
  final String kind;

  /// manual | watched_ratio
  final String completionRule;
  final double? minimumWatchedRatio;
  final String? bodyHtml;
  final String? fileUrl;
  final String? fileName;
  final String? externalUrl;
  final String? youtubeId;
  final String? hostedVideoUrl;
  final List<GrantResource> resources;
  final String? watermarkCode;
  final String? watermarkIdentity;
  final int resumeSeconds;
}

class CourseCompletion {
  CourseCompletion.fromJson(Map<String, dynamic> j)
    : completed = j['completed'] == true,
      completedAt = _date(j['completedAt']),
      missing = _list(j['missing']),
      certificateEnabled = (j['certificate'] as Map?)?['enabled'] == true,
      certificateStatus =
          (j['certificate'] as Map?)?['status'] as String? ?? 'unavailable';

  final bool completed;
  final DateTime? completedAt;
  final List<Map<String, dynamic>> missing;
  final bool certificateEnabled;
  final String certificateStatus;
}

class LearnerDevice {
  LearnerDevice.fromJson(Map<String, dynamic> j)
    : id = j['id'] as String,
      label = j['label'] as String? ?? '',
      lastSeenAt = _date(j['lastSeenAt']),
      current = j['current'] == true;

  final String id;
  final String label;
  final DateTime? lastSeenAt;
  final bool current;
}

class LearnerDevices {
  LearnerDevices.fromJson(Map<String, dynamic> j)
    : devices = _list(j['devices']).map(LearnerDevice.fromJson).toList(),
      maxDevices = _int(j['maxDevices'], 1),
      maxSessions = _int(j['maxConcurrentSessions'], 1);

  final List<LearnerDevice> devices;
  final int maxDevices;
  final int maxSessions;
}
