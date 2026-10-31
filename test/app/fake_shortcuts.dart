import 'package:atlas_mobile/app/shortcuts.dart';

/// Records the app icon's shortcuts instead of setting them.
class FakeShortcuts implements AppShortcuts {
  List<AppShortcut> items = const [];
  void Function(String path)? open;

  @override
  void listen(void Function(String path) onOpen) => open = onOpen;

  @override
  Future<void> set(List<AppShortcut> items) async => this.items = items;
}
