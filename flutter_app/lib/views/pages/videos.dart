import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import '../../data/api_service.dart';

class VideoPage extends StatefulWidget {
  const VideoPage({super.key});

  @override
  State<VideoPage> createState() => _VideoPageState();
}

class _VideoPageState extends State<VideoPage> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isLoading = true;
  bool _isRecording = false;
  bool _isProcessing = false;
  bool _serverConnected = false;

  final ApiService _apiService = ApiService();

  String _currentPrediction = 'Press record to sign';
  double _confidence = 0.0;
  int _recordingSeconds = 0;
  Timer? _recordingTimer;

  @override
  void initState() {
    super.initState();
    _initCamera();
    _checkServer();
  }

  Future<void> _checkServer() async {
    final isConnected = await _apiService.checkServerHealth();
    if (mounted) {
      setState(() => _serverConnected = isConnected);

      if (!isConnected) {
        _showServerError();
      }
    }
  }

  void _showServerError() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('⚠️ Cannot connect to server. Make sure FastAPI is running.'),
        duration: Duration(seconds: 5),
        backgroundColor: Colors.orange,
      ),
    );
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();

      _controller = CameraController(
        _cameras!.first,
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

  Future<void> _toggleRecording() async {
    if (!_serverConnected) {
      _showServerError();
      return;
    }

    if (_isRecording) {
      // Stop recording
      await _stopRecording();
    } else {
      // Start recording
      await _startRecording();
    }
  }

  Future<void> _startRecording() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      return;
    }

    try {
      await _controller!.startVideoRecording();

      setState(() {
        _isRecording = true;
        _recordingSeconds = 0;
        _currentPrediction = 'Recording...';
        _confidence = 0.0;
      });

      // Timer to show recording duration
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted) {
          setState(() => _recordingSeconds++);

          // Auto-stop after 3 seconds
          if (_recordingSeconds >= 3) {
            _stopRecording();
          }
        }
      });

    } catch (e) {
      debugPrint('Error starting recording: $e');
    }
  }

  Future<void> _stopRecording() async {
    if (_controller == null || !_controller!.value.isRecordingVideo) {
      return;
    }

    try {
      _recordingTimer?.cancel();

      final videoFile = await _controller!.stopVideoRecording();

      setState(() {
        _isRecording = false;
        _isProcessing = true;
        _currentPrediction = 'Processing video...';
      });

      // Send video to API
      await _processVideo(videoFile);

    } catch (e) {
      debugPrint('Error stopping recording: $e');
      if (mounted) {
        setState(() {
          _isRecording = false;
          _isProcessing = false;
          _currentPrediction = 'Error recording video';
        });
      }
    }
  }

  Future<void> _processVideo(XFile videoFile) async {
    try {
      final videoBytes = await videoFile.readAsBytes();

      debugPrint('Sending video: ${videoBytes.length} bytes');

      final result = await _apiService.predictHandSign(videoBytes);

      if (!mounted) return;

      if (result['success'] == true) {
        setState(() {
          _currentPrediction = result['label'];
          _confidence = result['confidence'];
        });
      } else {
        setState(() {
          _currentPrediction = 'Error: ${result['error']}';
          _confidence = 0.0;
        });
      }
    } catch (e) {
      debugPrint('Prediction error: $e');
      if (mounted) {
        setState(() {
          _currentPrediction = 'Error processing video';
          _confidence = 0.0;
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _controller == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Initializing camera...'),
          ],
        ),
      );
    }

    return Stack(
      children: [
        // Camera Preview
        Positioned.fill(
          child: CameraPreview(_controller!),
        ),

        // Recording indicator overlay
        if (_isRecording)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.red,
                  width: 8,
                ),
              ),
            ),
          ),

        // Top Bar with Server Status
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.7),
                  Colors.transparent,
                ],
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Server Status
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _serverConnected
                        ? Colors.green.withOpacity(0.3)
                        : Colors.red.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _serverConnected ? Colors.green : Colors.red,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _serverConnected ? Colors.green : Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _serverConnected ? 'Connected' : 'Disconnected',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                // Recording Timer
                if (_isRecording)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.fiber_manual_record, color: Colors.white, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          '${_recordingSeconds}s / 3s',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Retry Connection Button
                if (!_serverConnected && !_isRecording)
                  IconButton(
                    onPressed: _checkServer,
                    icon: const Icon(Icons.refresh, color: Colors.white),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.2),
                    ),
                  ),
              ],
            ),
          ),
        ),

        // Processing Indicator
        if (_isProcessing)
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.7),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      color: Colors.teal,
                      strokeWidth: 4,
                    ),
                    SizedBox(height: 20),
                    Text(
                      'Analyzing video...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Extracting hand landmarks',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

        // Prediction Results at Bottom
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withOpacity(0.8),
                  Colors.transparent,
                ],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Instructions
                if (!_isRecording && !_isProcessing)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue, width: 1),
                    ),
                    child: const Text(
                      '📹 Hold the button to record a 3-second sign\n🤟 Show your ASL sign clearly to the camera',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ),

                // Prediction Label
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _confidence > 0
                        ? Colors.teal.withOpacity(0.3)
                        : Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _confidence > 0 ? Colors.teal : Colors.white30,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        _currentPrediction.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 38,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (_confidence > 0) ...[
                        const SizedBox(height: 12),
                        // Confidence Bar
                        Column(
                          children: [
                            Text(
                              'Confidence: ${(_confidence * 100).toStringAsFixed(1)}%',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: LinearProgressIndicator(
                                value: _confidence,
                                backgroundColor: Colors.white24,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  _confidence > 0.7
                                      ? Colors.green
                                      : _confidence > 0.4
                                      ? Colors.orange
                                      : Colors.red,
                                ),
                                minHeight: 8,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Record Button
                GestureDetector(
                  onTap: _toggleRecording,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isRecording
                          ? Colors.red
                          : _serverConnected
                          ? Colors.white
                          : Colors.grey,
                      border: Border.all(
                        color: Colors.white,
                        width: 4,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (_isRecording ? Colors.red : Colors.white)
                              .withOpacity(0.5),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Icon(
                      _isRecording ? Icons.stop : Icons.videocam,
                      color: _isRecording ? Colors.white : Colors.black,
                      size: 40,
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                Text(
                  _isRecording
                      ? 'Tap to stop'
                      : 'Tap to record',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}