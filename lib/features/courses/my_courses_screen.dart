import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/learning_providers.dart';
import '../../app/providers.dart';
import '../../app/ui_helpers.dart';
import '../../core/learning/learning_models.dart';
import '../../design/design.dart';
import '../../core/text/search_text.dart';
import '../catalog/catalog_screen.dart';
import 'course_screen.dart' show explainLocked;
import '../learning/course_widgets.dart';
import '../learning/learning_ui.dart';

class MyCoursesScreen extends ConsumerStatefulWidget {
  const MyCoursesScreen({super.key});

  @override
  ConsumerState<MyCoursesScreen> createState() => _MyCoursesScreenState();
}

class _MyCoursesScreenState extends ConsumerState<MyCoursesScreen> {
  String _filter = 'all';
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final a = context.atlas;
    final courses = ref.watch(enrollmentsProvider);
    return Scaffold(
      body: RefreshIndicator.adaptive(
        onRefresh: () async {
          ref.invalidate(enrollmentsProvider);
          await ref.read(enrollmentsProvider.future);
        },
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            AtlasSpace.gutter,
            MediaQuery.paddingOf(context).top + AtlasSpace.s16,
            AtlasSpace.gutter,
            120,
          ),
          children: [
            ReadableWidth(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Semantics(
                    header: true,
                    child: Text(
                      l.coursesTitle,
                      style: a.type.largeTitle.copyWith(color: a.colors.ink),
                    ),
                  ),
                  const SizedBox(height: AtlasSpace.s16),
                  BrowseFreeCoursesCard(
                    academyName: ref.watch(sessionProvider).academy?.name ?? '',
                  ),
                  const SizedBox(height: AtlasSpace.s16),
                  AtlasTextField(
                    key: const ValueKey('courses-search'),
                    label: l.coursesSearch,
                    controller: _search,
                    textInputAction: TextInputAction.search,
                    prefix: Icon(
                      LucideIcons.search,
                      size: 18,
                      color: a.colors.inkSecondary,
                    ),
                    trailing: _search.text.isEmpty
                        ? null
                        : IconButton(
                            tooltip: l.catalogClearSearch,
                            icon: Icon(
                              LucideIcons.x,
                              size: 18,
                              color: a.colors.inkSecondary,
                            ),
                            onPressed: () => setState(_search.clear),
                          ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: AtlasSpace.s16),
                  if (_search.text.trim().isNotEmpty)
                    _SearchResults(query: _search.text.trim())
                  else ...[
                    SegmentedButton<String>(
                      showSelectedIcon: false,
                      segments: [
                        ButtonSegment(value: 'all', label: Text(l.coursesAll)),
                        ButtonSegment(
                          value: 'in_progress',
                          label: Text(l.coursesInProgress),
                        ),
                        ButtonSegment(
                          value: 'completed',
                          label: Text(l.coursesCompleted),
                        ),
                      ],
                      selected: {_filter},
                      onSelectionChanged: (s) =>
                          setState(() => _filter = s.first),
                      style: SegmentedButton.styleFrom(
                        selectedBackgroundColor: a.colors.tonal,
                        selectedForegroundColor: a.colors.accent,
                      ),
                    ),
                    const SizedBox(height: AtlasSpace.s8),
                    AsyncBody<List<EnrolledCourse>>(
                      value: courses,
                      onRetry: () => ref.invalidate(enrollmentsProvider),
                      data: (list) {
                        final shown = switch (_filter) {
                          'completed' => list.where(
                            (c) => c.learningState == 'completed',
                          ),
                          'in_progress' => list.where(
                            (c) => c.learningState != 'completed',
                          ),
                          _ => list,
                        }.toList();
                        if (shown.isEmpty) {
                          return EmptyState(
                            icon: list.isEmpty
                                ? LucideIcons.bookOpen
                                : LucideIcons.listFilter,
                            title: list.isEmpty
                                ? l.homeEmptyTitle
                                : l.coursesNoneInFilter,
                          );
                        }
                        return Column(
                          children: [
                            for (final (i, c) in shown.indexed)
                              Entrance(
                                key: ValueKey(c.courseId),
                                order: i,
                                child: EnrolledCourseRow(
                                  course: c,
                                  number: list.indexOf(c) + 1,
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Courses whose name or teacher matches, then lessons, quizzes and
/// assignments whose name does, across every enrolled course.
class _SearchResults extends ConsumerWidget {
  const _SearchResults({required this.query});
  final String query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final courses = ref.watch(enrollmentsProvider).value ?? const [];
    final index = ref.watch(searchIndexProvider);
    final courseHits = [
      for (final (i, c) in courses.indexed)
        if (searchMatches('${c.title} ${c.instructors.join(' ')}', query))
          (i, c),
    ];
    final itemHits = [
      for (final s in index.value ?? const <CourseSequence>[])
        for (final item in s.items)
          if (searchMatches(item.title, query)) (s, item),
    ];
    final searching = index.isLoading && !index.hasValue;
    if (courseHits.isEmpty && itemHits.isEmpty && !searching) {
      return EmptyState(
        icon: LucideIcons.searchX,
        title: l.coursesSearchNone(query),
      );
    }
    return Column(
      key: const ValueKey('courses-search-results'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (courseHits.isNotEmpty) ...[
          SectionHeader(title: l.coursesSearchCourses),
          for (final (i, c) in courseHits)
            EnrolledCourseRow(course: c, number: i + 1),
        ],
        if (itemHits.isNotEmpty) ...[
          SectionHeader(title: l.coursesSearchLessons),
          for (final (s, item) in itemHits.take(50))
            _ItemHit(sequence: s, item: item),
        ],
        if (searching)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator.adaptive()),
          ),
      ],
    );
  }
}

class _ItemHit extends ConsumerWidget {
  const _ItemHit({required this.sequence, required this.item});
  final CourseSequence sequence;
  final SequenceItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final a = context.atlas;
    final c = a.colors;
    final lock = lockText(context, item);
    return MergeSemantics(
      child: Pressable(
        scale: 0.99,
        onTap: item.isLocked
            ? () => explainLocked(context, item)
            : () => openItem(context, ref, sequence, item),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: c.rule)),
          ),
          child: Row(
            children: [
              IconTile(icon: itemIcon(item.type)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      textDirection: contentDirection(context, item.title),
                      style: a.type.headline.copyWith(
                        color: item.isLocked ? c.inkTertiary : c.ink,
                      ),
                    ),
                    Text(
                      [
                        sequence.courseTitle,
                        unitLabel(context, item.type),
                        ?lock,
                      ].join(context.sep),
                      style: a.type.footnote.copyWith(color: c.inkSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (item.isDone)
                Icon(LucideIcons.circleCheck, size: 20, color: c.success)
              else if (item.isLocked)
                Icon(LucideIcons.lock, size: 18, color: c.inkTertiary)
              else
                const ForwardChevron(),
            ],
          ),
        ),
      ),
    );
  }
}
