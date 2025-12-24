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
  CameraController? cameraController;
  Interpreter? interpreter;

  bool isCameraReady = false;
  bool modelReady = false;
  bool isProcessing = false;

  String predictedLabel = "Waiting...";

  @override
  void initState() {
    super.initState();
    loadModel();
  }

  // ✅ Loads model from assets folder
  Future<void> loadModel() async {
    try {
      // IMPORTANT: your file should be at assets/hand_model.tflite
      interpreter = await Interpreter.fromAsset('assets/hand_model.tflite');

      // Optional: print tensor info (helps debug shape issues)
      print("✅ Model loaded");
      print("Input shape: ${interpreter!.getInputTensor(0).shape}");
      print("Input type : ${interpreter!.getInputTensor(0).type}");
      print("Output shape: ${interpreter!.getOutputTensor(0).shape}");
      print("Output type : ${interpreter!.getOutputTensor(0).type}");

      if (!mounted) return;
      setState(() {
        modelReady = true;
      });

      await initCamera();
    } catch (e) {
      print("❌ Error loading model: $e");
    }
  }

  Future<void> initCamera() async {
    final cameras = await availableCameras();
    final camera = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );

    cameraController = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
    );

    cameraController = CameraController(
      cameras[0],
      ResolutionPreset.veryHigh,
      enableAudio: false,
    );

    await cameraController!.initialize();

    if (!mounted) return;
    setState(() => isCameraReady = true);

    cameraController!.startImageStream(processCameraImage);
  }

  void processCameraImage(CameraImage image) async {
    if (!mounted) return;
    if (!modelReady || interpreter == null) return;
    if (isProcessing) return;

    isProcessing = true;

    try {
      final rgbImage = convertYUV420toImageColor(image);
      final resized = img.copyResize(rgbImage, width: 64, height: 64);

      // input [1,64,64,3]
      final input = imageToFloat32(resized).reshape([1, 64, 64, 3]);

      // ✅ strongly-typed output
      final output = Float32List(29);
      final outputReshaped = output.reshape([1, 29]);

      interpreter!.run(input, outputReshaped);

      // ✅ find argmax safely
      double maxVal = output[0];
      int index = 0;
      for (int i = 1; i < output.length; i++) {
        if (output[i] > maxVal) {
          maxVal = output[i];
          index = i;
        }
      }

      if (!mounted) return;
      setState(() {
        predictedLabel = indexToLabel(index);
      });
    } catch (e) {
      print("⚠️ Error in processCameraImage: $e");
    } finally {
      isProcessing = false;
    }
  }

  Float32List imageToFloat32(img.Image image) {
    final floats = Float32List(64 * 64 * 3);
    int i = 0;

    for (int y = 0; y < 64; y++) {
      for (int x = 0; x < 64; x++) {
        final pixel = image.getPixel(x, y);
        floats[i++] = pixel.r / 255.0;
        floats[i++] = pixel.g / 255.0;
        floats[i++] = pixel.b / 255.0;
      }
    }

    return floats;
  }

  String indexToLabel(int i) {
    const labels = [
      'A',
      'B',
      'C',
      'D',
      'E',
      'F',
      'G',
      'H',
      'I',
      'J',
      'K',
      'L',
      'M',
      'N',
      'O',
      'P',
      'Q',
      'R',
      'S',
      'T',
      'U',
      'V',
      'W',
      'X',
      'Y',
      'Z',
      'del',
      'nothing',
      'space',
    ];

    if (i < 0 || i >= labels.length) return "Unknown";
    return labels[i];
  }

  // Converts camera YUV420 image to RGB image
  img.Image convertYUV420toImageColor(CameraImage image) {
    final width = image.width;
    final height = image.height;

    final img.Image imgBuffer = img.Image(width: width, height: height);

    final planeY = image.planes[0];
    final planeU = image.planes[1];
    final planeV = image.planes[2];

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final int uvIndex = (y ~/ 2) * (width ~/ 2) + (x ~/ 2);

        final int yp = planeY.bytes[y * width + x];
        final int up = planeU.bytes[uvIndex];
        final int vp = planeV.bytes[uvIndex];

        int r = (yp + vp * 1436 ~/ 1024 - 179).clamp(0, 255);
        int g = (yp - up * 46549 ~/ 131072 + 44 - vp * 93604 ~/ 131072 + 91)
            .clamp(0, 255);
        int b = (yp + up * 1814 ~/ 1024 - 227).clamp(0, 255);

        imgBuffer.setPixelRgba(x, y, r, g, b, 255);
      }
    }

    return imgBuffer;
  }

  @override
  void dispose() {
    cameraController?.dispose();
    interpreter?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isCameraReady
          ? Stack(
              children: [
                CameraPreview(cameraController!),
                Positioned(
                  bottom: 50,
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
                ),
              ],
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }
}
