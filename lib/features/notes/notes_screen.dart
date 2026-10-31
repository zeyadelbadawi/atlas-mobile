import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/notes.dart';
import '../../app/ui_helpers.dart';
import '../../design/design.dart';
import '../learning/learning_ui.dart';

/// The lessons the learner saved or wrote notes on, newest first. A tap
/// opens the lesson.
class NotesScreen extends ConsumerWidget {
  const NotesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final a = context.atlas;
    final c = a.colors;
    final notes = ref.watch(notesProvider);
    return ScrollTitleScaffold(
      title: l.notesTitle,
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
                  child: Text(
                    l.notesTitle,
                    style: a.type.title1.copyWith(color: c.ink),
                  ),
                ),
                const SizedBox(height: AtlasSpace.s16),
                if (notes.isEmpty)
                  EmptyState(
                    icon: LucideIcons.notebookPen,
                    title: l.notesEmptyTitle,
                    body: l.notesEmptyBody,
                  )
                else ...[
                  for (final n in notes) _NoteRow(note: n),
                  const SizedBox(height: AtlasSpace.s16),
                  Text(
                    l.notesOnPhone,
                    style: a.type.footnote.copyWith(color: c.inkTertiary),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NoteRow extends StatelessWidget {
  const _NoteRow({required this.note});
  final LessonNote note;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final a = context.atlas;
    final c = a.colors;
    final text = note.note.trim();
    return MergeSemantics(
      child: Pressable(
        scale: 0.99,
        onTap: () =>
            context.push('/course/${note.courseId}/lesson/${note.lessonId}'),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: c.rule)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconTile(
                icon: note.saved && text.isEmpty
                    ? LucideIcons.bookmarkCheck
                    : LucideIcons.notebookPen,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      note.lessonTitle,
                      textDirection: contentDirection(
                        context,
                        note.lessonTitle,
                      ),
                      style: a.type.headline.copyWith(color: c.ink),
                    ),
                    Text(
                      [
                        note.courseTitle,
                        if (note.saved) l.notesSaved,
                        shortDate(context, note.updatedAt),
                      ].join(context.sep),
                      style: a.type.footnote.copyWith(color: c.inkSecondary),
                    ),
                    if (text.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        text,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        textDirection: contentDirection(context, text),
                        style: a.type.subhead.copyWith(color: c.ink),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const ForwardChevron(),
            ],
          ),
        ),
      ),
    );
  }
}
