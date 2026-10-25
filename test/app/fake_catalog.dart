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

/// Auth calls the link screens make, answered locally.
class FakeAuthRepository extends AuthRepository {
  FakeAuthRepository() : super(_client(), academyId: 'ziadd');

  @override
  Future<bool> validateResetToken(String token) async => true;

  @override
  Future<void> verifyEmail(String token) async {}
}
