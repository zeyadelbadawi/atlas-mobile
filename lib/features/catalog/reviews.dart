import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/learning_providers.dart';
import '../../app/providers.dart';
import '../../app/ui_helpers.dart';
import '../../core/config/app_env.dart';
import '../../core/learning/catalog_repository.dart';
import '../../design/design.dart';
import '../learning/learning_ui.dart';

/// Reviews the learner reported or hid: gone from every list on this
/// phone at once (store review rules for content others publish).
class HiddenReviews extends Notifier<Set<String>> {
  static const key = 'reviews.hidden';

  @override
  Set<String> build() =>
      (ref.watch(sharedPreferencesProvider).getStringList(key) ?? const [])
          .toSet();

  Future<void> hide(String reviewId) async {
    if (reviewId.isEmpty || state.contains(reviewId)) return;
    state = {...state, reviewId};
    await ref
        .read(sharedPreferencesProvider)
        .setStringList(key, state.toList());
  }
}

final hiddenReviewsProvider = NotifierProvider<HiddenReviews, Set<String>>(
  HiddenReviews.new,
);

/// Report a review to Atlas by email (with what identifies it), then hide
/// it; or only hide it.
Future<void> _reviewActions(
  BuildContext context,
  WidgetRef ref,
  CourseReview review,
  String courseId,
) async {
  final l = context.l10n;
  final choice = await showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    builder: (c) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(LucideIcons.flag),
            title: Text(l.reviewReport),
            subtitle: Text(l.reviewReportHelp),
            onTap: () => Navigator.pop(c, 'report'),
          ),
          ListTile(
            leading: const Icon(LucideIcons.eyeOff),
            title: Text(l.reviewHide),
            onTap: () => Navigator.pop(c, 'hide'),
          ),
        ],
      ),
    ),
  );
  if (choice == null || !context.mounted) return;
  if (choice == 'report') {
    final host = ref.read(sessionProvider).academy?.host ?? '';
    unawaited(
      launchUrl(
        Uri(
          scheme: 'mailto',
          path: AppEnv.supportEmail,
          query: _query({
            'subject': l.reviewReportSubject,
            'body': l.reviewReportBody(host, courseId, review.id),
          }),
        ),
        mode: LaunchMode.externalApplication,
      ).catchError((_) => false),
    );
  }
  await ref.read(hiddenReviewsProvider.notifier).hide(review.id);
  if (!context.mounted) return;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(choice == 'report' ? l.reviewReported : l.reviewHidden),
      ),
    );
}

String _query(Map<String, String> q) =>
    q.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&');

/// 4.6 → "٤٫٦" in Arabic, "4.6" in English.
String ratingText(BuildContext context, double rating) {
  final s = rating.toStringAsFixed(1);
  return context.languageCode == 'ar'
      ? context.digits(s).replaceAll('.', '٫')
      : s;
}

/// Five stars, filled to [rating] (halves included), read out as
/// "4.5 out of 5 stars".
class Stars extends StatelessWidget {
  const Stars({super.key, required this.rating, this.size = 16});
  final double rating;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = context.atlas.colors;
    final r = (rating * 2).round() / 2;
    return Semantics(
      label: context.l10n.reviewsStars(ratingText(context, rating)),
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 1; i <= 5; i++)
              Icon(
                r >= i
                    ? Icons.star_rounded
                    : r >= i - 0.5
                    ? Icons.star_half_rounded
                    : Icons.star_outline_rounded,
                size: size,
                color: r >= i - 0.5 ? c.goldText : c.inkTertiary,
              ),
          ],
        ),
      ),
    );
  }
}

/// The short form in lists: "★ ٤٫٦ (٢٣)".
class RatingBadge extends StatelessWidget {
  const RatingBadge({super.key, required this.average, required this.total});
  final double average;
  final int total;

  @override
  Widget build(BuildContext context) {
    final a = context.atlas;
    final c = a.colors;
    return Semantics(
      label:
          '${context.l10n.reviewsStars(ratingText(context, average))}'
          '${context.sep}'
          '${context.l10n.reviewsCount(total, context.digits('$total'))}',
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.star_rounded, size: 16, color: c.goldText),
            const SizedBox(width: 3),
            Text(
              ratingText(context, average),
              style: a.type.caption.copyWith(
                color: c.ink,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '(${context.digits('$total')})',
              style: a.type.caption.copyWith(color: c.inkSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

/// The course preview's reviews: the mean, how the stars spread, the
/// newest few, and the way to all of them. Nothing when there are none.
class CourseReviewsSection extends ConsumerWidget {
  const CourseReviewsSection({
    super.key,
    required this.courseId,
    required this.total,
  });

  final String courseId;

  /// From the course itself, so the section knows at once whether to show.
  final int total;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (total == 0) return const SizedBox.shrink();
    final l = context.l10n;
    final summary = ref.watch(courseRatingProvider(courseId)).value;
    final hidden = ref.watch(hiddenReviewsProvider);
    final latest = ref.watch(latestReviewsProvider(courseId)).value;
    return Column(
      key: const ValueKey('course-reviews'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(title: l.reviewsTitle),
        if (summary != null) RatingSummaryView(summary: summary),
        if (latest != null)
          for (final r in latest.items)
            if (!hidden.contains(r.id))
              ReviewTile(review: r, courseId: courseId),
        if (total > (latest?.items.length ?? 0)) ...[
          const SizedBox(height: AtlasSpace.s12),
          AtlasButton(
            label: l.reviewsSeeAll,
            style: AtlasButtonStyle.tonal,
            onPressed: () => context.push('/catalog/$courseId/reviews'),
          ),
        ],
      ],
    );
  }
}

class RatingSummaryView extends StatelessWidget {
  const RatingSummaryView({super.key, required this.summary});
  final RatingSummary summary;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final a = context.atlas;
    final c = a.colors;
    final most = summary.distribution.values.fold(0, (m, v) => v > m ? v : m);
    return Padding(
      padding: const EdgeInsets.only(bottom: AtlasSpace.s8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                ratingText(context, summary.average),
                style: a.type.numeral.copyWith(color: c.ink),
              ),
              Stars(rating: summary.average),
              const SizedBox(height: 4),
              Text(
                l.reviewsCount(
                  summary.total,
                  context.digits('${summary.total}'),
                ),
                style: a.type.caption.copyWith(color: c.inkSecondary),
              ),
            ],
          ),
          const SizedBox(width: AtlasSpace.s20),
          Expanded(
            child: Column(
              children: [
                for (var star = 5; star >= 1; star--)
                  Semantics(
                    label: l.reviewsStarsRow(
                      context.digits('$star'),
                      context.digits('${summary.distribution[star] ?? 0}'),
                    ),
                    child: ExcludeSemantics(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 14,
                              child: Text(
                                context.digits('$star'),
                                textAlign: TextAlign.center,
                                style: a.type.caption.copyWith(
                                  color: c.inkSecondary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(3),
                                child: LinearProgressIndicator(
                                  value: most == 0
                                      ? 0
                                      : (summary.distribution[star] ?? 0) /
                                            most,
                                  minHeight: 6,
                                  color: c.goldText,
                                  backgroundColor: c.sunken,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ReviewTile extends ConsumerWidget {
  const ReviewTile({super.key, required this.review, required this.courseId});
  final CourseReview review;
  final String courseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final a = context.atlas;
    final c = a.colors;
    final name = review.name?.isNotEmpty == true
        ? review.name!
        : l.reviewsLearner;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: c.rule)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  textDirection: contentDirection(context, name),
                  // At the row's start whatever the name's language, so an
                  // English name in Arabic never runs into the date.
                  textAlign: Directionality.of(context) == TextDirection.rtl
                      ? TextAlign.right
                      : TextAlign.left,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: a.type.headline.copyWith(color: c.ink),
                ),
              ),
              if (review.createdAt != null) ...[
                const SizedBox(width: 12),
                Text(
                  shortDate(context, review.createdAt!),
                  style: a.type.caption.copyWith(color: c.inkTertiary),
                ),
              ],
              if (review.id.isNotEmpty)
                IconButton(
                  key: ValueKey('review-actions-${review.id}'),
                  tooltip: l.reviewActions,
                  visualDensity: VisualDensity.compact,
                  icon: Icon(
                    LucideIcons.ellipsis,
                    size: 20,
                    color: c.inkTertiary,
                  ),
                  onPressed: () =>
                      unawaited(_reviewActions(context, ref, review, courseId)),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Stars(rating: review.rating.toDouble(), size: 14),
          if (review.body case final body? when body.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              body,
              textDirection: contentDirection(context, body),
              style: a.type.body.copyWith(color: c.ink),
            ),
          ],
        ],
      ),
    );
  }
}

/// Every approved review of a course, a page at a time.
class CourseReviewsScreen extends ConsumerStatefulWidget {
  const CourseReviewsScreen({super.key, required this.courseId});
  final String courseId;

  @override
  ConsumerState<CourseReviewsScreen> createState() =>
      _CourseReviewsScreenState();
}

class _CourseReviewsScreenState extends ConsumerState<CourseReviewsScreen> {
  final _items = <CourseReview>[];
  int _page = 0;
  bool _hasMore = true, _loading = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _more();
  }

  Future<void> _more() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await ref
          .read(catalogRepositoryProvider)
          .reviews(widget.courseId, page: _page + 1);
      if (!mounted) return;
      setState(() {
        _page++;
        _items.addAll(page.items);
        _hasMore = page.hasMore;
      });
    } on Object catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final summary = ref.watch(courseRatingProvider(widget.courseId)).value;
    final hidden = ref.watch(hiddenReviewsProvider);
    final a = context.atlas;
    return ScrollTitleScaffold(
      title: l.reviewsTitle,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AtlasSpace.gutter,
          0,
          AtlasSpace.gutter,
          48,
        ),
        children: [
          ReadableWidth(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Semantics(
                  header: true,
                  child: SafeText(
                    l.reviewsTitle,
                    style: a.type.title1.copyWith(color: a.colors.ink),
                  ),
                ),
                const SizedBox(height: AtlasSpace.s16),
                if (summary != null) RatingSummaryView(summary: summary),
                for (final r in _items)
                  if (!hidden.contains(r.id))
                    ReviewTile(review: r, courseId: widget.courseId),
                if (_error != null)
                  LoadError(
                    message: errorText(ref, context, _error!),
                    error: _error,
                    onRetry: _more,
                  )
                else if (_loading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(child: CircularProgressIndicator.adaptive()),
                  )
                else if (_hasMore)
                  Padding(
                    padding: const EdgeInsets.only(top: AtlasSpace.s16),
                    child: AtlasButton(
                      label: l.catalogLoadMore,
                      style: AtlasButtonStyle.tonal,
                      onPressed: _more,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
