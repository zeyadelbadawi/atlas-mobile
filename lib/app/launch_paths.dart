/// An in-app path that arrived from outside the app — a home-screen widget
/// tap or an app-icon shortcut — is navigated to only when it is one the
/// app itself emits. Both arrive through a custom URL scheme
/// (`atlaswidget://open?path=…`) that other apps on the phone can invoke,
/// so an unchecked `router.go(path)` would let any app push this app to an
/// arbitrary screen (CWE-939, unvalidated scheme navigation).
///
/// Returns the path when it is on the allowlist, or null to ignore it.
library;

/// Static destinations the widget and the icon shortcuts use.
const _exact = {
  '/home',
  '/courses',
  '/tasks',
  '/notifications',
  '/account/notes',
};

/// Course ids and the lesson/item ids under them: letters, digits and a few
/// url-safe marks, nothing that could be a traversal or a second path.
final _segment = RegExp(r'^[A-Za-z0-9._~-]+$');

/// The one dynamic shape the widget emits: `/course/<id>[/<sub>…]`.
bool _isCoursePath(List<String> parts) =>
    parts.length >= 2 &&
    parts.first == 'course' &&
    parts.every((p) => _segment.hasMatch(p));

/// The path to navigate to, or null when it is not one the app emits.
String? safeLaunchPath(String? path) {
  if (path == null) return null;
  final trimmed = path.trim();
  // A real path only: no scheme, host, query or fragment smuggled in.
  if (!trimmed.startsWith('/') || trimmed.startsWith('//')) return null;
  if (trimmed.contains(RegExp(r'[?#\\]')) || trimmed.contains('..')) {
    return null;
  }
  if (_exact.contains(trimmed)) return trimmed;
  final parts = trimmed.split('/').where((p) => p.isNotEmpty).toList();
  if (parts.length != trimmed.split('/').length - 1) return null; // empty seg
  return _isCoursePath(parts) ? trimmed : null;
}
