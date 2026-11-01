import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:atlas_mobile/app/providers.dart';
import 'package:atlas_mobile/core/api/api_error.dart';
import 'package:atlas_mobile/features/account/profile_photo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_notifications.dart';
import 'screen_harness.dart';

const _path =
    '/api/v1/public/media/users/avatars/0b8f3c1e-2d4a-4f6b-9c7d-1e2f3a4b5c6d.webp';

class AsSignedInWithPhoto extends SessionController {
  @override
  SessionState build() => const SessionState(
    status: SessionStatus.signedIn,
    academy: ziadd,
    user: {...FakeAccountRepository.learner, 'avatar': _path},
  );
}

Future<void> settle(WidgetTester t) async {
  for (var i = 0; i < 6; i++) {
    await t.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 60)),
    );
    await t.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  final photo = File('test/fixtures/demo_logo.png').readAsBytesSync();

  test('initials: two Latin letters, one Arabic letter', () {
    expect(initialsOf('Zeyad Elbadawi'), 'ZE');
    expect(initialsOf('زياد البدوي'), 'ز');
    expect(initialsOf('  '), '');
  });

  test('a site-relative photo path is on the academy host', () {
    final c = ProviderContainer(
      overrides: [sessionProvider.overrideWith(AsSignedInWithPhoto.new)],
    );
    addTearDown(c.dispose);
    expect(
      c.read(avatarUrlProvider).toString(),
      'https://ziadd.atlass.dpdns.org$_path',
    );
  });

  testWidgets('choose a photo, crop it, and it becomes the account photo', (
    t,
  ) async {
    final account = FakeAccountRepository();
    final picker = FakePhotoPicker(photo);
    final container = await pumpScreen(
      t,
      session: AsSignedIn.new,
      path: '/account/profile',
      account: account,
      photoPicker: picker,
    );
    await t.tap(find.byKey(const Key('photo-edit')));
    await t.pumpAndSettle();
    expect(find.text('التقاط صورة'), findsOneWidget);
    // No photo yet: nothing to remove.
    expect(find.text('إزالة الصورة'), findsNothing);
    await t.tap(find.text('اختيار من الصور'));
    await settle(t);
    expect(picker.camera, isFalse);
    expect(find.text('تحريك وتكبير'), findsOneWidget);

    await t.tap(find.byKey(const Key('photo-use')));
    await settle(t);
    await t.pump(const Duration(seconds: 1));

    final png = account.uploaded!;
    final codec = await t.runAsync(() => ui.instantiateImageCodec(png));
    final img = (await t.runAsync(() => codec!.getNextFrame()))!.image;
    expect([img.width, img.height], [640, 640]);
    expect(container.read(sessionProvider).user?['avatar'], _path);
  });

  testWidgets('remove the photo: the initials come back', (t) async {
    final account = FakeAccountRepository();
    final container = await pumpScreen(
      t,
      session: AsSignedInWithPhoto.new,
      path: '/account/profile',
      account: account,
      avatar: MemoryImage(Uint8List.fromList(photo)),
    );
    await t.tap(find.byKey(const Key('photo-edit')));
    await t.pumpAndSettle();
    await t.tap(find.text('إزالة الصورة'));
    await t.pumpAndSettle();
    expect(account.removed, isTrue);
    expect(container.read(sessionProvider).user?['avatar'], isNull);
  });

  testWidgets('a failed upload says so and keeps the account as it was', (
    t,
  ) async {
    final account = FakeAccountRepository()
      ..failUpload = const AtlasApiException(
        kind: 'network',
        messageKey: 'errors.network',
      );
    final container = await pumpScreen(
      t,
      session: AsSignedIn.new,
      path: '/account/profile',
      account: account,
      photoPicker: FakePhotoPicker(photo),
    );
    await t.tap(find.byKey(const Key('photo-edit')));
    await t.pumpAndSettle();
    await t.tap(find.text('التقاط صورة'));
    await settle(t);
    await t.tap(find.byKey(const Key('photo-use')));
    await settle(t);
    await t.pump(const Duration(seconds: 1));
    expect(find.textContaining('تعذّر تحديث صورتك'), findsOneWidget);
    expect(container.read(sessionProvider).user?['avatar'], isNull);
  });
}
