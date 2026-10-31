import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/learning_providers.dart';
import '../../app/providers.dart';
import '../../app/ui_helpers.dart';
import '../../core/learning/learning_models.dart';
import '../../design/design.dart';
import '../catalog/catalog_screen.dart';
import '../learning/course_widgets.dart';
import '../learning/learning_ui.dart';

class MyCoursesScreen extends ConsumerStatefulWidget {
  const MyCoursesScreen({super.key});

  @override
  ConsumerState<MyCoursesScreen> createState() => _MyCoursesScreenState();
}

class _MyCoursesScreenState extends ConsumerState<MyCoursesScreen> {
  String _filter = 'all';

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
              ),
            ),
          ],
        ),
      ),
    );
  }
}
