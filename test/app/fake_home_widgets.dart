import 'dart:async';

import 'package:atlas_mobile/app/home_widgets.dart';

/// Records what the app writes to its home-screen widget.
class FakeHomeWidgets implements HomeWidgets {
  FakeHomeWidgets({this.launch});
  final String? launch;
  Map<String, Object?> data = const {};
  int saves = 0;
  // Closed with the test process; a fake.
  // ignore: close_sinks
  final tapped = StreamController<String>.broadcast();

  @override
  Future<void> save(Map<String, Object?> d) async {
    data = d;
    saves++;
  }

  @override
  Stream<String> get taps => tapped.stream;

  @override
  Future<String?> launchPath() async => launch;
}
