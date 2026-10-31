import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/push.dart';
import '../../app/learning_providers.dart';
import '../../app/lesson_outbox.dart';
import '../../app/notes.dart';
import '../../core/clock.dart';
import '../quiz/assessment_widgets.dart' show AnswerField;
import '../../app/providers.dart';
import '../../app/ui_helpers.dart';
import '../../core/api/api_error.dart';
import '../../core/learning/learning_models.dart';
import '../../design/design.dart';
import '../courses/course_screen.dart';
import '../learning/course_widgets.dart';
import '../learning/learning_ui.dart';
import '../player/hosted_lesson_player.dart';
import '../player/playback_speed.dart';
import '../player/playback_session.dart';
import '../player/youtube_lesson_player.dart';

/// One lesson: video (YouTube with the watermark and playback lease), text,
/// file or link, its files, and "mark as done" → next.
class LessonScreen extends ConsumerStatefulWidget {
  const LessonScreen({
    super.key,
    required this.courseId,
    required this.lessonId,
  });
  final String courseId;
  final String lessonId;

  @override
  ConsumerState<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends ConsumerState<LessonScreen> {
  LessonGrant? _grant;
  PlaybackSession? _session;
  AtlasApiException? _error;
  bool _loading = true, _completing = false, _eligible = false;

  /// Set once the learner marks the lesson done (true) or takes it back
  /// (false); until then the course's own record says.
  bool? _done;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void dispose() {
    unawaited(_session?.release());
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final repo = ref.read(learningRepositoryProvider);
    try {
      final grant = await repo.grant(widget.courseId, widget.lessonId);
      if (!mounted) return;
      _session?.pause();
      _session =
          PlaybackSession.fromGrant(
              repo.client,
              grant.raw,
              onLeaseLost: (e) => mounted ? setState(() => _error = e) : null,
            )
            ?..onHeartbeat = (beat) {
              if (beat['completionEligible'] == true && !_eligible && mounted) {
                setState(() => _eligible = true);
              }
            };
      setState(() {
        _grant = grant;
        _eligible = grant.completionRule != 'watched_ratio';
        _loading = false;
      });
    } on AtlasApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
      if (e.messageKey == 'errors.learning.sessionConflict') {
        unawaited(_offerTakeover(e));
      }
    }
  }

  Future<void> _offerTakeover(AtlasApiException e) async {
    final l = context.l10n;
    final device =
        (e.details['deviceLabel'] as String?) ?? l.takeoverUnknownDevice;
    final ios = Theme.of(context).platform == TargetPlatform.iOS;
    final ok = await showAdaptiveDialog<bool>(
      context: context,
      builder: (c) => AlertDialog.adaptive(
        title: Text(l.takeoverTitle),
        content: Text(l.takeoverBody(device)),
        actions: [
          ios
              ? CupertinoDialogAction(
                  onPressed: () => Navigator.pop(c, false),
                  child: Text(l.commonCancel),
                )
              : TextButton(
                  onPressed: () => Navigator.pop(c, false),
                  child: Text(l.commonCancel),
                ),
          ios
              ? CupertinoDialogAction(
                  isDefaultAction: true,
                  onPressed: () => Navigator.pop(c, true),
                  child: Text(l.takeoverConfirm),
                )
              : TextButton(
                  onPressed: () => Navigator.pop(c, true),
                  child: Text(l.takeoverConfirm),
                ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await ref
          .read(learningRepositoryProvider)
          .takeover(courseId: widget.courseId, lessonId: widget.lessonId);
      await _load();
    } on AtlasApiException catch (err) {
      if (mounted) setState(() => _error = err);
    }
  }

  Future<void> _complete() async {
    setState(() => _completing = true);
    try {
      final result = await ref
          .read(lessonOutboxProvider.notifier)
          .complete(widget.courseId, widget.lessonId);
      ref.read(analyticsProvider).event('lesson_complete', {
        'queued': result == LessonOpResult.queued ? 1 : 0,
      });
      HapticFeedback.lightImpact();
      if (result == LessonOpResult.sent) refreshLearning(ref, widget.courseId);
      if (!mounted) return;
      setState(() => _done = true);
      if (result == LessonOpResult.queued) _say(context.l10n.lessonQueued);
    } on AtlasApiException catch (e) {
      if (mounted) _say(errorText(ref, context, e));
    } finally {
      if (mounted) setState(() => _completing = false);
    }
  }

  Future<void> _undo() async {
    setState(() => _completing = true);
    try {
      final result = await ref
          .read(lessonOutboxProvider.notifier)
          .undo(widget.courseId, widget.lessonId);
      ref.read(analyticsProvider).event('lesson_undo_complete', {
        'queued': result == LessonOpResult.queued ? 1 : 0,
      });
      if (result == LessonOpResult.sent) refreshLearning(ref, widget.courseId);
      if (!mounted) return;
      // What was watched still counts, so it can be marked done again.
      setState(() {
        _done = false;
        _eligible = true;
      });
      _say(
        result == LessonOpResult.queued
            ? context.l10n.lessonUndoQueued
            : context.l10n.lessonUndone,
      );
    } on AtlasApiException catch (e) {
      if (mounted) _say(errorText(ref, context, e));
    } finally {
      if (mounted) setState(() => _completing = false);
    }
  }

  LessonNote _note(LessonGrant g, CourseSequence? seq) =>
      ref.read(notesProvider.notifier).of(widget.lessonId) ??
      LessonNote(
        courseId: widget.courseId,
        lessonId: widget.lessonId,
        courseTitle: seq?.courseTitle ?? '',
        lessonTitle: g.title,
        updatedAt: clockNow(),
      );

  Future<void> _toggleSave(LessonGrant g, CourseSequence? seq) async {
    final n = _note(g, seq);
    HapticFeedback.selectionClick();
    await ref.read(notesProvider.notifier).put(n.copyWith(saved: !n.saved));
    ref.read(analyticsProvider).event('lesson_save', {'on': n.saved ? 0 : 1});
    if (mounted) {
      _say(
        n.saved
            ? context.l10n.lessonUnsavedToast
            : context.l10n.lessonSavedToast,
      );
    }
  }

  Future<void> _editNote(LessonGrant g, CourseSequence? seq) async {
    final n = _note(g, seq);
    final text = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => NoteSheet(initial: n.note),
    );
    if (text == null) return;
    await ref.read(notesProvider.notifier).put(n.copyWith(note: text.trim()));
    ref.read(analyticsProvider).event('lesson_note');
  }

  void _say(String text) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text)));

  void _open(String url) =>
      launchUrl(Uri.parse(url), mode: LaunchMode.inAppBrowserView);

  @override
  Widget build(BuildContext context) {
    final seq = ref.watch(sequenceProvider(widget.courseId)).value;
    final item = seq?.items.where((i) => i.id == widget.lessonId).firstOrNull;
    final g = _grant;
    final l = context.l10n;
    final mine = ref.watch(
      notesProvider.select(
        (n) => n.where((x) => x.lessonId == widget.lessonId).firstOrNull,
      ),
    );
    final saved = mine?.saved ?? false;
    final video = g?.youtubeId != null;
    final hosted = g?.youtubeId == null && g?.hostedVideoUrl != null;
    final speed = ref.watch(playbackSpeedProvider);
    final Widget body = _loading
        ? const Center(
            child: SizedBox.square(
              dimension: 26,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
          )
        : _error != null && g == null
        ? _ErrorView(error: _error!, onRetry: _load)
        : ListView(
            padding: const EdgeInsets.only(bottom: 48),
            children: [
              if (video)
                ReadableWidth(
                  child: YouTubeLessonPlayer(
                    videoId: g!.youtubeId!,
                    academyOrigin: ref
                        .read(sessionProvider)
                        .academy!
                        .endpoint
                        .originHeader,
                    watermarkCode: g.watermarkCode ?? '',
                    watermarkSecondary: g.watermarkIdentity,
                    session: _session,
                    startSeconds: g.resumeSeconds,
                    recordingMessage: context.l10n.playerRecording,
                    failedMessage: context.l10n.playerFailed,
                    onEnded: () => setState(() => _eligible = true),
                    speed: speed,
                  ),
                ),
              if (hosted)
                ReadableWidth(
                  child: HostedLessonPlayer(
                    url: g!.hostedVideoUrl!,
                    hls: g.hostedVideoHls,
                    posterUrl: g.hostedPosterUrl,
                    academyOrigin: ref
                        .read(sessionProvider)
                        .academy!
                        .endpoint
                        .originHeader,
                    watermarkCode: g.watermarkCode ?? '',
                    watermarkSecondary: g.watermarkIdentity,
                    session: _session,
                    startSeconds: g.resumeSeconds,
                    recordingMessage: context.l10n.playerRecording,
                    failedMessage: context.l10n.playerFailed,
                    onEnded: () => setState(() => _eligible = true),
                    speed: speed,
                  ),
                ),
              if (video || hosted)
                const Padding(
                  padding: EdgeInsets.fromLTRB(
                    AtlasSpace.gutter,
                    AtlasSpace.s4,
                    AtlasSpace.gutter,
                    0,
                  ),
                  child: ReadableWidth(
                    child: Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: SpeedButton(key: ValueKey('speed')),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AtlasSpace.gutter,
                  0,
                  AtlasSpace.gutter,
                  0,
                ),
                child: ReadableWidth(child: _content(context, g!, item, seq)),
              ),
            ],
          );
    // iPad: the course outline beside the lesson.
    final split = isSplit(context) && seq != null;
    return Scaffold(
      backgroundColor: context.atlas.colors.paper,
      appBar: AppBar(
        title: Text(
          split ? '' : seq?.courseTitle ?? '',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          if (g != null) ...[
            IconButton(
              key: const ValueKey('lesson-save'),
              tooltip: saved ? l.lessonUnsave : l.lessonSave,
              isSelected: saved,
              onPressed: () => _toggleSave(g, seq),
              icon: Icon(
                saved ? LucideIcons.bookmarkCheck : LucideIcons.bookmarkPlus,
                color: saved ? context.atlas.colors.accent : null,
              ),
            ),
            IconButton(
              key: const ValueKey('lesson-note'),
              tooltip: l.lessonNoteAdd,
              onPressed: () => _editNote(g, seq),
              icon: const Icon(LucideIcons.notebookPen),
            ),
          ],
        ],
      ),
      body: split
          ? SplitView(
              master: CourseOutline(s: seq, openId: widget.lessonId),
              detail: body,
            )
          : body,
    );
  }

  Widget _content(
    BuildContext context,
    LessonGrant g,
    SequenceItem? item,
    CourseSequence? seq,
  ) {
    final l = context.l10n;
    final a = context.atlas;
    final c = a.colors;
    final next = seq?.after(widget.lessonId);
    // A choice still waiting for a connection counts over the server's.
    final queued = ref.watch(
      lessonOutboxProvider.select(
        (q) => q.where((o) => o.lessonId == widget.lessonId).lastOrNull,
      ),
    );
    final alreadyDone = queued?.complete ?? item?.isDone ?? false;
    final done = _done ?? alreadyDone;
    final pending = done && queued?.complete == true;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Where this lesson sits in the course, at a glance.
        // (On iPad the outline beside the lesson already shows it.)
        if (seq != null && seq.items.isNotEmpty && !isSplit(context)) ...[
          const SizedBox(height: AtlasSpace.s12),
          SegmentedProgress(
            segments: segmentsFor(seq),
            height: 4,
            semanticLabel: l.countOf(
              context.digits('${seq.completedCount}'),
              context.digits('${seq.totalCount}'),
            ),
          ),
          const SizedBox(height: AtlasSpace.s8),
        ],
        // Header: the bookmark marks where the learner is.
        Entrance(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Padding(
                padding: const EdgeInsetsDirectional.only(start: 34, top: 20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      context.digits('${(item?.position ?? 0) + 1}'),
                      style: a.type.numeral.copyWith(color: c.ink),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        item == null || item.sectionTitle.isEmpty
                            ? l.unitLesson
                            : '${l.unitLesson}${context.sep}'
                                  '${item.sectionTitle}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: a.type.footnote.copyWith(color: c.inkSecondary),
                      ),
                    ),
                  ],
                ),
              ),
              if (!done)
                const PositionedDirectional(
                  start: 0,
                  top: 0,
                  child: Bookmark(),
                ),
            ],
          ),
        ),
        const SizedBox(height: AtlasSpace.s8),
        Entrance(
          order: 1,
          child: Semantics(
            header: true,
            child: Text(
              g.title,
              textDirection: contentDirection(context, g.title),
              style: a.type.title1.copyWith(color: c.ink),
            ),
          ),
        ),
        const SizedBox(height: AtlasSpace.s20),
        if (_error != null) ...[
          AtlasBanner(
            kind: AtlasBannerKind.error,
            message: errorText(ref, context, _error!),
          ),
          const SizedBox(height: AtlasSpace.s16),
        ],
        Entrance(
          order: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: _body(context, g),
          ),
        ),
        if (ref.watch(
              notesProvider.select(
                (n) => n
                    .where((x) => x.lessonId == widget.lessonId)
                    .firstOrNull
                    ?.note,
              ),
            )
            case final note? when note.trim().isNotEmpty) ...[
          const SizedBox(height: AtlasSpace.s20),
          _NoteCard(note: note, onEdit: () => _editNote(g, seq)),
        ],
        if (g.resources.isNotEmpty) ...[
          SectionHeader(title: l.lessonResources),
          SettingsGroup(
            children: [
              for (final r in g.resources)
                SettingsRow(
                  title: r.title,
                  icon: LucideIcons.paperclip,
                  onTap: r.url == null ? null : () => _open(r.url!),
                ),
            ],
          ),
        ],
        const SizedBox(height: AtlasSpace.s32),
        if (!done) ...[
          AtlasButton(
            label: l.lessonMarkDone,
            icon: LucideIcons.check,
            loading: _completing,
            onPressed: _eligible && !_completing ? _complete : null,
          ),
          if (!_eligible && g.minimumWatchedRatio != null) ...[
            const SizedBox(height: AtlasSpace.s8),
            Text(
              l.lessonWatchFirst(
                context.digits('${(g.minimumWatchedRatio! * 100).round()}'),
              ),
              textAlign: TextAlign.center,
              style: a.type.footnote.copyWith(color: c.inkSecondary),
            ),
          ],
        ] else ...[
          AtlasBanner(
            kind: pending ? AtlasBannerKind.info : AtlasBannerKind.success,
            message: pending ? l.lessonPending : l.lessonDone,
          ),
          const SizedBox(height: AtlasSpace.s16),
          if (next != null && next.type != 'live_session')
            AtlasButton(
              label: l.lessonNext(next.title),
              onPressed: () =>
                  openItem(context, ref, seq!, next, replace: true),
            )
          else
            AtlasButton(
              label: l.lessonBackToCourse,
              style: AtlasButtonStyle.tonal,
              onPressed: () => context.pop(),
            ),
          const SizedBox(height: AtlasSpace.s8),
          AtlasButton(
            key: const ValueKey('lesson-undo'),
            label: l.lessonUndo,
            icon: LucideIcons.undo2,
            style: AtlasButtonStyle.plain,
            loading: _completing,
            onPressed: _completing ? null : _undo,
          ),
        ],
      ],
    );
  }

  List<Widget> _body(BuildContext context, LessonGrant g) {
    final l = context.l10n;
    final a = context.atlas;
    switch (g.kind) {
      case 'text':
        return [
          HtmlWidget(
            g.bodyHtml ?? '',
            textStyle: a.type.body.copyWith(color: a.colors.ink),
            onTapUrl: (url) {
              _open(url);
              return true;
            },
          ),
        ];
      case 'file':
        return [
          AtlasButton(
            label: g.fileName ?? l.lessonOpenFile,
            icon: LucideIcons.fileText,
            style: AtlasButtonStyle.tonal,
            onPressed: g.fileUrl == null ? null : () => _open(g.fileUrl!),
          ),
        ];
      case 'video' when g.youtubeId == null && g.hostedVideoUrl == null:
        // Hosted video tiers are not switched on yet; the web plays them.
        final host = ref.read(sessionProvider).academy!.host;
        return [
          AtlasBanner(message: l.lessonVideoOnWeb),
          const SizedBox(height: AtlasSpace.s12),
          AtlasButton(
            label: l.lessonOpenWebsite,
            style: AtlasButtonStyle.tonal,
            onPressed: () => _open(
              'https://$host/my/courses/${g.courseId}/learn/${g.lessonId}',
            ),
          ),
        ];
      case 'external' when g.youtubeId == null:
        return [
          AtlasButton(
            label: l.lessonOpenLink,
            icon: LucideIcons.externalLink,
            style: AtlasButtonStyle.tonal,
            onPressed: g.externalUrl == null
                ? null
                : () => _open(g.externalUrl!),
          ),
        ];
      default:
        return const [];
    }
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error, required this.onRetry});
  final AtlasApiException error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final deviceLimit = error.messageKey == 'errors.learning.deviceLimit';
    return Consumer(
      builder: (context, ref, _) => Padding(
        padding: const EdgeInsets.all(AtlasSpace.gutter),
        child: ReadableWidth(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AtlasBanner(
                kind: AtlasBannerKind.error,
                message: deviceLimit
                    ? '${l.deviceLimitTitle}. ${l.deviceLimitBody}'
                    : errorText(ref, context, error),
              ),
              const SizedBox(height: AtlasSpace.s16),
              if (deviceLimit)
                AtlasButton(
                  label: l.deviceLimitManage,
                  onPressed: () => context.push('/account/devices'),
                )
              else
                AtlasButton(
                  label: l.commonRetry,
                  style: AtlasButtonStyle.tonal,
                  onPressed: onRetry,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The learner's note on this lesson, inside the lesson.
class _NoteCard extends StatelessWidget {
  const _NoteCard({required this.note, required this.onEdit});
  final String note;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final a = context.atlas;
    final c = a.colors;
    return Container(
      key: const ValueKey('lesson-note-card'),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      decoration: BoxDecoration(
        color: c.tonal,
        borderRadius: BorderRadius.circular(AtlasRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(LucideIcons.notebookPen, size: 18, color: c.accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l.lessonNoteTitle,
                  style: a.type.headline.copyWith(color: c.ink),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            note,
            textDirection: contentDirection(context, note),
            style: a.type.body.copyWith(color: c.ink),
          ),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton(onPressed: onEdit, child: Text(l.lessonNoteEdit)),
          ),
        ],
      ),
    );
  }
}

/// Writing the note: the text, Save, and Delete when there is one. Pops
/// the new text ('' to delete), or null when dismissed.
class NoteSheet extends StatefulWidget {
  const NoteSheet({super.key, required this.initial});
  final String initial;

  @override
  State<NoteSheet> createState() => _NoteSheetState();
}

class _NoteSheetState extends State<NoteSheet> {
  late final _text = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final a = context.atlas;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AtlasSpace.gutter,
        0,
        AtlasSpace.gutter,
        MediaQuery.viewInsetsOf(context).bottom + AtlasSpace.s20,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l.lessonNoteTitle,
              style: a.type.title3.copyWith(color: a.colors.ink),
            ),
            const SizedBox(height: 12),
            AnswerField(
              controller: _text,
              label: l.lessonNoteHint,
              hint: '',
              helper: l.notesOnPhone,
              minLines: 4,
              maxLines: 10,
            ),
            const SizedBox(height: 12),
            AtlasButton(
              label: l.lessonNoteSave,
              onPressed: () => Navigator.pop(context, _text.text),
            ),
            if (widget.initial.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              AtlasButton(
                label: l.lessonNoteDelete,
                style: AtlasButtonStyle.plain,
                onPressed: () => Navigator.pop(context, ''),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
