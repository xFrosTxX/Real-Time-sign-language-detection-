import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  late CameraController cameraController;
  late Interpreter interpreter;
  bool isCameraReady = false;
  String predictedLabel = "Waiting...";

  @override
  void initState() {
    super.initState();
    loadModel();
    initCamera();
  }

  Future<void> loadModel() async {
    interpreter = await Interpreter.fromAsset('hand_model.tflite');
    print("Model loaded!");
  }

  Future<void> initCamera() async {
    final cameras = await availableCameras();
    cameraController = CameraController(
      cameras[0],
      ResolutionPreset.medium,
      enableAudio: false,
    );

    await cameraController.initialize();
    setState(() => isCameraReady = true);

    cameraController.startImageStream(processCameraImage);
  }

  void processCameraImage(CameraImage image) {
    if (!mounted) return;

    // Convert YUV420 → RGB
    img.Image rgbImage = convertYUV420toImageColor(image);

    // Resize to 64×64
    img.Image resized = img.copyResize(rgbImage, width: 64, height: 64);

    // Convert to Float32List
    Float32List input = imageToFloat32(resized);

    var output = List.filled(29, 0.0).reshape([1, 29]);

    interpreter.run([input], output);

    // Find max index
    int index =
        output[0].indexWhere((e) => e == output[0].reduce((a, b) => a > b ? a : b));

    setState(() {
      predictedLabel = indexToLabel(index);
    });
  }

  // Convert image to float
  Float32List imageToFloat32(img.Image image) {
    var floats = Float32List(64 * 64 * 3);
    int i = 0;

    for (int y = 0; y < 64; y++) {
      for (int x = 0; x < 64; x++) {
        final pixel = image.getPixel(x, y);
        floats[i++] = img.getRed(pixel) / 255.0;
        floats[i++] = img.getGreen(pixel) / 255.0;
        floats[i++] = img.getBlue(pixel) / 255.0;
      }
    }

    return floats;
  }

  // Your class labels:
  String indexToLabel(int i) {
    const labels = [
      'A','B','C','D','E','F','G','H','I','J',
      'K','L','M','N','O','P','Q','R','S','T',
      'U','V','W','X','Y','Z','del','nothing','space'
    ];
    return labels[i];
  }

  // YUV → RGB converter (required for Android)
  img.Image convertYUV420toImageColor(CameraImage image) {
    final int width = image.width;
    final int height = image.height;

    final img.Image imgBuffer = img.Image(width: width, height: height);

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final int uvIndex =
            (y ~/ 2) * (width ~/ 2) + (x ~/ 2); // chroma index

        final yp = image.planes[0].bytes[y * width + x];
        final up = image.planes[1].bytes[uvIndex];
        final vp = image.planes[2].bytes[uvIndex];

        int r = (yp + vp * 1436 ~/ 1024 - 179).clamp(0, 255);
        int g = (yp - up * 46549 ~/ 131072 + 44 - vp * 93604 ~/ 131072 + 91)
            .clamp(0, 255);
        int b = (yp + up * 1814 ~/ 1024 - 227).clamp(0, 255);

        imgBuffer.setPixelRgba(x, y, r, g, b);
      }
    }

    return imgBuffer;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isCameraReady
          ? Stack(
              children: [
                CameraPreview(cameraController),
                Positioned(
                  bottom: 40,
                  left: 0,
                  right: 0,
                  child: Text(
                    predictedLabel,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: Colors.yellow,
                    ),
                  ),
                )
              ],
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }
}
