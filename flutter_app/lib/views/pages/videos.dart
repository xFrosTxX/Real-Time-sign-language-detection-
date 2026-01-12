import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/sign_lang_service.dart';
import 'package:permission_handler/permission_handler.dart';

class VideoPage extends StatefulWidget {
  const VideoPage({super.key});

  @override
  State<VideoPage> createState() => _VideoPageState();
}

class _VideoPageState extends State<VideoPage> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isLoading = true;
  String? _errorMessage;
  
  // Sign language recognition
  SignLanguageService? _signService;
  PredictionResult? _currentPrediction;
  bool _isRecognizing = false;
  int _frameCount = 0;
  
  // Debug info
  bool _handsDetected = false;
  bool _poseDetected = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await _requestCameraPermission();
    await _initSignLanguageService();
  }

  Future<void> _requestCameraPermission() async {
    try {
      final status = await Permission.camera.request();
      
      if (status.isGranted) {
        await _initCamera();
      } else if (status.isDenied) {
        setState(() {
          _errorMessage = 'Camera permission denied. Please enable it in settings.';
          _isLoading = false;
        });
      } else if (status.isPermanentlyDenied) {
        setState(() {
          _errorMessage = 'Camera permission permanently denied. Please enable it in app settings.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Permission error: $e';
        _isLoading = false;
      });
      debugPrint("Permission error: $e");
    }
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      
      if (_cameras == null || _cameras!.isEmpty) {
        throw Exception('No cameras found on this device');
      }

      _controller = CameraController(
        _cameras!.first,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420, // Explicitly set format
      );

      await _controller!.initialize();
      
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
        _errorMessage = null;
      });
      
      debugPrint('✓ Camera initialized successfully');
    } catch (e) {
      debugPrint("Camera error: $e");
      if (mounted) {
        setState(() {
          _errorMessage = 'Camera initialization failed: $e';
          _isLoading = false;
        });
      }
    }
  }
  
  Future<void> _initSignLanguageService() async {
    try {
      _signService = SignLanguageService();
      await _signService!.initialize();
      debugPrint('✓ Sign language service ready');
    } catch (e) {
      debugPrint('✗ Sign service error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sign language service error: $e'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }
  
  void _toggleRecognition() {
    if (_controller == null || !_controller!.value.isInitialized) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Camera not ready')),
      );
      return;
    }

    if (_signService == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign language service not ready')),
      );
      return;
    }

    if (!_isRecognizing) {
      // Start
      setState(() => _isRecognizing = true);
      
      _controller!.startImageStream((CameraImage image) async {
        final result = await _signService?.processFrame(image);
        
        if (result != null && mounted) {
          setState(() {
            _currentPrediction = result;
            _frameCount = 0;
            _handsDetected = true;
            _poseDetected = true;
          });
        } else if (mounted) {
          setState(() {
            _frameCount = _signService?.bufferedFrames ?? 0;
            // Update detection status based on frame count
            _handsDetected = _frameCount > 0;
            _poseDetected = _frameCount > 0;
          });
        }
      });
    } else {
      // Stop
      _controller!.stopImageStream();
      _signService?.clearBuffer();
      setState(() {
        _isRecognizing = false;
        _currentPrediction = null;
        _frameCount = 0;
        _handsDetected = false;
        _poseDetected = false;
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _signService?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign Language Recognition'),
        backgroundColor: Colors.teal,
      ),
      body: _buildBody(),
      floatingActionButton: _buildFloatingActionButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildBody() {
    // Loading state
    if (_isLoading) {
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

    // Error state
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red.shade300,
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () async {
                  setState(() {
                    _isLoading = true;
                    _errorMessage = null;
                  });
                  await _requestCameraPermission();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: () => openAppSettings(),
                icon: const Icon(Icons.settings),
                label: const Text('Open Settings'),
              ),
            ],
          ),
        ),
      );
    }

    // Camera not initialized
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Center(
        child: Text('Camera initialization failed'),
      );
    }

    // Camera preview with overlay
    return Stack(
      children: [
        // Camera
        Center(
          child: CameraPreview(_controller!),
        ),
        
        // Recording indicator
        if (_isRecognizing)
          Positioned(
            top: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'REC',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        
        // Frame counter
        if (_isRecognizing)
          Positioned(
            top: 20,
            left: 20,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Frames: $_frameCount/64',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.pan_tool,
                        size: 16,
                        color: _handsDetected ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Hands: ${_handsDetected ? "✓" : "✗"}',
                        style: TextStyle(
                          color: _handsDetected ? Colors.green : Colors.red,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        Icons.accessibility_new,
                        size: 16,
                        color: _poseDetected ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Pose: ${_poseDetected ? "✓" : "✗"}',
                        style: TextStyle(
                          color: _poseDetected ? Colors.green : Colors.red,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        
        // Predictions
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
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
            child: _buildPredictionUI(),
          ),
        ),
      ],
    );
  }

  Widget? _buildFloatingActionButton() {
    if (_controller == null || !_controller!.value.isInitialized) {
      return null;
    }

    return FloatingActionButton.extended(
      onPressed: _toggleRecognition,
      backgroundColor: _isRecognizing ? Colors.red : Colors.teal,
      icon: Icon(_isRecognizing ? Icons.stop : Icons.play_arrow),
      label: Text(_isRecognizing ? 'Stop' : 'Start Recognition'),
    );
  }
  
  Widget _buildPredictionUI() {
    if (_currentPrediction == null) {
      return Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.waving_hand,
              size: 48,
              color: Colors.white.withOpacity(0.7),
            ),
            const SizedBox(height: 12),
            Text(
              _isRecognizing 
                  ? 'Perform a sign...' 
                  : 'Tap "Start Recognition" to begin',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top prediction
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green.shade600, Colors.green.shade800],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withOpacity(0.4),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  _currentPrediction!.topSign.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${(_currentPrediction!.topConfidence * 100).toStringAsFixed(1)}% confidence',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Alternatives
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.95),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Other possibilities:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                ...(_currentPrediction!.predictions.skip(1).take(4).map((pred) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          pred.sign,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                        ),
                        Row(
                          children: [
                            Container(
                              width: 80,
                              height: 6,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: FractionallySizedBox(
                                alignment: Alignment.centerLeft,
                                widthFactor: pred.confidence,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.teal,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 45,
                              child: Text(
                                '${(pred.confidence * 100).toStringAsFixed(1)}%',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.black54,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }).toList()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}