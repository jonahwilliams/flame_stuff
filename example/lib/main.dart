import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

void main() {
  runApp(MaterialApp(home: const MyApp()));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ui.Image? dash;
  ui.Image? robin;

  @override
  void initState() {
    super.initState();
    setup();
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
            painter: FilterGamePainter(dash!, robin!),
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
    for (int i = 0; i < 1000; i++) {
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
    canvas.drawAtlas(
      dash,
      [
        for (int i = 0; i < 1000; i++)
          RSTransform.fromComponents(
            rotation: 0,
            scale: 1,
            anchorX: 0,
            anchorY: 0,
            translateX: random.nextDouble() * size.width,
            translateY: random.nextDouble() * size.height,
          ),
      ],
      [
        for (int i = 0; i < 1000; i++)
          Offset.zero & Size(dash.width.toDouble(), dash.height.toDouble()),
      ],
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