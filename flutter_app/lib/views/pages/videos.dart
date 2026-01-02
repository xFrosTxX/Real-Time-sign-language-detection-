import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class VideoPage extends StatefulWidget {
  const VideoPage({super.key});

  @override
  State<VideoPage> createState() => _VideoPageState();
}

class _VideoPageState extends State<VideoPage> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();

      _controller = CameraController(
        _cameras!.first, // back camera
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _controller!.initialize();

      if (!mounted) return;
      setState(() => _isLoading = false);
    } catch (e) {
      debugPrint("Camera error: $e");
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _controller == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Camera")),
      body: CameraPreview(_controller!),
    );
  }
}
