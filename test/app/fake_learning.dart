import 'package:atlas_mobile/core/api/academy_endpoint.dart';

import '../design/golden_harness.dart' show testNow;

import 'package:atlas_mobile/core/api/atlas_api_client.dart';
import 'package:atlas_mobile/core/learning/catalog_repository.dart';
import 'package:atlas_mobile/core/learning/learning_models.dart';
import 'package:atlas_mobile/core/learning/learning_repository.dart';
import 'package:cookie_jar/cookie_jar.dart';

import 'demo_text.dart';

/// Sample data for screen goldens (illustrative, not real learners).
class FakeLearningRepository extends LearningRepository {
  FakeLearningRepository()
    : super(
        AtlasApiClient(
          endpoint: AcademyEndpoint.parse('ziadd.atlass.dpdns.org'),
          cookieJar: CookieJar(),
          userAgent: 'test',
        ),
      );

  static const courseId = 'c-calc';
  static final _now = testNow;

  static Map<String, dynamic> _item(
    int pos,
    String title,
    String section,
    int unit,
    int n,
    String state,
    int? minutes, {
    String type = 'lesson',
    String? lock,
  }) => {
    'id': 'l$pos',
    'type': type,
    'title': title,
    'sectionId': 's$unit',
    'sectionTitle': section,
    'unitNumber': unit,
    'itemNumber': n,
    'position': pos,
    'state': state,
    'lockReason': lock,
    'durationSeconds': minutes == null ? null : minutes * 60,
    'isPreview': false,
    'dueAt': null,
    'availableAt': null,
  };

  static Map<String, dynamic> get sequenceJson => {
    'courseId': courseId,
    'courseTitle': demo('التفاضل والتكامل'),
    'items': [
      _item(
        0,
        demo('مقدمة عن النهايات'),
        demo('النهايات'),
        1,
        1,
        'completed',
        12,
      ),
      _item(
        1,
        demo('النهايات بالتعويض المباشر'),
        demo('النهايات'),
        1,
        2,
        'completed',
        18,
      ),
      _item(
        2,
        demo('النهايات من جهة واحدة'),
        demo('النهايات'),
        1,
        3,
        'available',
        22,
      ),
      _item(
        3,
        demo('كويز النهايات'),
        demo('النهايات'),
        1,
        4,
        'locked',
        null,
        type: 'quiz',
        lock: 'previousIncomplete',
      ),
      _item(
        4,
        demo('تعريف الاتصال'),
        demo('الاتصال'),
        2,
        1,
        'locked',
        14,
        lock: 'previousIncomplete',
      ),
      _item(
        5,
        demo('أنواع عدم الاتصال'),
        demo('الاتصال'),
        2,
        2,
        'locked',
        16,
        lock: 'previousIncomplete',
      ),
      _item(
        6,
        demo('واجب الاتصال'),
        demo('الاتصال'),
        2,
        3,
        'locked',
        null,
        type: 'assignment',
        lock: 'previousIncomplete',
      ),
    ],
    'continueItemId': 'l2',
    'completedCount': 2,
    'totalCount': 7,
  };

  @override
  Future<LearnerOverview> overview() async => LearnerOverview.fromJson({
    'continueLearning': [
      {
        'courseId': courseId,
        'courseTitle': demo('التفاضل والتكامل'),
        'percentage': 28.6,
        'completedItems': 2,
        'totalItems': 7,
        'nextItemId': 'l2',
        'nextItemTitle': demo('النهايات من جهة واحدة'),
      },
    ],
    'courseCounts': {'all': 3},
    'upcomingDeadlines': [
      {
        'id': 'd1',
        'type': 'assignment',
        'title': demo('واجب الاتصال'),
        'courseId': courseId,
        'courseTitle': demo('التفاضل والتكامل'),
        'dueAt': _now.add(const Duration(days: 2)).toIso8601String(),
        'overdue': false,
      },
    ],
    'announcements': [
      {
        'id': 'a1',
        'title': demo('مراجعة ليلة الامتحان'),
        'body': demo(
          'مراجعة مباشرة يوم الخميس الساعة ٨ مساءً على المنهج كله. جهّز أسئلتك.',
        ),
        'publishedAt': _now.subtract(const Duration(days: 1)).toIso8601String(),
        'courseId': courseId,
      },
    ],
  });

  @override
  Future<List<EnrolledCourse>> enrollments() async => [
    _enrollment(
      courseId,
      demo('التفاضل والتكامل'),
      demo('أ. أحمد سمير'),
      2,
      7,
      'in_progress',
    ),
    _enrollment(
      'c-phys',
      demo('الفيزياء: الكهربية'),
      demo('أ. منى عادل'),
      0,
      14,
      'not_started',
    ),
    _enrollment(
      'c-chem',
      demo('الكيمياء العضوية'),
      demo('د. خالد فؤاد'),
      12,
      12,
      'completed',
    ),
  ];

  static EnrolledCourse _enrollment(
    String id,
    String title,
    String teacher,
    int done,
    int total,
    String state,
  ) => EnrolledCourse.fromJson({
    'id': 'e-$id',
    'courseId': id,
    'course': {
      'title': title,
      'instructors': [
        {'name': teacher},
      ],
    },
    'progress': {
      'completedItems': done,
      'totalItems': total,
      'percentage': total == 0 ? 0 : done * 100 / total,
      'learningState': state,
    },
    'isActive': true,
  });

  @override
  Future<CourseSequence> sequence(String courseId) async =>
      CourseSequence.fromJson(sequenceJson);

  /// The learner's own review (none by default).
  CourseReview? review;

  @override
  Future<CourseReview?> myReview(String courseId) async => review;

  @override
  Future<CourseReview> saveReview(
    String courseId, {
    required int rating,
    String? body,
  }) async => review = CourseReview.fromJson({
    'id': 'my',
    'rating': rating,
    'body': body,
    'status': 'pending',
    'createdAt': '2026-10-24T10:00:00Z',
  });

  @override
  Future<void> deleteReview(String courseId) async => review = null;

  @override
  Future<CourseCompletion> completion(String courseId) async =>
      CourseCompletion.fromJson({'completed': false});

  @override
  Future<LessonGrant> grant(String courseId, String lessonId) async =>
      LessonGrant.fromJson({
        'lessonId': lessonId,
        'courseId': courseId,
        'title': demo('النهايات من جهة واحدة'),
        'kind': 'text',
        'completionRule': 'manual',
        'bodyHtml':
            demo(
              '<p>النهاية من اليمين هي القيمة التي تقترب منها الدالة عندما تقترب <b>س</b> من العدد من جهة اليمين.</p>',
            ) +
            demo(
              '<ul><li>نكتبها: نهـا س←أ⁺ د(س)</li><li>وتوجد النهاية إذا تساوت النهايتان من اليمين واليسار.</li></ul>',
            ),
        'resources': [
          {
            'id': 'r1',
            'title': demo('ملخص الدرس (PDF)'),
            'url': 'https://example.test/r1.pdf',
          },
        ],
        'watermark': {'enabled': false, 'text': ''},
        'playbackLease': null,
        'resumePositionSeconds': 0,
      });

  @override
  Future<LearnerDevices> devices() async => LearnerDevices.fromJson({
    'devices': [
      {
        'id': 'd1',
        'label': 'Atlas app on iOS',
        'lastSeenAt': _now.toIso8601String(),
        'current': true,
      },
      {
        'id': 'd2',
        'label': 'Chrome on Windows',
        'lastSeenAt': _now.subtract(const Duration(days: 3)).toIso8601String(),
        'current': false,
      },
    ],
    'maxDevices': 2,
    'maxConcurrentSessions': 1,
  });
}
