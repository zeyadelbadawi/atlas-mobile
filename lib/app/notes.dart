import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/clock.dart';
import 'providers.dart';

/// A lesson the learner saved, wrote a note on, or both.
@immutable
class LessonNote {
  const LessonNote({
    required this.courseId,
    required this.lessonId,
    required this.courseTitle,
    required this.lessonTitle,
    required this.updatedAt,
    this.note = '',
    this.saved = false,
  });

  factory LessonNote.fromJson(Map<String, dynamic> j) => LessonNote(
    courseId: j['courseId'] as String,
    lessonId: j['lessonId'] as String,
    courseTitle: j['courseTitle'] as String? ?? '',
    lessonTitle: j['lessonTitle'] as String? ?? '',
    note: j['note'] as String? ?? '',
    saved: j['saved'] == true,
    updatedAt:
        DateTime.tryParse(j['updatedAt'] as String? ?? '') ?? DateTime(2000),
  );

  final String courseId;
  final String lessonId;
  final String courseTitle;
  final String lessonTitle;
  final String note;

  /// Kept to come back to (the learner's own list, not the course's place).
  final bool saved;
  final DateTime updatedAt;

  bool get isEmpty => note.trim().isEmpty && !saved;

  LessonNote copyWith({String? note, bool? saved}) => LessonNote(
    courseId: courseId,
    lessonId: lessonId,
    courseTitle: courseTitle,
    lessonTitle: lessonTitle,
    note: note ?? this.note,
    saved: saved ?? this.saved,
    updatedAt: clockNow(),
  );

  Map<String, Object> toJson() => {
    'courseId': courseId,
    'lessonId': lessonId,
    'courseTitle': courseTitle,
    'lessonTitle': lessonTitle,
    'note': note,
    'saved': saved,
    'updatedAt': updatedAt.toIso8601String(),
  };
}

/// Notes and saved lessons, on this phone only (no server for them yet),
/// per account and academy. Newest first.
class NotesController extends Notifier<List<LessonNote>> {
  static const prefix = 'notes.';
  String? _key;

  @override
  List<LessonNote> build() {
    final who = ref.watch(
      sessionProvider.select(
        (s) => s.status == SessionStatus.signedIn
            ? (s.academy?.id, s.user?['id'])
            : null,
      ),
    );
    _key = who == null || who.$1 == null || who.$2 == null
        ? null
        : '$prefix${who.$1}.${who.$2}';
    if (_key == null) return const [];
    final raw = ref.read(sharedPreferencesProvider).getString(_key!);
    if (raw == null) return const [];
    try {
      return _sorted([
        for (final m in (jsonDecode(raw) as List).whereType<Map>())
          LessonNote.fromJson(Map<String, dynamic>.from(m)),
      ]);
    } on Object {
      return const [];
    }
  }

  LessonNote? of(String lessonId) =>
      state.where((n) => n.lessonId == lessonId).firstOrNull;

  /// Saves (or clears, when empty) what the learner keeps on a lesson.
  Future<void> put(LessonNote note) async {
    final rest = state.where((n) => n.lessonId != note.lessonId);
    final next = _sorted([if (!note.isEmpty) note, ...rest]);
    state = next;
    final key = _key;
    if (key == null) return;
    final prefs = ref.read(sharedPreferencesProvider);
    next.isEmpty
        ? await prefs.remove(key)
        : await prefs.setString(
            key,
            jsonEncode([for (final n in next) n.toJson()]),
          );
  }

  static List<LessonNote> _sorted(List<LessonNote> notes) => List.unmodifiable(
    notes..sort((a, b) => b.updatedAt.compareTo(a.updatedAt)),
  );
}

final notesProvider = NotifierProvider<NotesController, List<LessonNote>>(
  NotesController.new,
);
