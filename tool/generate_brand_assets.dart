import 'dart:io';
import 'dart:math';

import 'package:image/image.dart';

/// Pads a wide logo into a square canvas so launcher/splash don't stretch it.
Future<void> padLogo({
  required String input,
  required String output,
  required double scale,
  List<int>? backgroundRgb,
  bool transparent = false,
}) async {
  final src = decodeImage(await File(input).readAsBytes());
  if (src == null) {
    throw StateError('Could not decode $input');
  }

  final side = max(src.width, src.height);
  final canvas = Image(width: side, height: side, numChannels: transparent ? 4 : 3);

  if (transparent) {
    fill(canvas, color: ColorRgba8(0, 0, 0, 0));
  } else {
    final bg = backgroundRgb ?? [0, 0, 0];
    fill(canvas, color: ColorRgb8(bg[0], bg[1], bg[2]));
  }

  final logoWidth = (side * scale).round();
  final logoHeight = (src.height * logoWidth / src.width).round();
  final resized = copyResize(src, width: logoWidth, height: logoHeight);

  compositeImage(
    canvas,
    resized,
    dstX: (side - logoWidth) ~/ 2,
    dstY: (side - logoHeight) ~/ 2,
  );

  await File(output).writeAsBytes(encodePng(canvas));
  stdout.writeln('Wrote $output (${side}x$side, scale=$scale)');
}

Future<void> main() async {
  await padLogo(
    input: 'assets/images/elmogps.png',
    output: 'assets/images/elmogps_launcher.png',
    scale: 0.76,
    backgroundRgb: [255, 255, 255],
  );

  await padLogo(
    input: 'assets/images/elmo-02.png',
    output: 'assets/images/elmo-02_splash.png',
    scale: 0.62,
    transparent: true,
  );
}
