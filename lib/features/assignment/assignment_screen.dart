import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/push.dart';
import '../../app/learning_providers.dart';
import '../../app/ui_helpers.dart';
import '../../core/api/api_error.dart';
import '../../core/learning/assessment_models.dart';
import '../../core/learning/assessment_repository.dart';
import '../../design/design.dart';
import '../quiz/assessment_widgets.dart';
import '../quiz/quiz_engine.dart' show autosaveDebounce;
import '../quiz/quiz_screen.dart' show dateTimeText;

/// An assignment: the facts first (due date, what happens when late,
/// whether resubmitting is allowed), then the draft. The draft autosaves,
/// so leaving loses nothing; Submit is the one deliberate action. After
/// submitting, the same screen shows the timeline (Submitted → Being
/// graded → Graded), what was sent, and the grade and feedback.
///
/// Draft saves are compare-and-set: a draft changed on another device
/// meanwhile is shown as a choice, never overwritten. A submit carries one
/// idempotency key per submitted content, so a retry never submits twice.
class AssignmentScreen extends ConsumerStatefulWidget {
  const AssignmentScreen({
    super.key,
    required this.courseId,
    required this.assignmentId,
  });
  final String courseId;
  final String assignmentId;

  @override
  ConsumerState<AssignmentScreen> createState() => _AssignmentScreenState();
}

enum _Draft { idle, dirty, saving, saved, failed, conflict }

class _AssignmentScreenState extends ConsumerState<AssignmentScreen> {
  Assignment? _assignment;
  AssignmentSubmission? _submission;
  Object? _loadError;
  bool _loading = true;

  final _response = TextEditingController();
  SubmissionAttachment? _attachment;
  _Draft _draft = _Draft.idle;
  String? _base;
  ({String response, String? savedAt})? _conflict;
  Timer? _debounce;
  bool _editing = false, _uploading = false, _submitting = false;
  String? _attachmentError, _submitError;
  ({String key, String payload})? _pendingSubmit;

  late final AssessmentRepository _repo;

  @override
  void initState() {
    super.initState();
    _repo = ref.read(assessmentRepositoryProvider);
    unawaited(_load());
  }

  @override
  void dispose() {
    if (_debounce?.isActive ?? false) {
      _debounce!.cancel();
      unawaited(_saveDraft());
    }
    _response.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    final repo = _repo;
    try {
      final both = await Future.wait<Object?>([
        repo.assignment(widget.courseId, widget.assignmentId),
        repo.submission(widget.courseId, widget.assignmentId),
      ]);
      if (!mounted) return;
      setState(() {
        _assignment = both[0] as Assignment;
        _seed(both[1] as AssignmentSubmission?);
        _loading = false;
      });
    } on Object catch (e) {
      if (mounted) {
        setState(() {
          _loadError = e;
          _loading = false;
        });
      }
    }
  }

  void _seed(AssignmentSubmission? s) {
    _submission = s;
    final submitted = s?.isSubmitted ?? false;
    _response.text = s?.draftResponse ?? (submitted ? '' : s?.response ?? '');
    _attachment = submitted ? null : s?.attachment;
    _base = s?.draftSavedAt;
    _draft = s?.draftResponse != null ? _Draft.saved : _Draft.idle;
  }

  /* ---------- draft ---------- */

  void _changed() {
    setState(() => _draft = _Draft.dirty);
    _debounce?.cancel();
    _debounce = Timer(autosaveDebounce, _saveDraft);
  }

  Future<void> _saveDraft() async {
    if (_conflict != null) return;
    if (mounted) setState(() => _draft = _Draft.saving);
    try {
      final saved = await _repo.saveDraft(
        widget.courseId,
        widget.assignmentId,
        response: _response.text,
        attachmentAssetId: _attachment?.assetId,
        baseDraftSavedAt: _base,
      );
      _base = saved.draftSavedAt;
      if (mounted) setState(() => _draft = _Draft.saved);
    } on AtlasApiException catch (e) {
      if (!mounted) return;
      if (e.messageKey == 'errors.assignment.draftConflict') {
        setState(() {
          _conflict = (
            response: e.details['draftResponse'] as String? ?? '',
            savedAt: e.details['draftSavedAt'] as String?,
          );
          _draft = _Draft.conflict;
        });
        return;
      }
      setState(() => _draft = _Draft.failed);
    }
  }

  void _keepMine() {
    _base = _conflict?.savedAt;
    setState(() => _conflict = null);
    unawaited(_saveDraft());
  }

  void _useTheirs() {
    _base = _conflict?.savedAt;
    setState(() {
      _response.text = _conflict!.response;
      _conflict = null;
      _draft = _Draft.saved;
    });
  }

  /* ---------- attachment ---------- */

  Future<void> _pick() async {
    final l = context.l10n;
    final choice = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (c) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(LucideIcons.camera),
              title: Text(l.assignmentTakePhoto),
              onTap: () => Navigator.pop(c, 0),
            ),
            ListTile(
              leading: const Icon(LucideIcons.image),
              title: Text(l.assignmentChoosePhoto),
              onTap: () => Navigator.pop(c, 1),
            ),
            ListTile(
              leading: const Icon(LucideIcons.fileText),
              title: Text(l.assignmentChooseFile),
              onTap: () => Navigator.pop(c, 2),
            ),
          ],
        ),
      ),
    );
    if (choice == null) return;
    String? name;
    Uint8List? bytes;
    try {
      if (choice == 2) {
        final f = await FilePicker.pickFile(
          type: FileType.custom,
          allowedExtensions: const ['pdf'],
        );
        if (f == null) return;
        name = f.name;
        bytes = await f.readAsBytes();
      } else {
        // Large photos are scaled down (and HEIC becomes JPEG) so a phone
        // picture fits the 10 MB limit and stays readable.
        final x = await ImagePicker().pickImage(
          source: choice == 0 ? ImageSource.camera : ImageSource.gallery,
          maxWidth: 2400,
          maxHeight: 2400,
          imageQuality: 85,
          requestFullMetadata: false,
        );
        if (x == null) return;
        name = x.name;
        bytes = await x.readAsBytes();
      }
    } on Object {
      if (mounted) setState(() => _attachmentError = l.assignmentUploadFailed);
      return;
    }
    await _upload(name, bytes);
  }

  Future<void> _upload(String name, Uint8List bytes) async {
    final l = context.l10n;
    final mime = mimeForFileName(name);
    if (mime == null || !allowedAttachmentTypes.contains(mime)) {
      setState(() => _attachmentError = l.assignmentBadType);
      return;
    }
    if (bytes.length > maxAttachmentBytes) {
      setState(() => _attachmentError = l.assignmentTooLarge);
      return;
    }
    setState(() {
      _uploading = true;
      _attachmentError = null;
    });
    try {
      final up = await _repo.uploadAttachment(
        widget.courseId,
        widget.assignmentId,
        fileName: name,
        mimeType: mime,
        sizeBytes: bytes.length,
        dataUrl: 'data:$mime;base64,${base64Encode(bytes)}',
      );
      if (!mounted) return;
      setState(() => _attachment = up);
      _changed();
    } on AtlasApiException catch (e) {
      if (mounted) {
        setState(() => _attachmentError = errorText(ref, context, e));
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  void _removeAttachment() {
    setState(() => _attachment = null);
    _changed();
  }

  /* ---------- submit ---------- */

  Future<void> _submit() async {
    final l = context.l10n;
    final a = _assignment!;
    final text = _response.text.trim();
    if (text.isEmpty && _attachment == null) {
      setState(() => _submitError = l.assignmentEmpty);
      return;
    }
    final resubmit = _submission?.isSubmitted ?? false;
    final ok = await confirmDialog(
      context,
      title: resubmit ? l.assignmentResubmitTitle : l.assignmentSubmitTitle,
      body: a.pastDue ? l.assignmentSubmitLateBody : l.assignmentSubmitBody,
      confirm: resubmit ? l.assignmentResubmit : l.assignmentSubmit,
      cancel: l.assignmentKeepEditing,
    );
    if (!ok || !mounted) return;
    _debounce?.cancel();
    // One key per submitted content: a retry of the same content reuses it.
    final payload = jsonEncode([text, _attachment?.assetId]);
    final pending = _pendingSubmit?.payload == payload
        ? _pendingSubmit!
        : (key: newClientOpId(), payload: payload);
    _pendingSubmit = pending;
    setState(() {
      _submitting = true;
      _submitError = null;
    });
    try {
      final s = await _repo.submitAssignment(
        widget.courseId,
        widget.assignmentId,
        response: text.isEmpty ? null : text,
        attachmentAssetId: _attachment?.assetId,
        idempotencyKey: pending.key,
        baseRevision: _submission?.submittedRevision ?? 0,
      );
      _pendingSubmit = null;
      ref.read(analyticsProvider).event('assignment_submit', {
        'attachment': _attachment == null ? 0 : 1,
      });
      HapticFeedback.lightImpact();
      refreshAssessments(ref, widget.courseId);
      if (!mounted) return;
      setState(() {
        _seed(s);
        _editing = false;
      });
    } on AtlasApiException catch (e) {
      if (mounted) setState(() => _submitError = errorText(ref, context, e));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _startEditing() {
    final s = _submission!;
    setState(() {
      _editing = true;
      if (_response.text.isEmpty) _response.text = s.response ?? '';
      _attachment ??= s.attachment;
    });
  }

  /* ---------- build ---------- */

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return ScrollTitleScaffold(
      title: _assignment?.title ?? '',
      body: SafeArea(
        top: false,
        child: _loading
            ? const Center(child: CircularProgressIndicator.adaptive())
            : _assignment == null
            ? ListView(
                padding: const EdgeInsets.all(AtlasSpace.gutter),
                children: [
                  AtlasBanner(
                    kind: AtlasBannerKind.error,
                    message: _loadError == null
                        ? l.loadFailed
                        : errorText(ref, context, _loadError!),
                  ),
                  const SizedBox(height: AtlasSpace.s12),
                  AtlasButton(
                    label: l.commonRetry,
                    style: AtlasButtonStyle.tonal,
                    onPressed: _load,
                  ),
                ],
              )
            : RefreshIndicator.adaptive(
                onRefresh: _load,
                child: ListView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(
                    AtlasSpace.gutter,
                    0,
                    AtlasSpace.gutter,
                    48,
                  ),
                  children: [ReadableWidth(child: _content(context))],
                ),
              ),
      ),
    );
  }

  Widget _content(BuildContext context) {
    final l = context.l10n;
    final a = context.atlas;
    final c = a.colors;
    final asg = _assignment!;
    final sub = _submission;
    final submitted = sub?.isSubmitted ?? false;
    final canResubmit = submitted && asg.allowResubmission && !sub!.isGraded;
    final showForm = !submitted || (canResubmit && _editing);
    final instructions = asg.instructions?.trim().isNotEmpty ?? false
        ? asg.instructions!
        : asg.description?.trim().isNotEmpty ?? false
        ? asg.description!
        : l.assignmentNoInstructions;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AtlasSpace.s8),
        AssessmentHeader(
          icon: LucideIcons.fileText,
          kind: l.unitAssignment,
          title: asg.title,
        ),
        const SizedBox(height: AtlasSpace.s16),
        FactList(
          facts: [
            (
              l.assignmentDue,
              asg.dueAt == null
                  ? l.assignmentNoDue
                  : dateTimeText(context, asg.dueAt!),
            ),
            if (asg.dueAt != null)
              (
                l.assignmentLate,
                asg.latePolicy == 'accept_flagged'
                    ? l.assignmentLateAccept
                    : l.assignmentLateBlock,
              ),
            (
              l.assignmentResubmission,
              asg.allowResubmission
                  ? l.assignmentResubmitAllowed
                  : l.assignmentResubmitNotAllowed,
            ),
          ],
        ),
        if (asg.dueAt != null && !submitted)
          AddToCalendarButton(
            title: asg.title,
            kind: l.unitAssignment,
            dueAt: asg.dueAt!,
          ),
        SectionHeader(title: l.assignmentInstructions),
        SelectionArea(
          child: Text(instructions, style: a.type.body.copyWith(color: c.ink)),
        ),
        if (submitted) ...[
          SectionHeader(title: l.assignmentYourSubmission),
          _Submitted(submission: sub!),
          if (!showForm) ...[
            const SizedBox(height: AtlasSpace.s16),
            if (canResubmit)
              AtlasButton(
                label: l.assignmentEditSubmission,
                style: AtlasButtonStyle.tonal,
                icon: LucideIcons.pencil,
                onPressed: _startEditing,
              )
            else if (!asg.allowResubmission)
              Text(
                l.assignmentResubmitClosed,
                style: a.type.footnote.copyWith(color: c.inkSecondary),
              ),
          ],
        ],
        if (showForm) ...[
          const SizedBox(height: AtlasSpace.s20),
          if (asg.pastDue)
            AtlasBanner(
              kind: asg.blockedByDue
                  ? AtlasBannerKind.error
                  : AtlasBannerKind.info,
              message:
                  '${l.assignmentPastDueTitle}. ${asg.blockedByDue ? l.assignmentPastDueBlocked : l.assignmentPastDueAccepted}',
            ),
          if (!asg.blockedByDue) ..._form(context, submitted),
        ],
      ],
    );
  }

  List<Widget> _form(BuildContext context, bool resubmit) {
    final l = context.l10n;
    final a = context.atlas;
    final c = a.colors;
    final draftText = switch (_draft) {
      _Draft.saving => l.assignmentDraftSaving,
      _Draft.saved => l.assignmentDraftSaved,
      _Draft.failed => l.assignmentDraftFailed,
      _Draft.dirty => l.assignmentDraftUnsaved,
      _ => '',
    };
    return [
      const SizedBox(height: AtlasSpace.s16),
      if (_conflict != null) ...[
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l.assignmentConflictTitle,
                style: a.type.headline.copyWith(color: c.ink),
              ),
              Text(
                l.assignmentConflictBody,
                style: a.type.subhead.copyWith(color: c.inkSecondary),
              ),
              const SizedBox(height: 8),
              Text(
                _conflict!.response,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: a.type.body.copyWith(color: c.ink),
              ),
              const SizedBox(height: 12),
              AtlasButton(label: l.assignmentKeepMine, onPressed: _keepMine),
              const SizedBox(height: 8),
              AtlasButton(
                label: l.assignmentUseTheirs,
                style: AtlasButtonStyle.tonal,
                onPressed: _useTheirs,
              ),
            ],
          ),
        ),
        const SizedBox(height: AtlasSpace.s16),
      ],
      AnswerField(
        controller: _response,
        label: l.assignmentResponse,
        hint: l.assignmentResponseHint,
        minLines: 6,
        maxLines: 16,
        maxLength: maxAssignmentResponseLength,
        enabled: !_submitting,
        onChanged: (_) => _changed(),
      ),
      Semantics(
        liveRegion: _draft == _Draft.failed,
        child: Text(
          draftText,
          style: a.type.caption.copyWith(
            color: _draft == _Draft.failed ? c.warning : c.inkTertiary,
          ),
        ),
      ),
      const SizedBox(height: AtlasSpace.s16),
      Text(
        l.assignmentAttachment,
        style: a.type.footnote.copyWith(color: c.inkSecondary),
      ),
      const SizedBox(height: 6),
      if (_attachment != null)
        _AttachmentRow(
          attachment: _attachment!,
          onRemove: _submitting ? null : _removeAttachment,
        )
      else
        AtlasButton(
          label: _uploading ? l.assignmentUploading : l.assignmentAttachment,
          icon: LucideIcons.paperclip,
          style: AtlasButtonStyle.tonal,
          loading: _uploading,
          onPressed: _uploading || _submitting ? null : _pick,
        ),
      const SizedBox(height: 6),
      Text(
        l.assignmentAttachmentHelp,
        style: a.type.footnote.copyWith(color: c.inkTertiary),
      ),
      if (_attachmentError != null) ...[
        const SizedBox(height: 8),
        AtlasBanner(kind: AtlasBannerKind.error, message: _attachmentError!),
      ],
      if (_submitError != null) ...[
        const SizedBox(height: AtlasSpace.s16),
        AtlasBanner(kind: AtlasBannerKind.error, message: _submitError!),
      ],
      const SizedBox(height: AtlasSpace.s24),
      AtlasButton(
        label: resubmit ? l.assignmentResubmit : l.assignmentSubmit,
        icon: LucideIcons.send,
        loading: _submitting,
        onPressed: _submitting || _uploading || _conflict != null
            ? null
            : _submit,
      ),
    ];
  }
}

class _AttachmentRow extends StatelessWidget {
  const _AttachmentRow({required this.attachment, this.onRemove, this.onOpen});
  final SubmissionAttachment attachment;
  final VoidCallback? onRemove;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final a = context.atlas;
    final c = a.colors;
    final pdf = attachment.mimeType == 'application/pdf';
    return Panel(
      child: Row(
        children: [
          Icon(pdf ? LucideIcons.fileText : LucideIcons.image, color: c.accent),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Text(
                    attachment.fileName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: a.type.headline.copyWith(color: c.ink),
                  ),
                ),
                Text(
                  fileSizeText(context, attachment.sizeBytes),
                  style: a.type.footnote.copyWith(color: c.inkSecondary),
                ),
              ],
            ),
          ),
          if (onOpen != null)
            TextButton(
              onPressed: onOpen,
              child: Text(l.assignmentOpenAttachment),
            ),
          if (onRemove != null)
            TextButton(
              onPressed: onRemove,
              child: Text(l.assignmentRemoveAttachment),
            ),
        ],
      ),
    );
  }
}

/// What was sent, the three-step timeline and, once graded, the result.
class _Submitted extends StatelessWidget {
  const _Submitted({required this.submission});
  final AssignmentSubmission submission;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final a = context.atlas;
    final c = a.colors;
    final s = submission;
    final steps = [
      (l.assignmentStepSubmitted, true),
      (l.assignmentStepGrading, true),
      (l.assignmentStepGraded, s.isGraded),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            for (final (i, (label, done)) in steps.indexed) ...[
              if (i > 0)
                Expanded(
                  child: Container(
                    height: 2,
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    color: done ? c.accent : c.rule,
                  ),
                ),
              Column(
                children: [
                  Icon(
                    done ? LucideIcons.circleCheck : LucideIcons.circle,
                    size: 22,
                    color: done ? c.accent : c.inkTertiary,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: a.type.caption.copyWith(
                      color: done ? c.ink : c.inkTertiary,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        const SizedBox(height: AtlasSpace.s16),
        if (s.isGraded)
          Panel(
            tonal: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(LucideIcons.badgeCheck, size: 26, color: c.goldText),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        s.score == null
                            ? l.assignmentGradedNoScore
                            : l.assignmentScore(numberText(context, s.score!)),
                        style: a.type.title2.copyWith(color: c.ink),
                      ),
                    ),
                  ],
                ),
                if (s.gradedAt != null)
                  Text(
                    l.assignmentGradedAt(dateTimeText(context, s.gradedAt!)),
                    style: a.type.footnote.copyWith(color: c.inkSecondary),
                  ),
                if (s.feedback?.trim().isNotEmpty ?? false) ...[
                  const SizedBox(height: 10),
                  Text(
                    l.assignmentFeedback,
                    style: a.type.footnote.copyWith(color: c.inkSecondary),
                  ),
                  SelectionArea(
                    child: Text(
                      s.feedback!,
                      style: a.type.body.copyWith(color: c.ink),
                    ),
                  ),
                ],
              ],
            ),
          )
        else
          Text(
            l.assignmentAwaiting,
            style: a.type.subhead.copyWith(color: c.inkSecondary),
          ),
        const SizedBox(height: AtlasSpace.s16),
        Text(
          [
            if (s.submittedAt != null)
              l.assignmentSubmittedAt(dateTimeText(context, s.submittedAt!)),
            if (s.isLate) l.assignmentSubmittedLate,
          ].join(context.sep),
          style: a.type.footnote.copyWith(
            color: s.isLate ? c.warning : c.inkSecondary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          (s.response?.trim().isNotEmpty ?? false)
              ? s.response!
              : l.assignmentNoText,
          style: a.type.body.copyWith(
            color: (s.response?.trim().isNotEmpty ?? false)
                ? c.ink
                : c.inkTertiary,
          ),
        ),
        if (s.attachment != null) ...[
          const SizedBox(height: AtlasSpace.s12),
          _AttachmentRow(
            attachment: s.attachment!,
            onOpen: s.attachment!.url == null
                ? null
                : () => launchUrl(
                    Uri.parse(s.attachment!.url!),
                    mode: LaunchMode.inAppBrowserView,
                  ),
          ),
        ],
      ],
    );
  }
}

/// The attachment types the backend accepts, by file extension.
String? mimeForFileName(String name) {
  final dot = name.lastIndexOf('.');
  if (dot < 0) return null;
  return switch (name.substring(dot + 1).toLowerCase()) {
    'pdf' => 'application/pdf',
    'png' => 'image/png',
    'jpg' || 'jpeg' => 'image/jpeg',
    'gif' => 'image/gif',
    'webp' => 'image/webp',
    _ => null,
  };
}

String fileSizeText(BuildContext context, int bytes) {
  final kb = bytes / 1024;
  final text = kb < 1024
      ? '${kb.ceil()} KB'
      : '${(kb / 1024).toStringAsFixed(1)} MB';
  return context.digits(text);
}

final _rand = Random.secure();

/// A random id for one submit action (sent as its idempotency key).
String newClientOpId() => List.generate(
  16,
  (_) => _rand.nextInt(256).toRadixString(16).padLeft(2, '0'),
).join();
