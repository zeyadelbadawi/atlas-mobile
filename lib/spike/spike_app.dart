// PHASE 0 TEST HARNESS — throwaway. Exists only to try the session model,
// the YouTube player, the watermark and capture protection on real phones.
// Replaced by the real app (design system, l10n, routing) in phase 2.
import 'dart:io' show Platform;

import 'package:cookie_jar/cookie_jar.dart';
import 'package:flutter/material.dart';

import '../core/api/academy_endpoint.dart';
import '../core/api/api_error.dart';
import '../core/api/atlas_api_client.dart';
import '../core/api/secure_cookie_storage.dart';
import '../core/auth/auth_repository.dart';
import '../features/player/playback_session.dart';
import '../features/player/youtube_lesson_player.dart';

String _userAgent() {
  final os = Platform.isIOS
      ? 'iPhone; iOS ${Platform.operatingSystemVersion}'
      : 'Android';
  return 'AtlasApp/0.1-spike ($os)';
}

final _jar = PersistCookieJar(storage: SecureCookieStorage());

class SpikeApp extends StatelessWidget {
  const SpikeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Atlas spike',
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF1F5FBF),
        useMaterial3: true,
      ),
      home: const _SignInPage(),
    );
  }
}

class _Session {
  _Session(this.client, this.academyId);
  final AtlasApiClient client;
  final String academyId;
}

class _SignInPage extends StatefulWidget {
  const _SignInPage();
  @override
  State<_SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<_SignInPage> {
  final _address = TextEditingController(text: 'ziadd.atlass.dpdns.org');
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _code = TextEditingController();
  EmailCodeRequired? _challenge;
  AuthRepository? _auth;
  String? _status;
  bool _busy = false;

  Future<void> _run(Future<void> Function() body) async {
    setState(() {
      _busy = true;
      _status = null;
    });
    try {
      await body();
    } on AtlasApiException catch (e) {
      setState(() => _status = '${e.status ?? ''} ${e.messageKey}');
    } on FormatException catch (e) {
      setState(() => _status = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<AuthRepository> _repo() async {
    final endpoint = AcademyEndpoint.parse(_address.text);
    final client = AtlasApiClient(
      endpoint: endpoint,
      cookieJar: _jar,
      userAgent: _userAgent(),
    );
    final resolved = await client.get<Map<String, dynamic>>(
      'public/websites/resolve',
      query: {'hostname': endpoint.host},
    );
    return AuthRepository(client, academyId: resolved['academyId'] as String);
  }

  Future<void> _restore() => _run(() async {
    final auth = await _repo();
    final user = await auth.restore();
    _open(auth, user);
  });

  Future<void> _signIn() => _run(() async {
    final auth = _auth = await _repo();
    final outcome = await auth.signIn(
      email: _email.text.trim(),
      password: _password.text,
    );
    switch (outcome) {
      case SignedIn(:final user):
        _open(auth, user);
      case EmailCodeRequired():
        setState(() => _challenge = outcome);
      case AuthenticatorCodeRequired():
        setState(
          () => _status = 'Authenticator code required (not in the spike)',
        );
    }
  });

  Future<void> _verify() => _run(() async {
    final outcome = await _auth!.verifyEmailCode(
      challengeId: _challenge!.challengeId,
      code: _code.text.trim(),
      rememberDevice: true,
    );
    if (outcome is SignedIn) _open(_auth!, outcome.user);
  });

  void _open(AuthRepository auth, Map<String, dynamic>? user) {
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _CoursesPage(
          session: _Session(auth.client, auth.academyId),
          name: '${user?['name'] ?? ''}',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Atlas spike')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _address,
            decoration: const InputDecoration(labelText: 'Academy address'),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: _busy ? null : _restore,
            child: const Text('Restore saved session'),
          ),
          const Divider(height: 32),
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'Email'),
          ),
          TextField(
            controller: _password,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Password'),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _busy ? null : _signIn,
            child: const Text('Sign in'),
          ),
          if (_challenge != null) ...[
            const SizedBox(height: 16),
            Text('Code sent to ${_challenge!.maskedEmail}'),
            TextField(
              controller: _code,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Code'),
            ),
            FilledButton(
              onPressed: _busy ? null : _verify,
              child: const Text('Verify'),
            ),
          ],
          if (_status != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(_status!),
            ),
        ],
      ),
    );
  }
}

class _CoursesPage extends StatelessWidget {
  const _CoursesPage({required this.session, required this.name});
  final _Session session;
  final String name;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Hi $name'),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await session.client.signOut();
              if (context.mounted) Navigator.of(context).pop();
            },
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: session.client.get<Map<String, dynamic>>('enrollments'),
        builder: (context, snap) {
          if (snap.hasError) return Center(child: Text('${snap.error}'));
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = (snap.data!['items'] as List)
              .cast<Map<String, dynamic>>();
          if (items.isEmpty) return const Center(child: Text('No enrolments'));
          return ListView(
            children: [
              for (final e in items)
                ListTile(
                  title: Text('${(e['course'] as Map)['title']}'),
                  subtitle: Text(
                    '${(e['progress'] as Map?)?['percentage'] ?? 0}%',
                  ),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => _SequencePage(
                        session: session,
                        courseId: e['courseId'] as String,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _SequencePage extends StatelessWidget {
  const _SequencePage({required this.session, required this.courseId});
  final _Session session;
  final String courseId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Course')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: session.client.get<Map<String, dynamic>>(
          'learning/courses/$courseId/sequence',
        ),
        builder: (context, snap) {
          if (snap.hasError) return Center(child: Text('${snap.error}'));
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = (snap.data!['items'] as List)
              .cast<Map<String, dynamic>>();
          return ListView(
            children: [
              for (final item in items)
                ListTile(
                  title: Text('${item['title']}'),
                  subtitle: Text(
                    '${item['type']} · ${item['state']}${item['lockReason'] != null ? ' (${item['lockReason']})' : ''}',
                  ),
                  enabled:
                      item['type'] == 'lesson' && item['state'] != 'locked',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => _LessonPage(
                        session: session,
                        courseId: courseId,
                        lessonId: item['id'] as String,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _LessonPage extends StatefulWidget {
  const _LessonPage({
    required this.session,
    required this.courseId,
    required this.lessonId,
  });
  final _Session session;
  final String courseId;
  final String lessonId;
  @override
  State<_LessonPage> createState() => _LessonPageState();
}

class _LessonPageState extends State<_LessonPage> {
  late final Future<Map<String, dynamic>>
  _grant = widget.session.client.get<Map<String, dynamic>>(
    'learning/courses/${widget.courseId}/lessons/${widget.lessonId}/content',
  );
  String? _note;

  Future<void> _complete() async {
    try {
      await widget.session.client.post<dynamic>(
        'courses/${widget.courseId}/progress/complete-lesson',
        data: {'lessonId': widget.lessonId},
      );
      setState(() => _note = 'Marked complete');
    } on AtlasApiException catch (e) {
      setState(() => _note = e.messageKey);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lesson')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _grant,
        builder: (context, snap) {
          if (snap.hasError) return Center(child: Text('${snap.error}'));
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final grant = snap.data!;
          final embed = grant['externalEmbed'] as Map?;
          final watermark = grant['watermark'] as Map?;
          return ListView(
            children: [
              if (embed?['provider'] == 'youtube' &&
                  watermark?['code'] is String)
                YouTubeLessonPlayer(
                  videoId: embed!['videoId'] as String,
                  academyOrigin: widget.session.client.endpoint.originHeader,
                  watermarkCode: watermark!['code'] as String,
                  watermarkSecondary: watermark['maskedIdentity'] as String?,
                  startSeconds:
                      (grant['resumePositionSeconds'] as num?)?.toInt() ?? 0,
                  session: PlaybackSession.fromGrant(
                    widget.session.client,
                    grant,
                    onLeaseLost: (e) {
                      if (mounted) {
                        setState(() => _note = 'Lease lost: ${e.messageKey}');
                      }
                    },
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'kind: ${grant['kind']}\n\n${grant['html'] ?? grant['body'] ?? ''}',
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${grant['title']}',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    FilledButton(
                      onPressed: _complete,
                      child: const Text('Mark complete'),
                    ),
                    if (_note != null) Text(_note!),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
