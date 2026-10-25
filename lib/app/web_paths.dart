/// Turns a learner link from the web (a notification's `actionUrl`, a push
/// message's `path`) into the app screen that shows the same thing.
///
/// Accepts relative paths and full URLs, with or without a language prefix
/// (`/ar/my/...`). Anything the app has no screen for opens the
/// notifications list rather than a dead end.
String appPathForWebLink(String? link) {
  if (link == null || link.trim().isEmpty) return '/notifications';
  var path = link.trim();
  final uri = Uri.tryParse(path);
  if (uri != null && uri.hasScheme) path = uri.path;
  path = path.split('?').first.split('#').first;
  final parts = path.split('/').where((p) => p.isNotEmpty).toList();
  if (parts.isNotEmpty && (parts.first == 'ar' || parts.first == 'en')) {
    parts.removeAt(0);
  }
  if (parts.isEmpty) return '/home';

  // /my/courses/:id[/activities/:item | /learn/:lesson | /complete]
  if (parts.length >= 3 && parts[0] == 'my' && parts[1] == 'courses') {
    final course = parts[2];
    if (parts.length >= 5 && parts[3] == 'activities') {
      return '/course/$course/item/${parts[4]}';
    }
    if (parts.length >= 5 && parts[3] == 'learn') {
      return '/course/$course/lesson/${parts[4]}';
    }
    return '/course/$course';
  }
  final key = parts.join('/');
  return switch (key) {
    'my/courses' || 'my-courses' || 'my/learning' => '/courses',
    'my/certificates' => '/account/certificates',
    'my/results' || 'my/assessments' => '/account/results',
    'my/devices' => '/account/devices',
    'my/profile' || 'my/security' => '/account/profile',
    'my/notifications' => '/notifications',
    'my' || 'my/overview' => '/home',
    _ => '/notifications',
  };
}
