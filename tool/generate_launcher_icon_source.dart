import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart' as image;

const _defaultInputPath = 'assets/logo.png';
const _defaultOutputPath = 'assets/icons/launcher_icon_source.png';
const _canvasSize = 1024;
const _contentScale = 0.66;

void main(List<String> args) {
  final inputPath = args.isNotEmpty ? args[0] : _defaultInputPath;
  final outputPath = args.length > 1 ? args[1] : _defaultOutputPath;

  final inputFile = File(inputPath);
  if (!inputFile.existsSync()) {
    stderr.writeln('Launcher icon source not found: $inputPath');
    exitCode = 1;
    return;
  }

  final decoded = image.decodeImage(inputFile.readAsBytesSync());
  if (decoded == null) {
    stderr.writeln('Could not decode launcher icon source: $inputPath');
    exitCode = 1;
    return;
  }

  final source = image.bakeOrientation(decoded);
  final contentBox = (_canvasSize * _contentScale).round();
  final scale = math.min(
    contentBox / source.width,
    contentBox / source.height,
  );
  final iconWidth = math.max(1, (source.width * scale).round());
  final iconHeight = math.max(1, (source.height * scale).round());
  final resized = image.copyResize(
    source,
    width: iconWidth,
    height: iconHeight,
    interpolation: image.Interpolation.cubic,
  );

  final canvas = image.Image(
    width: _canvasSize,
    height: _canvasSize,
    numChannels: 4,
  )..clear(image.ColorRgba8(0, 0, 0, 0));

  image.compositeImage(
    canvas,
    resized,
    dstX: (_canvasSize - iconWidth) ~/ 2,
    dstY: (_canvasSize - iconHeight) ~/ 2,
    blend: image.BlendMode.alpha,
  );

  final outputFile = File(outputPath);
  outputFile.parent.createSync(recursive: true);
  outputFile.writeAsBytesSync(image.encodePng(canvas, level: 9));

  stdout.writeln(
    'Generated $outputPath from $inputPath '
    '(${source.width}x${source.height} -> '
    '${iconWidth}x$iconHeight on ${_canvasSize}x$_canvasSize).',
  );
}
