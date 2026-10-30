import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/learning_providers.dart';
import '../../app/ui_helpers.dart';
import '../../core/learning/assessment_models.dart';
import '../../design/design.dart';
import '../learning/learning_ui.dart';
import '../quiz/assessment_widgets.dart';
import '../results/results_screen.dart';

/// The Tasks tab: every quiz and assignment in the academy, in three groups
/// — to do, awaiting grading, graded — each opening the quiz or assignment.
class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> {
  TaskGroup _group = TaskGroup.todo;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final a = context.atlas;
    final tasks = ref.watch(tasksProvider);
    final all = tasks.value ?? const <LearnerTask>[];
    int count(TaskGroup g) => all.where((t) => t.group == g).length;
    String label(String text, TaskGroup g) =>
        tasks.hasValue ? '$text (${context.digits('${count(g)}')})' : text;

    return Scaffold(
      body: RefreshIndicator.adaptive(
        onRefresh: () => ref.refresh(tasksProvider.future),
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
                      l.tasksTitle,
                      style: a.type.largeTitle.copyWith(color: a.colors.ink),
                    ),
                  ),
                  const SizedBox(height: AtlasSpace.s16),
                  SegmentedButton<TaskGroup>(
                    showSelectedIcon: false,
                    segments: [
                      ButtonSegment(
                        value: TaskGroup.todo,
                        label: Text(label(l.tasksTodo, TaskGroup.todo)),
                      ),
                      ButtonSegment(
                        value: TaskGroup.awaiting,
                        label: Text(
                          label(l.tasksAwaitingShort, TaskGroup.awaiting),
                        ),
                      ),
                      ButtonSegment(
                        value: TaskGroup.graded,
                        label: Text(label(l.tasksGraded, TaskGroup.graded)),
                      ),
                    ],
                    selected: {_group},
                    onSelectionChanged: (s) => setState(() => _group = s.first),
                    style: SegmentedButton.styleFrom(
                      selectedBackgroundColor: a.colors.tonal,
                      selectedForegroundColor: a.colors.accent,
                    ),
                  ),
                  const SizedBox(height: AtlasSpace.s8),
                  AsyncBody<List<LearnerTask>>(
                    value: tasks,
                    onRetry: () => ref.invalidate(tasksProvider),
                    data: (list) => _List(all: list, group: _group),
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

class _List extends StatelessWidget {
  const _List({required this.all, required this.group});
  final List<LearnerTask> all;
  final TaskGroup group;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final a = context.atlas;
    final shown = all.where((t) => t.group == group).toList()
      ..sort(switch (group) {
        // Overdue first, then the nearest due date; no date last.
        TaskGroup.todo => (x, y) {
          if (x.overdue != y.overdue) return x.overdue ? -1 : 1;
          final dx = x.dueAt, dy = y.dueAt;
          if (dx == null || dy == null) return dx == null ? 1 : -1;
          return dx.compareTo(dy);
        },
        // Newest first.
        _ => (x, y) => (y.submittedAt ?? DateTime(0)).compareTo(
          x.submittedAt ?? DateTime(0),
        ),
      });
    if (shown.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Text(
          all.isEmpty
              ? l.tasksNone
              : switch (group) {
                  TaskGroup.todo => l.tasksEmptyTodo,
                  TaskGroup.awaiting => l.tasksEmptyAwaiting,
                  TaskGroup.graded => l.tasksEmptyGraded,
                },
          textAlign: TextAlign.center,
          style: a.type.body.copyWith(color: a.colors.inkSecondary),
        ),
      );
    }
    return Column(children: [for (final t in shown) _TaskRow(task: t)]);
  }
}

class _TaskRow extends StatelessWidget {
  const _TaskRow({required this.task});
  final LearnerTask task;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = task;
    final when = switch (t.group) {
      TaskGroup.todo when t.dueAt != null => l.tasksDue(
        shortDate(context, t.dueAt!),
      ),
      TaskGroup.todo => null,
      _ when t.submittedAt != null => l.tasksSubmitted(
        shortDate(context, t.submittedAt!),
      ),
      _ => null,
    };
    final Widget trailing = switch (t.group) {
      TaskGroup.graded =>
        t.score == null
            ? StatusPill(
                label: l.assignmentGradedNoScore,
                tone: PillTone.success,
              )
            : ScoreText(
                text: t.isQuiz
                    ? percentText(context, t.score!)
                    : numberText(context, t.score!),
                passed: t.isQuiz ? t.state == 'passed' : null,
              ),
      TaskGroup.awaiting => StatusPill(label: l.tasksAwaiting),
      TaskGroup.todo => switch (t.state) {
        'overdue' => StatusPill(label: l.overdue, tone: PillTone.danger),
        'in_progress' => StatusPill(
          label: l.tasksInProgress,
          tone: PillTone.accent,
        ),
        'draft' => StatusPill(label: l.tasksDraft, tone: PillTone.accent),
        'failed' => StatusPill(label: l.tasksRetry, tone: PillTone.danger),
        _ => const ForwardChevron(),
      },
    };
    return ResultRow(
      icon: itemIcon(t.type),
      title: t.title,
      meta: [t.courseTitle, ?when].join(context.sep),
      trailing: trailing,
      onTap: () => context.push(
        t.isQuiz
            ? '/course/${t.courseId}/quiz/${t.id}'
            : '/course/${t.courseId}/assignment/${t.id}',
      ),
    );
  }
}
