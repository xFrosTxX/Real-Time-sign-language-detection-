package com.example.flutter_app

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.ImageFormat
import android.graphics.Rect
import android.graphics.YuvImage
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.google.mediapipe.tasks.vision.core.RunningMode
import com.google.mediapipe.tasks.vision.handlandmarker.HandLandmarker
import com.google.mediapipe.tasks.vision.poselandmarker.PoseLandmarker
import com.google.mediapipe.tasks.vision.handlandmarker.HandLandmarkerResult
import com.google.mediapipe.tasks.vision.poselandmarker.PoseLandmarkerResult
import com.google.mediapipe.framework.image.BitmapImageBuilder
import com.google.mediapipe.framework.image.MPImage
import java.io.ByteArrayOutputStream
import java.nio.ByteBuffer
import java.util.concurrent.Executors

class MainActivity: FlutterActivity() {
    private val CHANNEL = "sign_language/mediapipe"
    private var handLandmarker: HandLandmarker? = null
    private var poseLandmarker: PoseLandmarker? = null
    private val backgroundExecutor = Executors.newSingleThreadExecutor()

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Initialize Landmarkers
        setupLandmarkers()

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "processFrame") {
                val bytes = call.argument<ByteArray>("bytes")
                val width = call.argument<Int>("width")
                val height = call.argument<Int>("height")

                if (bytes != null && width != null && height != null) {
                    processImage(bytes, width, height, result)
                } else {
                    result.error("INVALID_ARGS", "Missing bytes, width, or height", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }

    private fun setupLandmarkers() {
        try {
            val handOptions = HandLandmarker.HandLandmarkerOptions.builder()
                .setBaseOptions(com.google.mediapipe.tasks.core.BaseOptions.builder()
                    .setModelAssetPath("hand_landmarker.task").build())
                .setNumHands(2)
                .setMinHandDetectionConfidence(0.5f)
                .setMinHandPresenceConfidence(0.5f)
                .setMinTrackingConfidence(0.5f)
                .setRunningMode(RunningMode.IMAGE) // Using IMAGE mode for simplicity with Flutter frames
                .build()

            handLandmarker = HandLandmarker.createFromOptions(context, handOptions)

            val poseOptions = PoseLandmarker.PoseLandmarkerOptions.builder()
                .setBaseOptions(com.google.mediapipe.tasks.core.BaseOptions.builder()
                    .setModelAssetPath("pose_landmarker_heavy.task").build())
                .setMinPoseDetectionConfidence(0.5f)
                .setMinPosePresenceConfidence(0.5f)
                .setMinTrackingConfidence(0.5f)
                .setRunningMode(RunningMode.IMAGE)
                .build()

            poseLandmarker = PoseLandmarker.createFromOptions(context, poseOptions)
        } catch (e: Exception) {
            android.util.Log.e("MainActivity", "Error setting up landmarkers: ${e.message}")
        }
    }

    private fun processImage(bytes: ByteArray, width: Int, height: Int, result: MethodChannel.Result) {
        backgroundExecutor.execute {
            try {
                // Convert NV21/YUV to Bitmap
                // Note: This is a simplified conversion. For production, consider ScriptIntrinsicYuvToRGB or similar.
                val yuvImage = YuvImage(bytes, ImageFormat.NV21, width, height, null)
                val out = ByteArrayOutputStream()
                yuvImage.compressToJpeg(Rect(0, 0, width, height), 100, out)
                val imageBytes = out.toByteArray()
                val bitmap = BitmapFactory.decodeByteArray(imageBytes, 0, imageBytes.size)

                if (bitmap == null) {
                    runOnUiThread { result.error("IMAGE_ERROR", "Failed to decode bitmap", null) }
                    return@execute
                }

                // Create MPImage
                val mpImage = BitmapImageBuilder(bitmap).build()

                // Run inference
                val handResult = handLandmarker?.detect(mpImage)
                val poseResult = poseLandmarker?.detect(mpImage)

                // Format results
                val resultMap = HashMap<String, Any>()
                
                // Process Hands
                if (handResult != null && handResult.landmarks().size > 0) {
                    // Tasks-vision returns list of hands. We need to distinguish left/right if possible, 
                    // or just send them. The Flutter code expects 'left_hand' and 'right_hand'.
                    // Tasks-vision HandLandmarker output includes handedness.
                    
                    val leftHandList = ArrayList<Map<String, Any>>()
                    val rightHandList = ArrayList<Map<String, Any>>()
                    
                    // Check handedness to assign correctly
                    for (i in 0 until handResult.landmarks().size) {
                        val landmarks = handResult.landmarks()[i]
                        // Handedness is often available in handedness() list matching landmarks list
                        val handednessLabel = if (handResult.handedness().size > i) 
                                                handResult.handedness()[i][0].categoryName() 
                                              else "Unknown"
                        
                        // Mediapipe 'Left' usually means detected left hand (which is on right side of image if mirrored? 
                        // or viewer perspective?). Standard check.
                        
                        val landmarkList = ArrayList<Map<String, Any>>()
                        for (landmark in landmarks) {
                            val map = HashMap<String, Any>()
                            map["x"] = landmark.x()
                            map["y"] = landmark.y()
                            map["z"] = landmark.z()
                            landmarkList.add(map)
                        }

                        if (handednessLabel == "Left") {
                            leftHandList.addAll(landmarkList) // Assuming one left hand
                        } else {
                            rightHandList.addAll(landmarkList) // Assuming one right hand
                        }
                    }
                    
                    if (leftHandList.isNotEmpty()) resultMap["left_hand"] = leftHandList
                    if (rightHandList.isNotEmpty()) resultMap["right_hand"] = rightHandList
                }

                // Process Pose
                if (poseResult != null && poseResult.landmarks().size > 0) {
                     val poseList = ArrayList<Map<String, Any>>()
                     // Usually only one pose detected
                     for (landmark in poseResult.landmarks()[0]) {
                         val map = HashMap<String, Any>()
                         map["x"] = landmark.x()
                         map["y"] = landmark.y()
                         map["z"] = landmark.z()
                         poseList.add(map)
                     }
                     resultMap["pose"] = poseList
                }

                runOnUiThread {
                    result.success(resultMap)
                }

            } catch (e: Exception) {
                runOnUiThread {
                    result.error("INFERENCE_ERROR", e.message, null)
                }
            }
        }
    }
}
