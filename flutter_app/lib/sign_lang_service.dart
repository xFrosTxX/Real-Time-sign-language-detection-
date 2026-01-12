
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:camera/camera.dart';
import 'dart:math' show sqrt;

class SignLanguageService {
  Interpreter? _interpreter;
  Map<int, String>? _indexToSign;
  
  // Buffer for collecting frames (need 64 frames for prediction)
  List<List<double>> _frameBuffer = [];
  bool _isProcessing = false;
  
  // Constants matching your training
  static const int MAX_FRAMES = 64;
  static const int FEATURES_PER_FRAME = 150; // (21+21+33)*2
  
  Future<void> initialize() async {
    print('Loading model...');
    
    // Load TFLite model
    _interpreter = await Interpreter.fromAsset('assets/sign_language_model.tflite');
    print('✓ Model loaded: ${_interpreter!.getInputTensor(0).shape}');
    
    // Load sign mapping
    final jsonString = await rootBundle.loadString('assets/sign_to_prediction_index_map.json');
    final Map<String, dynamic> signToIndex = json.decode(jsonString);
    
    _indexToSign = {};
    signToIndex.forEach((sign, index) {
      _indexToSign![index as int] = sign;
    });
    
    print('✓ Loaded ${_indexToSign!.length} signs');
  }
  
  // Call this for each camera frame
  Future<PredictionResult?> processFrame(CameraImage image) async {
    if (_isProcessing) return null;
    _isProcessing = true;
    
    try {
      // Extract landmarks from frame (you'll get this from native code)
      final landmarks = await _extractLandmarksFromNative(image);
      
      if (landmarks == null) {
        _isProcessing = false;
        return null;
      }
      
      // Add to buffer
      _frameBuffer.add(landmarks);
      
      // Need 64 frames before we can predict
      if (_frameBuffer.length >= MAX_FRAMES) {
        final prediction = await _runInference();
        _frameBuffer.clear(); // Reset for next sign
        _isProcessing = false;
        return prediction;
      }
      
      _isProcessing = false;
      return null;
      
    } catch (e) {
      print('Error: $e');
      _isProcessing = false;
      return null;
    }
  }
  
  Future<List<double>?> _extractLandmarksFromNative(CameraImage image) async {
    // Call native MediaPipe code
    const platform = MethodChannel('sign_language/mediapipe');
    
    try {
      final bytes = _concatenatePlanes(image.planes);
      
      final result = await platform.invokeMethod('processFrame', {
        'bytes': bytes,
        'width': image.width,
        'height': image.height,
      });
      
      if (result == null) return null;
      
      // Extract features in order: left_hand, right_hand, pose
      List<double> features = [];
      
      // Left hand (21 landmarks * 2 = 42 features)
      final leftHand = result['left_hand'];
      if (leftHand != null && leftHand.length >= 21) {
        for (int i = 0; i < 21; i++) {
          features.add((leftHand[i]['x'] as num).toDouble());
          features.add((leftHand[i]['y'] as num).toDouble());
        }
      } else {
        features.addAll(List.filled(42, 0.0));
      }
      
      // Right hand (21 landmarks * 2 = 42 features)
      final rightHand = result['right_hand'];
      if (rightHand != null && rightHand.length >= 21) {
        for (int i = 0; i < 21; i++) {
          features.add((rightHand[i]['x'] as num).toDouble());
          features.add((rightHand[i]['y'] as num).toDouble());
        }
      } else {
        features.addAll(List.filled(42, 0.0));
      }
      
      // Pose (33 landmarks * 2 = 66 features)
      final pose = result['pose'];
      if (pose != null && pose.length >= 33) {
        for (int i = 0; i < 33; i++) {
          features.add((pose[i]['x'] as num).toDouble());
          features.add((pose[i]['y'] as num).toDouble());
        }
      } else {
        features.addAll(List.filled(66, 0.0));
      }
      
      // Normalize (CRITICAL - must match training!)
      return _normalizeLandmarks(features);
      
    } catch (e) {
      print('Native call error: $e');
      return null;
    }
  }
  
  List<double> _normalizeLandmarks(List<double> landmarks) {
    // EXACT SAME NORMALIZATION AS TRAINING
    
    if (landmarks.length != 150) return landmarks;
    
    // Reshape to [75, 2]
    List<List<double>> coords = [];
    for (int i = 0; i < landmarks.length; i += 2) {
      coords.add([landmarks[i], landmarks[i + 1]]);
    }
    
    // Get non-zero coords
    var nonZero = coords.where((c) => c[0] != 0.0 || c[1] != 0.0).toList();
    if (nonZero.isEmpty) return landmarks;
    
    // Center by mean
    double meanX = nonZero.map((c) => c[0]).reduce((a, b) => a + b) / nonZero.length;
    double meanY = nonZero.map((c) => c[1]).reduce((a, b) => a + b) / nonZero.length;
    
    var centered = coords.map((c) {
      if (c[0] == 0.0 && c[1] == 0.0) return [0.0, 0.0];
      return [c[0] - meanX, c[1] - meanY];
    }).toList();
    
    // Scale by std
    var flatCentered = centered
        .where((c) => c[0] != 0.0 || c[1] != 0.0)
        .expand((c) => c)
        .toList();
    
    if (flatCentered.isEmpty) return landmarks;
    
    double variance = flatCentered.map((x) => x * x).reduce((a, b) => a + b) / flatCentered.length;
    double std = variance > 1e-6 ? sqrt(variance) : 1.0;
    
    List<double> normalized = [];
    for (var c in centered) {
      if (c[0] == 0.0 && c[1] == 0.0) {
        normalized.addAll([0.0, 0.0]);
      } else {
        normalized.add(c[0] / std);
        normalized.add(c[1] / std);
      }
    }
    
    return normalized;
  }
  
  Future<PredictionResult> _runInference() async {
    // Prepare input [1, 64, 150]
    List<List<List<double>>> input = [[]];
    
    // Sample if we have more than 64 frames
    List<List<double>> sampled = [];
    if (_frameBuffer.length > MAX_FRAMES) {
      for (int i = 0; i < MAX_FRAMES; i++) {
        int idx = (i * _frameBuffer.length / MAX_FRAMES).floor();
        sampled.add(_frameBuffer[idx]);
      }
    } else {
      sampled = List.from(_frameBuffer);
    }
    
    // Pad if needed
    while (sampled.length < MAX_FRAMES) {
      sampled.add(List.filled(FEATURES_PER_FRAME, 0.0));
    }
    
    input[0] = sampled;
    
    // VALIDATION LOGGING: Check input statistics
    _logInputValidation(input[0]);
    
    // Prepare output [1, 250]
    var output = List.generate(1, (_) => List.filled(250, 0.0));
    
    // Run model
    _interpreter!.run(input, output);
    
    // VALIDATION LOGGING: Check output statistics
    _logOutputValidation(output[0]);
    
    // Get top 5
    List<MapEntry<int, double>> indexed = [];
    for (int i = 0; i < output[0].length; i++) {
      indexed.add(MapEntry(i, output[0][i]));
    }
    indexed.sort((a, b) => b.value.compareTo(a.value));
    
    var top5 = indexed.take(5).map((e) => 
      Prediction(_indexToSign![e.key]!, e.value)
    ).toList();
    
    // HAT BIAS FILTER: Apply filtering to handle model bias
    final filteredResult = _applyHatBiasFilter(top5, output[0]);
    
    return filteredResult;
  }
  
  /// Validates and logs input tensor statistics for debugging
  void _logInputValidation(List<List<double>> inputFrames) {
    // Calculate statistics across all frames
    int totalFeatures = 0;
    int nonZeroFeatures = 0;
    double sumValues = 0.0;
    double minVal = double.infinity;
    double maxVal = double.negativeInfinity;
    
    for (var frame in inputFrames) {
      for (var value in frame) {
        totalFeatures++;
        if (value != 0.0) {
          nonZeroFeatures++;
          sumValues += value;
          if (value < minVal) minVal = value;
          if (value > maxVal) maxVal = value;
        }
      }
    }
    
    double meanVal = nonZeroFeatures > 0 ? sumValues / nonZeroFeatures : 0.0;
    double nonZeroPercent = (nonZeroFeatures / totalFeatures) * 100;
    
    print('═══════════════════════════════════════════════════');
    print('📊 INPUT VALIDATION');
    print('═══════════════════════════════════════════════════');
    print('  Shape: [${inputFrames.length}, ${inputFrames[0].length}]');
    print('  Non-zero features: $nonZeroFeatures / $totalFeatures (${nonZeroPercent.toStringAsFixed(1)}%)');
    print('  Value range: [${minVal.toStringAsFixed(4)}, ${maxVal.toStringAsFixed(4)}]');
    print('  Mean (non-zero): ${meanVal.toStringAsFixed(4)}');
    
    // Warning if input looks suspicious
    if (nonZeroPercent < 10) {
      print('  ⚠️  WARNING: Very few non-zero features detected!');
      print('  This may indicate landmark detection issues.');
    }
  }
  
  /// Validates and logs output tensor statistics for debugging
  void _logOutputValidation(List<double> outputProbabilities) {
    // Find top predictions
    List<MapEntry<int, double>> indexed = [];
    for (int i = 0; i < outputProbabilities.length; i++) {
      indexed.add(MapEntry(i, outputProbabilities[i]));
    }
    indexed.sort((a, b) => b.value.compareTo(a.value));
    
    var top5 = indexed.take(5).toList();
    
    // Calculate statistics
    double sum = outputProbabilities.reduce((a, b) => a + b);
    double maxProb = top5[0].value;
    double secondMaxProb = top5.length > 1 ? top5[1].value : 0.0;
    double confidence = maxProb - secondMaxProb; // Separation between top 2
    
    print('═══════════════════════════════════════════════════');
    print('🎯 OUTPUT VALIDATION');
    print('═══════════════════════════════════════════════════');
    print('  Output shape: [${outputProbabilities.length}]');
    print('  Sum of probabilities: ${sum.toStringAsFixed(4)}');
    print('  Max probability: ${(maxProb * 100).toStringAsFixed(2)}%');
    print('  Confidence margin: ${(confidence * 100).toStringAsFixed(2)}%');
    print('');
    print('  Top 5 predictions:');
    for (int i = 0; i < top5.length; i++) {
      final sign = _indexToSign![top5[i].key] ?? 'Unknown';
      final prob = top5[i].value * 100;
      print('    ${i + 1}. $sign: ${prob.toStringAsFixed(2)}%');
    }
    
    // Warnings
    if (maxProb < 0.1) {
      print('  ⚠️  WARNING: Very low confidence prediction!');
    }
    if (confidence < 0.05) {
      print('  ⚠️  WARNING: Top predictions are very close!');
    }
    print('═══════════════════════════════════════════════════');
  }
  
  /// Applies "hat" bias filter to prevent false "hat" predictions
  /// The model has a known bias to predict "hat" with low-quality input
  PredictionResult _applyHatBiasFilter(List<Prediction> predictions, List<double> rawOutput) {
    const double HAT_CONFIDENCE_THRESHOLD = 0.30; // 30% threshold for "hat"
    const double MIN_CONFIDENCE_THRESHOLD = 0.15; // 15% minimum for any prediction
    
    bool hatFilterApplied = false;
    bool lowConfidence = false;
    
    // Check if top prediction is "hat" with suspicious confidence
    if (predictions.isNotEmpty && 
        predictions[0].sign.toLowerCase() == 'hat' && 
        predictions[0].confidence < HAT_CONFIDENCE_THRESHOLD) {
      
      print('🚫 HAT BIAS FILTER TRIGGERED');
      print('   "hat" predicted with ${(predictions[0].confidence * 100).toStringAsFixed(1)}% confidence');
      print('   Threshold: ${(HAT_CONFIDENCE_THRESHOLD * 100).toStringAsFixed(0)}%');
      
      hatFilterApplied = true;
      
      // Find next best prediction that isn't "hat"
      var alternativePredictions = predictions
          .where((p) => p.sign.toLowerCase() != 'hat')
          .toList();
      
      if (alternativePredictions.isNotEmpty && 
          alternativePredictions[0].confidence >= MIN_CONFIDENCE_THRESHOLD) {
        print('   ✓ Using alternative: ${alternativePredictions[0].sign} (${(alternativePredictions[0].confidence * 100).toStringAsFixed(1)}%)');
        
        // Reorder predictions with "hat" removed from top
        var filtered = [alternativePredictions[0]];
        filtered.addAll(predictions.where((p) => 
            p.sign != alternativePredictions[0].sign && 
            p.sign.toLowerCase() != 'hat'
        ).take(4));
        
        return PredictionResult(
          filtered,
          hatBiasFilterApplied: true,
          lowConfidenceWarning: alternativePredictions[0].confidence < 0.25,
        );
      } else {
        print('   ⚠️  No confident alternative found, keeping "hat" but flagged');
        lowConfidence = true;
      }
    }
    
    // Also filter out any prediction below minimum threshold
    var confidentPredictions = predictions
        .where((p) => p.confidence >= MIN_CONFIDENCE_THRESHOLD)
        .toList();
    
    if (confidentPredictions.isEmpty) {
      print('⚠️  All predictions below ${(MIN_CONFIDENCE_THRESHOLD * 100).toStringAsFixed(0)}% threshold');
      lowConfidence = true;
      // Return original but user should be warned
      return PredictionResult(
        predictions,
        hatBiasFilterApplied: hatFilterApplied,
        lowConfidenceWarning: true,
      );
    }
    
    final resultPredictions = confidentPredictions.length >= 5 
        ? confidentPredictions.take(5).toList() 
        : confidentPredictions;
    
    return PredictionResult(
      resultPredictions,
      hatBiasFilterApplied: hatFilterApplied,
      lowConfidenceWarning: lowConfidence || (resultPredictions.isNotEmpty && resultPredictions[0].confidence < 0.25),
    );
  }
  
  Uint8List _concatenatePlanes(List<Plane> planes) {
    final allBytes = WriteBuffer();
    for (final plane in planes) {
      allBytes.putUint8List(plane.bytes);
    }
    return allBytes.done().buffer.asUint8List();
  }
  
  int get bufferedFrames => _frameBuffer.length;
  void clearBuffer() => _frameBuffer.clear();
  void dispose() => _interpreter?.close();
}

class Prediction {
  final String sign;
  final double confidence;
  Prediction(this.sign, this.confidence);
}

class PredictionResult {
  final List<Prediction> predictions;
  final bool hatBiasFilterApplied;
  final bool lowConfidenceWarning;
  
  PredictionResult(
    this.predictions, {
    this.hatBiasFilterApplied = false,
    this.lowConfidenceWarning = false,
  });
  
  String get topSign => predictions.first.sign;
  double get topConfidence => predictions.first.confidence;
}