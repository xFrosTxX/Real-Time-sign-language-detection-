import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class VideoPage extends StatefulWidget {
  const VideoPage({super.key});

  @override
  State<VideoPage> createState() => _VideoPageState();
}

class _VideoPageState extends State<VideoPage> {
  CameraController? cameraController;
  bool isCameraReady = false;
  List<CameraDescription>? cameras;
  int selectedCameraIndex = 0;

  @override
  void initState() {
    super.initState();
    initCamera();
  }

  Future<void> initCamera() async {
    cameras = await availableCameras();
    final camera = cameras!.firstWhere(
          (c) => c.lensDirection == CameraLensDirection.back,
      orElse: () => cameras!.first,
    );
    selectedCameraIndex = cameras!.indexOf(camera);

    cameraController = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
    );

    await cameraController!.initialize();

    if (!mounted) return;
    setState(() => isCameraReady = true);
  }

  Future<void> flipCamera() async {
    if (cameras == null || cameras!.length < 2) return;

    setState(() => isCameraReady = false);
    await cameraController?.dispose();

    selectedCameraIndex = (selectedCameraIndex + 1) % cameras!.length;

    cameraController = CameraController(
      cameras![selectedCameraIndex],
      ResolutionPreset.high,
      enableAudio: false,
    );

    await cameraController!.initialize();

    if (!mounted) return;
    setState(() => isCameraReady = true);
  }

  @override
  void dispose() {
    cameraController?.dispose();
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
            top: 40,
            right: 20,
            child: IconButton(
              onPressed: flipCamera,
              icon: const Icon(
                Icons.flip_camera_ios,
                color: Colors.white,
                size: 30,
              ),
            ),
          ),
        ],
      )
          : const Center(child: CircularProgressIndicator()),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          if (cameraController != null && isCameraReady) {
            final image = await cameraController!.takePicture();
            print('Photo saved to: ${image.path}');
          }
        },
        child: const Icon(Icons.camera_alt),
      ),
    );
  }
}