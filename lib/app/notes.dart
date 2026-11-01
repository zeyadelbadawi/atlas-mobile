import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api/api_error.dart';
import '../core/clock.dart';
import '../core/learning/learning_models.dart';
import 'learning_providers.dart';
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

/// Notes and saved lessons, per account and academy, newest first. Kept on
/// the phone (they work offline) and synced with the server so they follow
/// the learner to another phone: every change is queued and sent, and
/// [sync] takes the other phones' newer edits. Last edit wins.
class NotesController extends Notifier<List<LessonNote>> {
  static const prefix = 'notes.';
  static const pendingPrefix = 'notes.pending.';
  String? _key;
  String? _pendingKey;
  bool _flushing = false;

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
    _pendingKey = _key == null
        ? null
        : '$pendingPrefix${_key!.substring(prefix.length)}';
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

  /// Saves (or clears, when empty) what the learner keeps on a lesson, and
  /// sends it to the server (queued while offline).
  Future<void> put(LessonNote note) async {
    await _store([if (!note.isEmpty) note, ..._without(note.lessonId)]);
    await _queue(note);
    unawaited(_flush());
  }

  Iterable<LessonNote> _without(String lessonId) =>
      state.where((n) => n.lessonId != lessonId);

  Future<void> _store(List<LessonNote> notes) async {
    final next = _sorted(notes);
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

  /// Edits not yet on the server (an empty one is a deletion), by lesson.
  Map<String, LessonNote> _pending() {
    final key = _pendingKey;
    final raw = key == null
        ? null
        : ref.read(sharedPreferencesProvider).getString(key);
    if (raw == null) return {};
    try {
      return {
        for (final m in (jsonDecode(raw) as List).whereType<Map>())
          m['lessonId'] as String: LessonNote.fromJson(
            Map<String, dynamic>.from(m),
          ),
      };
    } on Object {
      return {};
    }
  }

  Future<void> _savePending(Map<String, LessonNote> pending) async {
    final key = _pendingKey;
    if (key == null) return;
    final prefs = ref.read(sharedPreferencesProvider);
    pending.isEmpty
        ? await prefs.remove(key)
        : await prefs.setString(
            key,
            jsonEncode([for (final n in pending.values) n.toJson()]),
          );
  }

  Future<void> _queue(LessonNote note) =>
      _savePending({..._pending(), note.lessonId: note});

  /// Sends the queued edits. Stops quietly when offline (retried on the
  /// next sync) or when the server does not keep notes (older server).
  Future<void> _flush() async {
    if (_flushing) return;
    _flushing = true;
    try {
      final repo = ref.read(learningRepositoryProvider);
      for (final n in _pending().values) {
        try {
          await repo.putNote(
            courseId: n.courseId,
            lessonId: n.lessonId,
            note: n.note,
            saved: n.saved,
            editedAt: n.updatedAt,
          );
        } on AtlasApiException catch (e) {
          // 404: the lesson is gone or the server has no notes yet; 400:
          // refused. Neither gets better by retrying.
          if (e.status != 404 && e.status != 400) return;
        }
        await _savePending(_pending()..remove(n.lessonId));
      }
    } on Object catch (e) {
      debugPrint('notes flush: $e');
    } finally {
      _flushing = false;
    }
  }

  /// Sends what is queued, then takes the server's newer edits; a note on
  /// this phone the server has never seen (kept before sync existed) is
  /// sent too.
  Future<void> sync() async {
    if (_key == null) return;
    await _flush();
    final List<ServerNote> server;
    try {
      server = await ref.read(learningRepositoryProvider).notes();
    } on Object {
      return; // Offline, or a server without notes: the phone's copy stands.
    }
    if (_key == null) return;
    final pending = _pending();
    final local = {for (final n in state) n.lessonId: n};
    final onServer = <String>{};
    for (final s in server) {
      onServer.add(s.lessonId);
      if (pending.containsKey(s.lessonId)) continue;
      final mine = local[s.lessonId];
      if (mine != null && !s.editedAt.isAfter(mine.updatedAt)) continue;
      final note = LessonNote(
        courseId: s.courseId,
        lessonId: s.lessonId,
        courseTitle: s.courseTitle.isEmpty
            ? (mine?.courseTitle ?? '')
            : s.courseTitle,
        lessonTitle: s.lessonTitle.isEmpty
            ? (mine?.lessonTitle ?? '')
            : s.lessonTitle,
        note: s.note,
        saved: s.saved,
        updatedAt: s.editedAt,
      );
      if (note.isEmpty) {
        local.remove(s.lessonId);
      } else {
        local[s.lessonId] = note;
      }
    }
    await _store(local.values.toList());
    final unsent = state.where((n) => !onServer.contains(n.lessonId));
    if (unsent.isNotEmpty) {
      await _savePending({...pending, for (final n in unsent) n.lessonId: n});
      await _flush();
    }
  }

  static List<LessonNote> _sorted(List<LessonNote> notes) => List.unmodifiable(
    notes..sort((a, b) => b.updatedAt.compareTo(a.updatedAt)),
  );
}

final notesProvider = NotifierProvider<NotesController, List<LessonNote>>(
  NotesController.new,
);
