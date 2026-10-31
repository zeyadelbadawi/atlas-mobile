import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/learning_providers.dart';
import '../../app/ui_helpers.dart';
import '../../core/learning/catalog_repository.dart';
import '../../design/design.dart';
import '../learning/learning_ui.dart';

/// The academy's free courses: search, page through, open one to preview
/// and join it. Paid courses are not listed (nothing is sold in the app).
class CatalogScreen extends ConsumerStatefulWidget {
  const CatalogScreen({super.key});

  @override
  ConsumerState<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends ConsumerState<CatalogScreen> {
  final _search = TextEditingController();
  Timer? _debounce;
  final _items = <CatalogCourse>[];
  Set<String> _enrolled = const {};
  int _page = 0;
  bool _hasMore = true;
  bool _loading = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    _items.clear();
    _page = 0;
    _hasMore = true;
    try {
      final list = await ref.read(enrollmentsProvider.future);
      _enrolled = {for (final e in list) e.courseId};
    } on Object {
      _enrolled = const {};
    }
    await _more();
  }

  Future<void> _more() async {
    if (_loading || !_hasMore) return;
    final query = _search.text;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await ref
          .read(catalogRepositoryProvider)
          .freeCourses(page: _page + 1, search: query);
      if (!mounted || query != _search.text) return;
      setState(() {
        _page++;
        _items.addAll(page.items.where((c) => c.isFree));
        _hasMore = page.hasMore;
      });
    } on Object catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onSearch(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      setState(_items.clear);
      _reload();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final a = context.atlas;
    final searching = _search.text.trim().isNotEmpty;
    return Scaffold(
      appBar: AppBar(),
      body: RefreshIndicator.adaptive(
        onRefresh: _reload,
        child: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
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
                      l.catalogTitle,
                      style: a.type.title1.copyWith(color: a.colors.ink),
                    ),
                  ),
                  const SizedBox(height: AtlasSpace.s12),
                  AtlasTextField(
                    label: l.catalogSearch,
                    controller: _search,
                    textInputAction: TextInputAction.search,
                    prefix: Icon(
                      LucideIcons.search,
                      size: 18,
                      color: a.colors.inkSecondary,
                    ),
                    onChanged: _onSearch,
                  ),
                  const SizedBox(height: AtlasSpace.s8),
                  for (final (i, c) in _items.indexed)
                    Entrance(
                      key: ValueKey(c.id),
                      order: i % 20,
                      child: CatalogCourseRow(
                        course: c,
                        number: i + 1,
                        joined: _enrolled.contains(c.id),
                      ),
                    ),
                  if (_error != null && _items.isEmpty)
                    LoadError(
                      message: errorText(ref, context, _error!),
                      onRetry: _reload,
                    )
                  else if (_loading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Center(
                        child: CircularProgressIndicator.adaptive(),
                      ),
                    )
                  else if (_items.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Text(
                        searching ? l.catalogNoResults : l.catalogEmpty,
                        textAlign: TextAlign.center,
                        style: a.type.body.copyWith(
                          color: a.colors.inkSecondary,
                        ),
                      ),
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
      ),
    );
  }
}

class CatalogCourseRow extends StatelessWidget {
  const CatalogCourseRow({
    super.key,
    required this.course,
    required this.number,
    this.joined = false,
  });

  final CatalogCourse course;
  final int number;
  final bool joined;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return CourseRow(
      title: course.title,
      subtitle: [
        if (course.instructors.isNotEmpty) course.instructors.join(context.sep),
        l.lessonsCount(
          course.totalLessons,
          context.digits('${course.totalLessons}'),
        ),
      ].join(context.sep),
      cover: CourseCover(
        image: course.thumbnailUrl == null
            ? null
            : NetworkImage(course.thumbnailUrl!),
        kicker: l.coursesCover,
        mark: context.digits(number.toString().padLeft(2, '0')),
      ),
      status: joined ? l.catalogJoined : l.catalogFree,
      onTap: () => context.push('/catalog/${course.id}'),
    );
  }
}

/// The catalog's way in from Home and My courses.
class BrowseFreeCoursesCard extends StatelessWidget {
  const BrowseFreeCoursesCard({super.key, required this.academyName});
  final String academyName;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final a = context.atlas;
    return MergeSemantics(
      child: Pressable(
        onTap: () => context.push('/catalog'),
        child: Container(
          padding: const EdgeInsets.all(AtlasSpace.s16),
          decoration: BoxDecoration(
            color: a.colors.tonal,
            borderRadius: BorderRadius.circular(AtlasRadius.lg),
          ),
          child: Row(
            children: [
              Icon(LucideIcons.compass, color: a.colors.accent),
              const SizedBox(width: AtlasSpace.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.catalogBrowse,
                      style: a.type.headline.copyWith(color: a.colors.ink),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l.catalogBrowseBody(academyName),
                      style: a.type.subhead.copyWith(
                        color: a.colors.inkSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const ForwardChevron(),
            ],
          ),
        ),
      ),
    );
  }
}
