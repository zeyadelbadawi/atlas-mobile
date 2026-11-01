import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/providers.dart';
import '../../core/api/api_error.dart';
import '../../design/design.dart';
import '../../app/ui_helpers.dart';
import '../../core/account/account_repository.dart';
import 'account_settings_screens.dart' show accountRepositoryProvider;

/* ------------------------------------------------------------- picking */

/// The phone's camera and photo library, behind an interface for tests.
abstract class PhotoPicker {
  /// The picked photo's bytes, or null when the learner backed out.
  Future<Uint8List?> pick({required bool camera});
}

class SystemPhotoPicker implements PhotoPicker {
  @override
  Future<Uint8List?> pick({required bool camera}) async {
    // Scaled down on the phone (and HEIC becomes JPEG): the crop needs no
    // more than this, and decoding a 48 MP photo would be slow.
    final x = await ImagePicker().pickImage(
      source: camera ? ImageSource.camera : ImageSource.gallery,
      preferredCameraDevice: CameraDevice.front,
      maxWidth: 2048,
      maxHeight: 2048,
      imageQuality: 90,
      requestFullMetadata: false,
    );
    return x?.readAsBytes();
  }
}

final photoPickerProvider = Provider<PhotoPicker>((_) => SystemPhotoPicker());

/* -------------------------------------------------------------- upload */

/// While a new photo uploads it shows at once from the phone, with a
/// spinner on it; a failed upload puts the previous one back.
@immutable
class PhotoUpload {
  const PhotoUpload({this.preview, this.busy = false});
  final Uint8List? preview;
  final bool busy;
}

class PhotoUploadController extends Notifier<PhotoUpload> {
  @override
  PhotoUpload build() => const PhotoUpload();

  Future<AtlasApiException?> upload(Uint8List square) => _run(
    PhotoUpload(preview: square, busy: true),
    () => ref
        .read(accountRepositoryProvider)
        .uploadAvatar(square, fileName: 'avatar.png'),
  );

  Future<AtlasApiException?> remove() => _run(
    const PhotoUpload(busy: true),
    () => ref.read(accountRepositoryProvider).removeAvatar(),
  );

  Future<AtlasApiException?> _run(
    PhotoUpload during,
    Future<AccountProfile> Function() call,
  ) async {
    if (state.busy) return null;
    state = during;
    try {
      final me = await call();
      ref.read(sessionProvider.notifier).signedIn(me.raw);
      return null;
    } on AtlasApiException catch (e) {
      return e;
    } finally {
      state = const PhotoUpload();
    }
  }
}

final photoUploadProvider =
    NotifierProvider<PhotoUploadController, PhotoUpload>(
      PhotoUploadController.new,
    );

/// The signed-in learner's photo on the academy's API host, or null.
final avatarUrlProvider = Provider<Uri?>((ref) {
  final s = ref.watch(sessionProvider);
  final path = s.user?['avatar'] as String?;
  final academy = s.academy;
  if (path == null || path.isEmpty || academy == null) return null;
  final uri = Uri.tryParse(path);
  if (uri == null) return null;
  return uri.hasScheme ? uri : academy.endpoint.origin.resolveUri(uri);
});

/// The photo to draw (tests serve one from memory).
final avatarImageProvider = Provider<ImageProvider?>((ref) {
  final url = ref.watch(avatarUrlProvider);
  return url == null ? null : NetworkImage(url.toString());
});

/* ------------------------------------------------------------- avatars */

/// Two Latin initials ("ZE"); one Arabic letter, because two Arabic letters
/// side by side read as a word.
String initialsOf(String name) {
  final words = name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
  if (words.isEmpty) return '';
  if (RegExp(r'[؀-ۿ]').hasMatch(words.first)) {
    return words.first.characters.first;
  }
  return words.take(2).map((w) => w.characters.first).join().toUpperCase();
}

/// A round photo, or the initials until (and unless) it loads.
class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.name,
    required this.size,
    required this.background,
    required this.foreground,
    this.image,
    this.preview,
    this.busy = false,
  });

  final String name;
  final double size;
  final Color background, foreground;
  final ImageProvider? image;
  final Uint8List? preview;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final a = context.atlas;
    final initials = Center(
      child: Text(
        initialsOf(name),
        style: (size >= 80 ? a.type.largeTitle : a.type.title2).copyWith(
          color: foreground,
          height: 1,
        ),
      ),
    );
    Widget photo;
    if (preview != null) {
      photo = Image.memory(preview!, fit: BoxFit.cover, gaplessPlayback: true);
    } else if (image != null) {
      photo = Image(
        image: image!,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        frameBuilder: (_, child, frame, sync) => sync
            ? child
            : AnimatedOpacity(
                opacity: frame == null ? 0 : 1,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                child: child,
              ),
        errorBuilder: (_, _, _) => const SizedBox.shrink(),
      );
    } else {
      photo = const SizedBox.shrink();
    }
    return SizedBox.square(
      dimension: size,
      child: ClipOval(
        child: ColoredBox(
          color: background,
          child: Stack(
            fit: StackFit.expand,
            children: [
              initials,
              photo,
              if (busy)
                ColoredBox(
                  color: Colors.black.withValues(alpha: 0.35),
                  child: const Center(
                    child: SizedBox.square(
                      dimension: 22,
                      child: CircularProgressIndicator.adaptive(
                        strokeWidth: 2.4,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The learner's own avatar with a camera badge; a tap changes the photo.
class EditableAvatar extends ConsumerWidget {
  const EditableAvatar({
    super.key,
    required this.name,
    required this.size,
    required this.background,
    required this.foreground,
    required this.ring,
  });

  final String name;
  final double size;
  final Color background, foreground;

  /// The badge's border: the colour behind the avatar.
  final Color ring;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.atlas.colors;
    final l = context.l10n;
    final image = ref.watch(avatarImageProvider);
    final upload = ref.watch(photoUploadProvider);
    final badge = (size * 0.36).clamp(24.0, 34.0);
    return Semantics(
      button: true,
      label: image == null ? l.photoAdd : l.photoChange,
      child: Pressable(
        onTap: upload.busy ? null : () => editProfilePhoto(context, ref),
        child: SizedBox.square(
          dimension: size,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              UserAvatar(
                name: name,
                size: size,
                background: background,
                foreground: foreground,
                image: image,
                preview: upload.preview,
                busy: upload.busy,
              ),
              PositionedDirectional(
                end: -2,
                bottom: -2,
                child: Container(
                  width: badge,
                  height: badge,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: c.button,
                    border: Border.all(color: ring, width: 2.5),
                  ),
                  child: Icon(
                    LucideIcons.camera,
                    size: badge * 0.48,
                    color: c.onButton,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/* ----------------------------------------------------------------- flow */

enum _PhotoAction { camera, library, remove }

/// Camera, photo library or remove → square crop → upload.
Future<void> editProfilePhoto(BuildContext context, WidgetRef ref) async {
  final l = context.l10n;
  final c = context.atlas.colors;
  final hasPhoto = ref.read(avatarImageProvider) != null;
  final action = await showModalBottomSheet<_PhotoAction>(
    context: context,
    showDragHandle: true,
    builder: (s) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
            child: Text(
              l.photoSheetTitle,
              style: s.atlas.type.headline.copyWith(color: c.ink),
            ),
          ),
          ListTile(
            leading: const Icon(LucideIcons.camera),
            title: Text(l.photoTake),
            onTap: () => Navigator.pop(s, _PhotoAction.camera),
          ),
          ListTile(
            leading: const Icon(LucideIcons.image),
            title: Text(l.photoChoose),
            onTap: () => Navigator.pop(s, _PhotoAction.library),
          ),
          if (hasPhoto)
            ListTile(
              leading: Icon(LucideIcons.trash2, color: c.danger),
              title: Text(l.photoRemove, style: TextStyle(color: c.danger)),
              onTap: () => Navigator.pop(s, _PhotoAction.remove),
            ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
  if (action == null || !context.mounted) return;
  final uploads = ref.read(photoUploadProvider.notifier);
  void fail(AtlasApiException? e) {
    if (e == null || !context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(e.status == 400 ? l.photoInvalid : l.photoFailed),
      ),
    );
  }

  if (action == _PhotoAction.remove) {
    fail(await uploads.remove());
    return;
  }
  Uint8List? picked;
  try {
    picked = await ref
        .read(photoPickerProvider)
        .pick(camera: action == _PhotoAction.camera);
  } on PlatformException {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(l.photoNoAccess),
        ),
      );
    }
    return;
  }
  if (picked == null || !context.mounted) return;
  final square = await Navigator.of(context).push<Uint8List>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => AvatarCropScreen(image: picked!),
    ),
  );
  if (square == null) return;
  unawaited(HapticFeedback.lightImpact());
  fail(await uploads.upload(square));
}

/* ----------------------------------------------------------------- crop */

/// Move and pinch the photo inside the circle; "Use photo" keeps exactly
/// what the circle shows, as a 640 x 640 PNG.
class AvatarCropScreen extends StatefulWidget {
  const AvatarCropScreen({super.key, required this.image});

  final Uint8List image;

  static const outputSize = 640;

  @override
  State<AvatarCropScreen> createState() => _AvatarCropScreenState();
}

class _AvatarCropScreenState extends State<AvatarCropScreen> {
  final _transform = TransformationController();
  ui.Image? _decoded;
  bool _failed = false;
  bool _saving = false;
  double _viewport = 0;

  @override
  void initState() {
    super.initState();
    unawaited(_decode());
  }

  Future<void> _decode() async {
    try {
      final codec = await ui.instantiateImageCodec(widget.image);
      final frame = await codec.getNextFrame();
      if (mounted) setState(() => _decoded = frame.image);
    } on Object {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  void dispose() {
    _transform.dispose();
    _decoded?.dispose();
    super.dispose();
  }

  /// The photo laid out to cover the square viewport at scale 1.
  Size _childSize(ui.Image img, double side) {
    final k = side / math.min(img.width, img.height);
    return Size(img.width * k, img.height * k);
  }

  Future<void> _use() async {
    final img = _decoded;
    if (img == null || _viewport == 0) return;
    setState(() => _saving = true);
    final child = _childSize(img, _viewport);
    final inverse = Matrix4.inverted(_transform.value);
    final tl = MatrixUtils.transformPoint(inverse, Offset.zero);
    final br = MatrixUtils.transformPoint(
      inverse,
      Offset(_viewport, _viewport),
    );
    final k = img.width / child.width;
    final src = Rect.fromPoints(tl * k, br * k);
    const out = AvatarCropScreen.outputSize;
    final recorder = ui.PictureRecorder();
    Canvas(recorder).drawImageRect(
      img,
      src,
      const Rect.fromLTWH(0, 0, out + 0.0, out + 0.0),
      Paint()..filterQuality = FilterQuality.high,
    );
    final cropped = await recorder.endRecording().toImage(out, out);
    final png = await cropped.toByteData(format: ui.ImageByteFormat.png);
    cropped.dispose();
    if (!mounted) return;
    Navigator.pop(context, png?.buffer.asUint8List());
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final a = context.atlas;
    final img = _decoded;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                child: Row(
                  children: [
                    TextButton(
                      onPressed: _saving ? null : () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                      ),
                      child: Text(l.commonCancel),
                    ),
                    Expanded(
                      child: Text(
                        l.photoCropTitle,
                        textAlign: TextAlign.center,
                        style: a.type.headline.copyWith(color: Colors.white),
                      ),
                    ),
                    TextButton(
                      key: const Key('photo-use'),
                      onPressed: img == null || _saving ? null : _use,
                      style: TextButton.styleFrom(
                        foregroundColor: a.colors.gold,
                        textStyle: a.type.headline,
                      ),
                      child: Text(l.photoUse),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, box) {
                    final side = math.min(box.maxWidth, box.maxHeight) - 32;
                    _viewport = side;
                    if (_failed) {
                      return Center(
                        child: Text(
                          l.photoInvalid,
                          style: a.type.body.copyWith(color: Colors.white70),
                        ),
                      );
                    }
                    if (img == null) {
                      return const Center(
                        child: CircularProgressIndicator.adaptive(
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      );
                    }
                    final child = _childSize(img, side);
                    return Center(
                      child: SizedBox.square(
                        dimension: side,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Positioned.fill(
                              child: InteractiveViewer(
                                transformationController: _transform,
                                minScale: 1,
                                maxScale: 5,
                                constrained: false,
                                clipBehavior: Clip.none,
                                child: SizedBox.fromSize(
                                  size: child,
                                  child: RawImage(image: img, fit: BoxFit.fill),
                                ),
                              ),
                            ),
                            const Positioned.fill(
                              child: IgnorePointer(
                                child: CustomPaint(painter: _CircleMask()),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: Text(
                  l.photoCropHint,
                  textAlign: TextAlign.center,
                  style: a.type.subhead.copyWith(color: Colors.white70),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Dims everything outside the circle, far enough out to cover the photo
/// overflowing the square.
class _CircleMask extends CustomPainter {
  const _CircleMask();

  @override
  void paint(Canvas canvas, Size size) {
    final circle = Rect.fromLTWH(0, 0, size.width, size.height);
    final outside = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(circle.inflate(2000))
      ..addOval(circle);
    canvas.drawPath(
      outside,
      Paint()..color = Colors.black.withValues(alpha: 0.62),
    );
    canvas.drawOval(
      circle.deflate(0.75),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = Colors.white.withValues(alpha: 0.9),
    );
  }

  @override
  bool shouldRepaint(_CircleMask oldDelegate) => false;
}
