import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

void main() {
  runApp(MaterialApp(home: const MyApp()));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with SingleTickerProviderStateMixin {
  ui.Image? dash;
  ui.Image? robin;
  int time = 0;
  Ticker? ticker;

  @override
  void initState() {
    super.initState();
    setup();
    ticker = createTicker((Duration _) {
      setState(() {
        time++;
      });
    });
    ticker!.start();
  }

  @override
  dispose() {
    ticker?.dispose();
    super.dispose();
  }

  Future<void> setup() async {
    var dashBuffer = await ui.ImmutableBuffer.fromAsset('assets/dash.png');
    var robinBuffer = await ui.ImmutableBuffer.fromAsset('assets/robin.png');
    var dashCodec = await ui.instantiateImageCodecFromBuffer(dashBuffer);
    var robinCodec = await ui.instantiateImageCodecFromBuffer(robinBuffer);
    var dashFrame = await dashCodec.getNextFrame();
    var robinFrame = await robinCodec.getNextFrame();
    if (!mounted) {
      return;
    }
    setState(() {
      dash = dashFrame.image;
      robin = robinFrame.image;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (dash == null || robin == null) {
      return Center(child: Text('Loading...'));
    }
    return Column(
      children: [
        Center(
          child: CustomPaint(
            painter: PathPainter(dash!, robin!, time),
            size: Size(800, 600),
          ),
        ),
        LinearProgressIndicator(),
      ],
    );
  }
}

class GamePainter extends CustomPainter {
  GamePainter(this.dash, this.robin);

  final ui.Image robin;
  final ui.Image dash;

  @override
  void paint(ui.Canvas canvas, ui.Size size) {
    var random = Random();
    var paint = Paint();
    // 1, 10, 100, 1000, 10,000
    for (int i = 0; i < 5_000; i++) {
      var x = random.nextDouble() * size.width;
      var y = random.nextDouble() * size.height;
      canvas.drawImage(dash, Offset(x, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

class AtlasGamePainter extends CustomPainter {
  AtlasGamePainter(this.dash, this.robin);

  final ui.Image robin;
  final ui.Image dash;

  @override
  void paint(ui.Canvas canvas, ui.Size size) {
    var random = Random();
    var paint = Paint();
    var rect =
        Offset.zero & Size(dash.width.toDouble(), dash.height.toDouble());
    var count = 5_000;
    canvas.drawAtlas(
      dash,
      [
        for (int i = 0; i < count; i++)
          RSTransform.fromComponents(
            rotation: 0,
            scale: 1,
            anchorX: 0,
            anchorY: 0,
            translateX: random.nextDouble() * size.width,
            translateY: random.nextDouble() * size.height,
          ),
      ],
      [for (int i = 0; i < count; i++) rect],
      null,
      BlendMode.srcOver,
      null,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

///////

class GamePainterBig extends CustomPainter {
  GamePainterBig(this.dash, this.robin);

  final ui.Image robin;
  final ui.Image dash;

  @override
  void paint(ui.Canvas canvas, ui.Size size) {
    var random = Random();
    var paint = Paint();
    canvas.save();
    canvas.scale(4);
    canvas.drawAtlas(
      dash,
      [
        for (int i = 0; i < 2000; i++)
          RSTransform.fromComponents(
            rotation: 0,
            scale: 1,
            anchorX: 0,
            anchorY: 0,
            translateX: random.nextDouble() * size.width / 5,
            translateY: random.nextDouble() * size.height / 5,
          ),
      ],
      [
        for (int i = 0; i < 2000; i++)
          Offset.zero & Size(dash.width.toDouble(), dash.height.toDouble()),
      ],
      null,
      BlendMode.srcOver,
      null,
      paint,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

////

class FilterGamePainter extends CustomPainter {
  FilterGamePainter(this.dash, this.robin);

  final ui.Image robin;
  final ui.Image dash;

  @override
  void paint(ui.Canvas canvas, ui.Size size) {
    var random = Random();
    var paint = Paint();
    //paint.colorFilter = ui.ColorFilter.mode(Colors.red.withAlpha(100), BlendMode.srcOver);
    paint.imageFilter = ui.ImageFilter.blur(sigmaX: 4, sigmaY: 4);

    for (int i = 0; i < 100; i++) {
      var x = random.nextDouble() * size.width;
      var y = random.nextDouble() * size.height;
      canvas.drawImage(dash, Offset(x, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

class CachedFilterGamePainter extends CustomPainter {
  CachedFilterGamePainter(this.dash, this.robin);

  final ui.Image robin;
  final ui.Image dash;

  @override
  void paint(ui.Canvas canvas, ui.Size size) {
    var random = Random();
    var paint = Paint();
    //paint.colorFilter = ui.ColorFilter.mode(Colors.red.withAlpha(100), BlendMode.srcOver);
    paint.imageFilter = ui.ImageFilter.blur(sigmaX: 4, sigmaY: 4);

    var recorder = ui.PictureRecorder();
    var cacheCanvas = ui.Canvas(recorder);
    cacheCanvas.drawImage(dash, Offset.zero, paint);
    var picture = recorder.endRecording();
    var image = picture.toImageSync(dash.width, dash.height);

    for (int i = 0; i < 1000; i++) {
      var x = random.nextDouble() * size.width;
      var y = random.nextDouble() * size.height;
      canvas.drawImage(image, Offset(x, y), Paint());
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

///////////////////////

class PathPainter extends CustomPainter {
  PathPainter(this.dash, this.robin, this.time);

  final ui.Image robin;
  final ui.Image dash;
  final int time;

  @override
  void paint(ui.Canvas canvas, ui.Size size) {
    var paint = Paint()..color = Colors.red;
    var path = _pathFromString(
      'M8.3252 2.675L7.7877 4.0625L5.93771 5.1125L4.4627 4.8875C4.2171 4.85416 3.96713 4.89459 3.74456 5.00365C3.52199 5.11271 3.33686 5.28548 3.21271 5.5L2.7127 6.375C2.58458 6.59294 2.52555 6.8446 2.5434 7.09678C2.56126 7.34895 2.65516 7.58979 2.8127 7.7875L3.7502 8.95V11.05L2.8377 12.2125C2.68016 12.4102 2.58626 12.651 2.5684 12.9032C2.55055 13.1554 2.60958 13.4071 2.73771 13.625L3.2377 14.5C3.36186 14.7145 3.54699 14.8873 3.76956 14.9963C3.99213 15.1054 4.2421 15.1458 4.4877 15.1125L5.96271 14.8875L7.7877 15.9375L8.3252 17.325C8.41585 17.5599 8.57534 17.762 8.78277 17.9047C8.9902 18.0475 9.2359 18.1243 9.48771 18.125H10.5377C10.7895 18.1243 11.0352 18.0475 11.2426 17.9047C11.4501 17.762 11.6096 17.5599 11.7002 17.325L12.2377 15.9375L14.0627 14.8875L15.5377 15.1125C15.7833 15.1458 16.0333 15.1054 16.2559 14.9963C16.4784 14.8873 16.6636 14.7145 16.7877 14.5L17.2877 13.625C17.4158 13.4071 17.4749 13.1554 17.457 12.9032C17.4392 12.651 17.3453 12.4102 17.1877 12.2125L16.2502 11.05V8.95L17.1627 7.7875C17.3203 7.58979 17.4142 7.34895 17.432 7.09678C17.4499 6.8446 17.3908 6.59294 17.2627 6.375L16.7627 5.5C16.6386 5.28548 16.4534 5.11271 16.2309 5.00365C16.0083 4.89459 15.7583 4.85416 15.5127 4.8875L14.0377 5.1125L12.2127 4.0625L11.6752 2.675C11.5846 2.44008 11.4251 2.23801 11.2176 2.09527C11.0102 1.95252 10.7645 1.87574 10.5127 1.875H9.48771C9.2359 1.87574 8.9902 1.95252 8.78277 2.09527C8.57534 2.23801 8.41585 2.44008 8.3252 2.675ZM10 12.5C11.3807 12.5 12.5 11.3807 12.5 10C12.5 8.61929 11.3807 7.5 10 7.5C8.61929 7.5 7.5 8.61929 7.5 10C7.5 11.3807 8.61929 12.5 10 12.5Z',
    )..fillType = PathFillType.evenOdd;

    var dx = .0;
    var dy = .0;
    canvas.scale((time % 100) / 100 * 5 + 1);
    for (int i = 0; i < 1000; i++) {
      canvas.save();
      canvas.translate(dx, dy);
      canvas.drawPath(path, paint);
      canvas.restore();
      dx += 20;
      if (dx >= 600) {
        dx = 0;
        dy += 20;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

/// Helpers
///

/// Parses SVG path data into a [Path] object.
Path _pathFromString(String pathString) {
  int start = 0;
  final RegExp pattern = RegExp('[MLCHVZ]');
  Offset current = Offset.zero;
  final Path path = Path();

  void performCommand(String command) {
    final String type = command[0];
    final List<double> arguments = command
        .substring(1)
        .split(' ')
        .where((String element) => element.isNotEmpty)
        .map((String e) => double.parse(e))
        .toList(growable: false);
    switch (type) {
      case 'M':
        path.moveTo(arguments[0], arguments[1]);
        current = Offset(arguments[0], arguments[1]);
      case 'L':
        path.lineTo(arguments[0], arguments[1]);
        current = Offset(arguments[0], arguments[1]);
      case 'C':
        path.cubicTo(
          arguments[0],
          arguments[1],
          arguments[2],
          arguments[3],
          arguments[4],
          arguments[5],
        );
        current = Offset(arguments[4], arguments[5]);
      case 'H':
        path.lineTo(arguments[0], current.dy);
        current = Offset(arguments[0], current.dy);
      case 'V':
        path.lineTo(current.dx, arguments[0]);
        current = Offset(current.dx, arguments[0]);
    }
  }

  while (true) {
    start = pathString.indexOf(pattern, start);
    if (start == -1) {
      break;
    }
    int end = pathString.indexOf(pattern, start + 1);
    if (end == -1) {
      end = pathString.length;
    }
    final String command = pathString.substring(start, end);
    performCommand(command);
    start = end;
  }
  return path;
}
