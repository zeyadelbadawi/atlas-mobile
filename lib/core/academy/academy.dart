import '../api/academy_endpoint.dart';

/// An academy the learner picked, as `GET /public/websites/resolve` describes
/// it. Stored locally for "recent academies".
class Academy {
  const Academy({
    required this.id,
    required this.name,
    required this.host,
    this.slug,
    this.primaryColor,
  });

  factory Academy.fromResolve(
    Map<String, dynamic> json, {
    required String fallbackHost,
  }) {
    final brand = (json['presentation'] as Map?)?['brand'] as Map?;
    return Academy(
      id: json['academyId'] as String,
      name: (json['academyName'] as String?)?.trim().isNotEmpty == true
          ? json['academyName'] as String
          : fallbackHost,
      host: (json['canonicalHost'] as String?) ?? fallbackHost,
      slug: json['academySlug'] as String?,
      primaryColor: brand?['primaryColor'] as String?,
    );
  }

  factory Academy.fromJson(Map<String, dynamic> json) => Academy(
    id: json['id'] as String,
    name: json['name'] as String,
    host: json['host'] as String,
    slug: json['slug'] as String?,
    primaryColor: json['primaryColor'] as String?,
  );

  final String id;
  final String name;
  final String host;
  final String? slug;

  /// HSL string from the web identity, e.g. "40 95% 54%".
  final String? primaryColor;

  AcademyEndpoint get endpoint => AcademyEndpoint.parse(host);

  Uri get logoUrl => Uri.parse('${endpoint.apiBase}public/websites/$id/logo');

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'host': host,
    'slug': slug,
    'primaryColor': primaryColor,
  };

  @override
  bool operator ==(Object other) =>
      other is Academy && other.id == id && other.host == host;

  @override
  int get hashCode => Object.hash(id, host);
}
