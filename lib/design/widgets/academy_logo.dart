import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import "../atlas_theme.dart";

/// The academy's logo on a tile chosen so the logo always reads: academy
/// logos are often transparent PNGs drawn in one colour, and a yellow logo
/// on the academy's own yellow, or a white logo on a white card, vanishes.
/// Once the logo has loaded, its own colours pick the tile that contrasts
/// with it most: white, or Atlas's darkest navy (yellow and white logos). Without a logo (or if it fails),
/// the first letter of the academy name on [background].
class AcademyLogo extends StatefulWidget {
  const AcademyLogo({
    super.key,
    required this.academyName,
    this.image,
    this.size = 40,
    this.background,
  });

  final String academyName;
  final ImageProvider? image;
  final double size;

  /// For the first-letter tile. Defaults to raised; the picker uses the
  /// academy cover colour.
  final Color? background;

  /// Per logo: true when it reads better on the dark tile than on white.
  @visibleForTesting
  static final lightLogo = <Object, bool>{};

  @override
  State<AcademyLogo> createState() => _AcademyLogoState();
}

class _AcademyLogoState extends State<AcademyLogo> {
  ImageStream? _stream;
  ImageStreamListener? _listener;
  bool? _light;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolve();
  }

  @override
  void didUpdateWidget(AcademyLogo old) {
    super.didUpdateWidget(old);
    if (old.image != widget.image) _resolve();
  }

  void _resolve() {
    final image = widget.image;
    if (image == null) return;
    final known = AcademyLogo.lightLogo[image];
    if (known != null) {
      _light = known;
      return;
    }
    final stream = image.resolve(createLocalImageConfiguration(context));
    if (stream.key == _stream?.key) return;
    _stop();
    _stream = stream;
    _listener = ImageStreamListener(
      (info, _) => unawaited(_measure(image, info.image.clone())),
      onError: (_, _) {},
    );
    stream.addListener(_listener!);
  }

  /// The logo's average visible colour (a sample of its pixels), then the
  /// tile that contrasts with it most: white or Atlas's darkest navy.
  Future<void> _measure(ImageProvider key, ui.Image img) async {
    try {
      final data = await img.toByteData();
      if (data == null) return;
      var r = 0, g = 0, b = 0, count = 0;
      final step = (data.lengthInBytes ~/ 4 ~/ 4000).clamp(1, 1 << 20) * 4;
      for (var i = 0; i + 3 < data.lengthInBytes; i += step) {
        if (data.getUint8(i + 3) < 128) continue; // transparent
        r += data.getUint8(i);
        g += data.getUint8(i + 1);
        b += data.getUint8(i + 2);
        count++;
      }
      // A logo with no visible pixels: keep white.
      var light = false;
      if (count > 0) {
        final avg = Color.fromARGB(255, r ~/ count, g ~/ count, b ~/ count);
        light =
            AcademyPalette.contrast(avg, AtlasBrand.navy900) >
            AcademyPalette.contrast(avg, AcademyPalette.white);
      }
      AcademyLogo.lightLogo[key] = light;
      if (mounted) setState(() => _light = light);
    } finally {
      img.dispose();
    }
  }

  void _stop() {
    if (_listener != null) _stream?.removeListener(_listener!);
    _stream = null;
    _listener = null;
  }

  @override
  void dispose() {
    _stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final a = context.atlas;
    final c = a.colors;
    final size = widget.size;
    final bg = widget.background ?? c.raised;
    final fg =
        AcademyPalette.contrast(AcademyPalette.white, bg) >=
            AcademyPalette.contrast(AcademyPalette.ink, bg)
        ? AcademyPalette.white
        : AcademyPalette.ink;
    final name = widget.academyName.trim();
    final letter = name.isEmpty ? '·' : String.fromCharCode(name.runes.first);
    final radius = BorderRadius.circular(size * 0.26);

    Widget letterTile() => Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: bg, borderRadius: radius),
      child: Text(
        letter.toUpperCase(),
        style: a.type.title2.copyWith(
          color: fg,
          fontSize: size * 0.45,
          height: 1,
          fontWeight: FontWeight.w700,
        ),
      ),
    );

    final image = widget.image;
    if (image == null) {
      return Semantics(
        image: true,
        label: widget.academyName,
        child: letterTile(),
      );
    }
    final dark = _light ?? false;
    return Semantics(
      image: true,
      label: widget.academyName,
      child: AnimatedContainer(
        duration: AtlasMotion.quick,
        width: size,
        height: size,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: dark ? AtlasBrand.navy900 : AcademyPalette.white,
          borderRadius: radius,
          border: Border.all(
            color: dark ? const Color(0x33FFFFFF) : const Color(0x1A000000),
          ),
        ),
        child: Image(
          // Decoded at the size it is drawn (logos are small here).
          image: ResizeImage.resizeIfNeeded(
            (size * MediaQuery.devicePixelRatioOf(context)).round(),
            null,
            image,
          ),
          fit: BoxFit.contain,
          frameBuilder: (context, child, frame, sync) =>
              Padding(padding: EdgeInsets.all(size * 0.12), child: child),
          errorBuilder: (context, _, _) => letterTile(),
        ),
      ),
    );
  }
}
