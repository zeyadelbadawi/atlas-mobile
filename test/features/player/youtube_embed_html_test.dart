import 'package:atlas_mobile/features/player/youtube_embed_html.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const origin = 'https://ziadd.atlass.dpdns.org';

  test(
    'embeds on youtube-nocookie with fs=0, playsinline and the academy origin',
    () {
      final html = youtubeEmbedHtml(
        videoId: 'dQw4w9WgXcQ',
        origin: origin,
        startSeconds: 42,
      );
      expect(html, contains('"host":"https://www.youtube-nocookie.com"'));
      expect(html, contains('"fs":0'));
      expect(html, contains('"playsinline":1'));
      expect(html, contains('"origin":"$origin"'));
      expect(html, contains('"start":42'));
    },
  );

  test('refuses anything that is not an 11-character video id', () {
    expect(
      () => youtubeEmbedHtml(videoId: 'x"</script>', origin: origin),
      throwsArgumentError,
    );
  });

  test(
    'navigation stays on the embed; YouTube pages and other sites are refused',
    () {
      bool ok(String url) =>
          isAllowedPlayerNavigation(Uri.parse(url), academyOrigin: origin);
      expect(ok('about:blank'), isTrue);
      expect(ok('$origin/'), isTrue);
      expect(ok('https://www.youtube.com/iframe_api'), isTrue);
      expect(ok('https://www.youtube-nocookie.com/embed/dQw4w9WgXcQ'), isTrue);
      expect(ok('https://www.youtube.com/watch?v=dQw4w9WgXcQ'), isFalse);
      expect(ok('https://youtu.be/dQw4w9WgXcQ'), isFalse);
      expect(ok('https://evil.example/'), isFalse);
    },
  );
}
