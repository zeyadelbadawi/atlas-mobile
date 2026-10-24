import 'dart:convert';

/// The page the lesson WebView loads for a YouTube lesson.
///
/// * Loaded with the ACADEMY's origin as its base URL, so YouTube sees the
///   academy as the embedding site (same as the website) and the IFrame API
///   `origin` matches.
/// * `youtube-nocookie.com` (privacy-enhanced), like the website.
/// * `fs=0`: YouTube's own fullscreen would show the video outside the
///   watermark; the app's fullscreen keeps the overlay on top.
/// * `playsinline=1`: iOS would otherwise jump to its native player, again
///   outside the watermark.
/// * Events go to the app through the `Atlas` JavaScript channel.
String youtubeEmbedHtml({
  required String videoId,
  required String origin,
  int startSeconds = 0,
}) {
  if (!RegExp(r'^[A-Za-z0-9_-]{11}$').hasMatch(videoId)) {
    throw ArgumentError.value(videoId, 'videoId', 'not a YouTube video id');
  }
  final config = jsonEncode({
    'videoId': videoId,
    'host': 'https://www.youtube-nocookie.com',
    'playerVars': {
      'rel': 0,
      'modestbranding': 1,
      'playsinline': 1,
      'fs': 0,
      'enablejsapi': 1,
      'origin': origin,
      if (startSeconds > 0) 'start': startSeconds,
    },
  });
  return '''
<!doctype html>
<html>
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1,maximum-scale=1,user-scalable=no">
<style>html,body{margin:0;height:100%;background:#000;overflow:hidden}#p{position:absolute;inset:0;width:100%;height:100%}</style>
</head>
<body>
<div id="p"></div>
<script>
  var player;
  function send(m){ try { Atlas.postMessage(JSON.stringify(m)); } catch (e) {} }
  function onYouTubeIframeAPIReady(){
    var c = $config;
    c.events = {
      onReady: function(){ send({t:'ready'}); },
      onStateChange: function(e){ send({t:'state', s:e.data}); },
      onError: function(e){ send({t:'error', c:e.data}); }
    };
    player = new YT.Player('p', c);
    setInterval(function(){
      if (player && player.getCurrentTime) send({t:'time', v:player.getCurrentTime()});
    }, 5000);
  }
  function atlasPause(){ if (player && player.pauseVideo) player.pauseVideo(); }
  function atlasPlay(){ if (player && player.playVideo) player.playVideo(); }
</script>
<script src="https://www.youtube.com/iframe_api"></script>
</body>
</html>
''';
}

/// Hosts the lesson WebView may load. Everything else (the YouTube logo,
/// "Watch on YouTube", channel links) is refused, so the lesson cannot be
/// opened outside the watermark from inside the app.
bool isAllowedPlayerNavigation(Uri uri, {required String academyOrigin}) {
  if (uri.scheme == 'about' || uri.scheme == 'data') return true;
  if (uri.toString().startsWith(academyOrigin)) return true;
  const hosts = {
    'www.youtube-nocookie.com',
    'www.youtube.com',
    's.ytimg.com',
    'i.ytimg.com',
    'yt3.ggpht.com',
  };
  if (!hosts.contains(uri.host)) return false;
  // www.youtube.com only for the IFrame API script and embeds.
  if (uri.host == 'www.youtube.com') {
    return uri.path.startsWith('/iframe_api') ||
        uri.path.startsWith('/s/player') ||
        uri.path.startsWith('/embed/');
  }
  return true;
}
