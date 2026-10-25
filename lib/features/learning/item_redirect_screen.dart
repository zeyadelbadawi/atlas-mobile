import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/learning_providers.dart';
import '../../app/ui_helpers.dart';
import '../../core/learning/learning_models.dart';
import '../../design/design.dart';
import 'course_widgets.dart';
import 'learning_ui.dart';

/// A link names an activity by id only (`/my/courses/:id/activities/:item`
/// in a notification). This finds what kind it is in the course and opens
/// the right screen in its place.
class ItemRedirectScreen extends ConsumerWidget {
  const ItemRedirectScreen({
    super.key,
    required this.courseId,
    required this.itemId,
  });
  final String courseId;
  final String itemId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seq = ref.watch(sequenceProvider(courseId));
    return Scaffold(
      appBar: AppBar(),
      body: AsyncBody<CourseSequence>(
        value: seq,
        onRetry: () => ref.invalidate(sequenceProvider(courseId)),
        data: (s) {
          final item = s.items.where((i) => i.id == itemId).firstOrNull;
          if (item == null) {
            return Padding(
              padding: const EdgeInsets.all(AtlasSpace.gutter),
              child: AtlasBanner(message: context.l10n.itemNotFound),
            );
          }
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) openItem(context, ref, s, item, replace: true);
          });
          return const Center(child: CircularProgressIndicator.adaptive());
        },
      ),
    );
  }
}
