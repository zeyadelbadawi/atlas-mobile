import 'package:atlas_mobile/core/api/academy_endpoint.dart';
import 'package:atlas_mobile/core/api/atlas_api_client.dart';
import 'package:atlas_mobile/core/auth/auth_repository.dart';
import 'package:atlas_mobile/core/learning/catalog_repository.dart';
import 'package:cookie_jar/cookie_jar.dart';

AtlasApiClient _client() => AtlasApiClient(
  endpoint: AcademyEndpoint.parse('ziadd.atlass.dpdns.org'),
  cookieJar: CookieJar(),
  userAgent: 'test',
);

Map<String, dynamic> _course(
  String id,
  String title,
  String teacher,
  int lessons, {
  String level = 'beginner',
}) => {
  'id': id,
  'slug': id,
  'title': title,
  'shortDescription': 'كورس مجاني للمبتدئين.',
  'description': 'يشرح الكورس الأساسيات خطوة بخطوة بأمثلة محلولة، ويختم كل وحدة باختبار قصير.',
  'pricing': {'type': 'free'},
  'instructors': [
    {'id': 'i-$id', 'name': teacher},
  ],
  'level': level,
  'language': 'ar',
  'outcomes': ['حل المعادلات من الدرجة الأولى', 'قراءة الرسوم البيانية'],
  'requirements': ['الحساب الأساسي'],
  'certificatesEnabled': true,
  'stats': {
    'totalSections': 3,
    'totalLessons': lessons,
    'totalQuizzes': 2,
    'totalAssignments': 1,
    'durationSeconds': 5400,
  },
};

/// Sample catalog for screen goldens (illustrative, not real courses).
class FakeCatalogRepository extends CatalogRepository {
  FakeCatalogRepository() : super(_client(), 'ziadd');

  static final _courses = [
    _course('free-algebra', 'أساسيات الجبر', 'أ. زياد', 12),
    _course('free-physics', 'مدخل إلى الفيزياء', 'أ. منى', 9),
    _course(
      'free-english',
      'قواعد اللغة الإنجليزية',
      'أ. سارة',
      15,
      level: 'all_levels',
    ),
  ];

  /// A sample course's JSON (the first one for an unknown id).
  static Map<String, dynamic> raw(String id) =>
      _courses.firstWhere((c) => c['id'] == id, orElse: () => _courses[0]);

  @override
  Future<CatalogPage> freeCourses({int page = 1, String? search}) async =>
      CatalogPage.fromJson({
        'items': _courses,
        'pagination': {'page': 1, 'totalPages': 1},
      });

  @override
  Future<CatalogCourse> course(String idOrSlug) async => CatalogCourse.fromJson(
    _courses.firstWhere((c) => c['id'] == idOrSlug, orElse: () => _courses[0]),
  );

  @override
  Future<List<CurriculumSection>> curriculum(String courseId) async => [
    CurriculumSection.fromJson({
      'title': 'المعادلات',
      'lessons': [
        {'title': 'ما هي المعادلة؟', 'contentType': 'video'},
        {'title': 'حل معادلة بخطوة واحدة', 'contentType': 'video'},
        {'title': 'ملخص الوحدة', 'contentType': 'file'},
      ],
    }),
    CurriculumSection.fromJson({
      'title': 'الرسوم البيانية',
      'lessons': [
        {'title': 'المحاور والنقاط', 'contentType': 'text'},
      ],
    }),
  ];

  @override
  Future<bool> isEnrolled(String courseId) async => false;
}

/// The sample catalog with approved reviews.
class RatedCatalog extends FakeCatalogRepository {
  @override
  Future<CatalogPage> freeCourses({int page = 1, String? search}) async {
    final p = await super.freeCourses();
    return CatalogPage.fromJson({
      'items': [for (final c in p.items) _rated(c.id)],
      'pagination': {'page': 1, 'totalPages': 1},
    });
  }

  @override
  Future<CatalogCourse> course(String idOrSlug) async =>
      CatalogCourse.fromJson(_rated(idOrSlug));

  Map<String, dynamic> _rated(String id) {
    final raw = FakeCatalogRepository.raw(id);
    final (avg, n) = switch (id) {
      'free-algebra' => (4.6, 23),
      'free-physics' => (4.2, 8),
      _ => (0.0, 0),
    };
    return {
      ...raw,
      'stats': {
        ...(raw['stats'] as Map<String, dynamic>),
        'averageRating': avg,
        'totalReviews': n,
      },
    };
  }

  @override
  Future<RatingSummary> rating(String courseId) async =>
      RatingSummary.fromJson({
        'averageRating': 4.6,
        'totalReviews': 23,
        'distribution': {'5': 16, '4': 5, '3': 1, '2': 1, '1': 0},
      });

  @override
  Future<ReviewsPage> reviews(
    String courseId, {
    int page = 1,
    int pageSize = 20,
  }) async => ReviewsPage.fromJson({
    'items': [
      {
        'id': 'r1',
        'studentName': 'مريم حسن',
        'rating': 5,
        'body': 'شرح واضح جدًا، والأمثلة المحلولة ساعدتني أفهم المعادلات.',
        'createdAt': '2026-10-20T10:00:00Z',
      },
      {
        'id': 'r2',
        'studentName': 'Omar Khaled',
        'rating': 4,
        'body': 'Good course. More practice questions would help.',
        'createdAt': '2026-10-12T10:00:00Z',
      },
      {'id': 'r3', 'rating': 5, 'createdAt': '2026-10-02T10:00:00Z'},
    ].take(pageSize).toList(),
    'pagination': {'page': 1, 'totalPages': 1},
  });
}

/// Auth calls the link screens make, answered locally.
class FakeAuthRepository extends AuthRepository {
  FakeAuthRepository() : super(_client(), academyId: 'ziadd');

  @override
  Future<bool> validateResetToken(String token) async => true;

  @override
  Future<void> verifyEmail(String token) async {}
}
