import '../api/atlas_api_client.dart';

List<Map<String, dynamic>> _maps(Object? v) => v is List
    ? v.whereType<Map>().map((m) => Map<String, dynamic>.from(m)).toList()
    : const [];

int _int(Object? v) => v is num ? v.toInt() : 0;

/// A published, public course as the academy's own website shows it
/// (`GET public/websites/:academyId/courses[/:id]`).
class CatalogCourse {
  CatalogCourse.fromJson(Map<String, dynamic> j)
    : id = j['id'] as String,
      slug = j['slug'] as String? ?? '',
      title = j['title'] as String? ?? '',
      shortDescription = (j['shortDescription'] as String?)?.trim(),
      description = (j['description'] as String?)?.trim(),
      thumbnailUrl = j['thumbnail'] as String?,
      isFree = (j['pricing'] as Map?)?['type'] != 'paid',
      instructors = _maps(j['instructors'])
          .map((i) => i['name'] as String? ?? '')
          .where((n) => n.isNotEmpty)
          .toList(),
      level = j['level'] as String?,
      language = j['language'] as String?,
      outcomes = (j['outcomes'] as List?)?.whereType<String>().toList() ?? [],
      requirements =
          (j['requirements'] as List?)?.whereType<String>().toList() ?? [],
      certificatesEnabled = j['certificatesEnabled'] == true,
      totalSections = _int((j['stats'] as Map?)?['totalSections']),
      totalLessons = _int((j['stats'] as Map?)?['totalLessons']),
      totalQuizzes = _int((j['stats'] as Map?)?['totalQuizzes']),
      totalAssignments = _int((j['stats'] as Map?)?['totalAssignments']),
      durationSeconds = ((j['stats'] as Map?)?['durationSeconds'] as num?)
          ?.toInt();

  final String id;
  final String slug;
  final String title;
  final String? shortDescription;
  final String? description;
  final String? thumbnailUrl;
  final bool isFree;
  final List<String> instructors;

  /// beginner | intermediate | advanced | all_levels
  final String? level;
  final String? language;
  final List<String> outcomes;
  final List<String> requirements;
  final bool certificatesEnabled;
  final int totalSections;
  final int totalLessons;
  final int totalQuizzes;
  final int totalAssignments;

  /// Null when no lesson declares a length.
  final int? durationSeconds;
}

class CatalogPage {
  CatalogPage.fromJson(Map<String, dynamic> j)
    : items = _maps(j['items']).map(CatalogCourse.fromJson).toList(),
      hasMore = _hasMore(j);

  final List<CatalogCourse> items;
  final bool hasMore;

  static bool _hasMore(Map<String, dynamic> j) {
    final meta = j['pagination'] is Map ? j['pagination'] as Map : j;
    final page = _int(meta['page']);
    final totalPages = _int(meta['totalPages']);
    return totalPages > 0 && page < totalPages;
  }
}

class CurriculumLesson {
  CurriculumLesson.fromJson(Map<String, dynamic> j)
    : title = j['title'] as String? ?? '',
      contentType = j['contentType'] as String? ?? 'video';

  final String title;
  final String contentType;
}

class CurriculumSection {
  CurriculumSection.fromJson(Map<String, dynamic> j)
    : title = j['title'] as String? ?? '',
      lessons = _maps(j['lessons']).map(CurriculumLesson.fromJson).toList();

  final String title;
  final List<CurriculumLesson> lessons;
}

/// The academy's free courses and joining one. Only free courses are
/// listed: the app sells nothing, and a paid course is bought on the web.
class CatalogRepository {
  CatalogRepository(this.client, this.academyId);

  final AtlasApiClient client;
  final String academyId;

  Future<CatalogPage> freeCourses({int page = 1, String? search}) async =>
      CatalogPage.fromJson(
        await client.get<Map<String, dynamic>>(
          'public/websites/$academyId/courses',
          query: {
            'pricingType': 'free',
            'page': page,
            'pageSize': 20,
            if (search != null && search.trim().isNotEmpty)
              'search': search.trim(),
          },
        ),
      );

  /// By id or slug (the website's `/courses/:idOrSlug`).
  Future<CatalogCourse> course(String idOrSlug) async => CatalogCourse.fromJson(
    await client.get<Map<String, dynamic>>(
      'public/websites/$academyId/courses/$idOrSlug',
    ),
  );

  Future<List<CurriculumSection>> curriculum(String courseId) async {
    final body = await client.get<List<dynamic>>(
      'public/websites/$academyId/courses/$courseId/curriculum',
    );
    return _maps(body).map(CurriculumSection.fromJson).toList();
  }

  /// Whether the learner already holds an enrollment for this course
  /// (`null` body when not).
  Future<bool> isEnrolled(String courseId) async {
    final body = await client.get<dynamic>('enrollments/by-course/$courseId');
    return body is Map && body['id'] is String;
  }

  /// Free self-enrollment. Idempotent on the server: joining twice returns
  /// the same enrollment.
  Future<void> enroll(String courseId) =>
      client.post<dynamic>('enrollments', data: {'courseId': courseId});
}
