import 'package:flutter/foundation.dart';

/// Where one academy's API lives.
///
/// The backend decides which academy a request is for from the request's
/// host, so every academy gets its own origin: its Atlas subdomain
/// (`https://ziadd.atlass.dpdns.org`) or its connected custom domain. The
/// session cookie is bound to that exact host (`__Host-` prefix), so each
/// academy also keeps its own session.
class AcademyEndpoint {
  AcademyEndpoint._(this.origin);

  /// Builds an endpoint from what a learner typed, scanned or tapped:
  /// `ziadd.atlass.dpdns.org`, `https://ziadd.atlass.dpdns.org/ar/courses`, …
  /// Throws [FormatException] when there is no usable host.
  factory AcademyEndpoint.parse(String input) {
    var text = input.trim();
    if (text.isEmpty) throw const FormatException('empty address');
    if (!text.contains('://')) text = 'https://$text';
    final uri = Uri.parse(text);
    if (uri.host.isEmpty) throw FormatException('no host in "$input"');
    // HTTPS only in release, so a scanned QR code or a pasted link cannot
    // point the app at a cleartext origin and downgrade the session. http is
    // allowed for loopback always, and for any host in debug/profile (the
    // local test stack).
    final schemeOk =
        uri.scheme == 'https' ||
        (uri.scheme == 'http' && _cleartextAllowed(uri.host));
    if (!schemeOk) {
      throw FormatException('insecure or unsupported scheme "${uri.scheme}"');
    }
    return AcademyEndpoint._(
      Uri(
        scheme: uri.scheme,
        host: uri.host.toLowerCase(),
        port: uri.hasPort ? uri.port : null,
      ),
    );
  }

  /// `scheme://host[:port]` with no path.
  final Uri origin;

  String get host => origin.host;

  /// Base for every API call: `<origin>/api/v1/`.
  String get apiBase => '$originHeader/api/v1/';

  /// The exact value the backend accepts in `Origin` for the two
  /// cookie-authenticated routes (`/auth/refresh`, `/auth/sign-out`): the
  /// serialised origin, lower case, default port omitted, no trailing slash.
  String get originHeader {
    final defaultPort =
        (origin.scheme == 'https' && origin.port == 443) ||
        (origin.scheme == 'http' && origin.port == 80);
    final port = origin.hasPort && !defaultPort ? ':${origin.port}' : '';
    return '${origin.scheme}://${origin.host}$port';
  }

  @override
  bool operator ==(Object other) =>
      other is AcademyEndpoint && other.originHeader == originHeader;

  @override
  int get hashCode => originHeader.hashCode;

  @override
  String toString() => originHeader;
}

/// http is acceptable only for a loopback literal, or anywhere in a
/// debug/profile build (the local test stack). Release is https-only.
bool _cleartextAllowed(String host) {
  const loopback = {'localhost', '127.0.0.1', '10.0.2.2'};
  return loopback.contains(host) || !kReleaseMode;
}
