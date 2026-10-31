import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/learning_providers.dart';
import '../../app/push.dart';
import '../../app/ui_helpers.dart';
import '../../core/api/api_error.dart';
import '../../core/learning/catalog_repository.dart';
import '../../design/design.dart';
import '../catalog/reviews.dart';
import '../quiz/assessment_widgets.dart';

/// On an enrolled course's page: the learner's own rating. Five stars to
/// start one; once written, the stars, the comment, whether the academy
/// has approved it, and edit / delete.
class MyReviewCard extends ConsumerWidget {
  const MyReviewCard({super.key, required this.courseId});
  final String courseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final a = context.atlas;
    final c = a.colors;
    final mine = ref.watch(myReviewProvider(courseId));
    // Nothing while loading or if it cannot load: it is an extra.
    if (!mine.hasValue) return const SizedBox.shrink();
    final review = mine.value;

    Future<void> write([int stars = 0]) => _writeReview(
      context,
      ref,
      courseId: courseId,
      current: review,
      stars: stars,
    );

    return AtlasCard(
      key: const ValueKey('my-review'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(
              review == null ? l.myReviewTitle : l.myReviewYours,
              style: a.type.title3.copyWith(color: c.ink),
            ),
          ),
          const SizedBox(height: 4),
          if (review == null) ...[
            Text(
              l.myReviewPrompt,
              style: a.type.subhead.copyWith(color: c.inkSecondary),
            ),
            const SizedBox(height: 8),
            StarPicker(value: 0, onChanged: write),
          ] else ...[
            Row(
              children: [
                Stars(rating: review.rating.toDouble(), size: 20),
                const SizedBox(width: 10),
                Flexible(child: _Status(status: review.status)),
              ],
            ),
            if (review.body case final body? when body.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                body,
                textDirection: contentDirection(context, body),
                style: a.type.body.copyWith(color: c.ink),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                TextButton.icon(
                  onPressed: write,
                  icon: const Icon(LucideIcons.pencil, size: 18),
                  label: Text(l.myReviewEdit),
                ),
                TextButton.icon(
                  style: TextButton.styleFrom(foregroundColor: c.danger),
                  onPressed: () => _delete(context, ref),
                  icon: const Icon(LucideIcons.trash2, size: 18),
                  label: Text(l.myReviewDelete),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final l = context.l10n;
    final ok = await confirmDialog(
      context,
      title: l.myReviewDeleteTitle,
      confirm: l.myReviewDelete,
      cancel: l.commonCancel,
      destructive: true,
    );
    if (!ok || !context.mounted) return;
    try {
      await ref.read(learningRepositoryProvider).deleteReview(courseId);
      ref.invalidate(myReviewProvider(courseId));
      if (context.mounted) _say(context, l.myReviewDeleted);
    } on AtlasApiException catch (e) {
      if (context.mounted) _say(context, errorText(ref, context, e));
    }
  }
}

class _Status extends StatelessWidget {
  const _Status({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final a = context.atlas;
    final c = a.colors;
    final (text, color) = switch (status) {
      'approved' => (l.myReviewApproved, c.success),
      'rejected' => (l.myReviewRejected, c.danger),
      _ => (l.myReviewPending, c.inkSecondary),
    };
    return Text(text, style: a.type.footnote.copyWith(color: color));
  }
}

/// Five stars to tap, each a 48pt target, read as "4 out of 5".
class StarPicker extends StatelessWidget {
  const StarPicker({super.key, required this.value, required this.onChanged});
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.atlas.colors;
    return Row(
      children: [
        for (var i = 1; i <= 5; i++)
          IconButton(
            tooltip: context.l10n.myReviewStar(context.digits('$i')),
            isSelected: i <= value,
            constraints: const BoxConstraints.tightFor(width: 48, height: 48),
            onPressed: () {
              HapticFeedback.selectionClick();
              onChanged(i);
            },
            icon: Icon(
              i <= value ? Icons.star_rounded : Icons.star_outline_rounded,
              size: 34,
              color: i <= value ? c.goldText : c.inkTertiary,
            ),
          ),
      ],
    );
  }
}

void _say(BuildContext context, String text) => ScaffoldMessenger.of(context)
  ..hideCurrentSnackBar()
  ..showSnackBar(
    SnackBar(behavior: SnackBarBehavior.floating, content: Text(text)),
  );

Future<void> _writeReview(
  BuildContext context,
  WidgetRef ref, {
  required String courseId,
  CourseReview? current,
  int stars = 0,
}) async {
  final sent = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _ReviewSheet(
      courseId: courseId,
      stars: stars > 0 ? stars : current?.rating ?? 0,
      body: current?.body ?? '',
    ),
  );
  if (sent == true && context.mounted) {
    ref.invalidate(myReviewProvider(courseId));
    _say(context, context.l10n.myReviewSent);
  }
}

class _ReviewSheet extends ConsumerStatefulWidget {
  const _ReviewSheet({
    required this.courseId,
    required this.stars,
    required this.body,
  });
  final String courseId;
  final int stars;
  final String body;

  @override
  ConsumerState<_ReviewSheet> createState() => _ReviewSheetState();
}

class _ReviewSheetState extends ConsumerState<_ReviewSheet> {
  late int _stars = widget.stars;
  late final _body = TextEditingController(text: widget.body);
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _body.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final l = context.l10n;
    if (_stars == 0) {
      setState(() => _error = l.myReviewPickStars);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(learningRepositoryProvider)
          .saveReview(widget.courseId, rating: _stars, body: _body.text);
      ref.read(analyticsProvider).event('course_review', {'stars': _stars});
      if (mounted) Navigator.pop(context, true);
    } on AtlasApiException catch (e) {
      if (mounted) setState(() => _error = errorText(ref, context, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
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
              l.myReviewTitle,
              style: a.type.title3.copyWith(color: a.colors.ink),
            ),
            const SizedBox(height: 8),
            StarPicker(
              value: _stars,
              onChanged: (v) => setState(() {
                _stars = v;
                _error = null;
              }),
            ),
            const SizedBox(height: 12),
            AnswerField(
              controller: _body,
              label: l.myReviewComment,
              hint: l.myReviewCommentHint,
              minLines: 3,
              maxLines: 6,
              maxLength: 2000,
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              AtlasBanner(kind: AtlasBannerKind.error, message: _error!),
            ],
            const SizedBox(height: 12),
            AtlasButton(
              label: l.myReviewSend,
              loading: _busy,
              onPressed: _busy ? null : _send,
            ),
          ],
        ),
      ),
    );
  }
}
