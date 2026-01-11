
package com.example.flutter_app

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.ImageFormat
import android.graphics.Rect
import android.graphics.YuvImage
import com.google.mediapipe.framework.image.BitmapImageBuilder
import com.google.mediapipe.tasks.core.BaseOptions
import com.google.mediapipe.tasks.vision.core.RunningMode
import com.google.mediapipe.tasks.vision.handlandmarker.HandLandmarker
import com.google.mediapipe.tasks.vision.handlandmarker.HandLandmarkerResult
import com.google.mediapipe.tasks.vision.poselandmarker.PoseLandmarker
import com.google.mediapipe.tasks.vision.poselandmarker.PoseLandmarkerResult
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream

class MediaPipeHandler(private val context: Context) {
    
    private var handLandmarker: HandLandmarker? = null
    private var poseLandmarker: PoseLandmarker? = null
    
    fun initialize() {
        try {
            // Initialize Hand Landmarker
            val handOptions = HandLandmarker.HandLandmarkerOptions.builder()
                .setBaseOptions(
                    BaseOptions.builder()
                        .setModelAssetPath("hand_landmarker.task") 
                        .build()
                )
                .setRunningMode(RunningMode.IMAGE)
                .setNumHands(2) // Detect both hands
                .setMinHandDetectionConfidence(0.5f)
                .setMinHandPresenceConfidence(0.5f)
                .setMinTrackingConfidence(0.5f)
                .build()
            
            handLandmarker = HandLandmarker.createFromOptions(context, handOptions)
            
            // Initialize Pose Landmarker
            val poseOptions = PoseLandmarker.PoseLandmarkerOptions.builder()
                .setBaseOptions(
                    BaseOptions.builder()
                        .setModelAssetPath("pose_landmarker_heavy.task") 
                        .build()
                )
                .setRunningMode(RunningMode.IMAGE)
                .setMinPoseDetectionConfidence(0.5f)
                .setMinPosePresenceConfidence(0.5f)
                .setMinTrackingConfidence(0.5f)
                .build()
            
            poseLandmarker = PoseLandmarker.createFromOptions(context, poseOptions)
            
            println("MediaPipe initialized successfully")
        } catch (e: Exception) {
            println("MediaPipe initialization error: ${e.message}")
            e.printStackTrace()
        }
    }
    
    fun processFrame(bytes: ByteArray, width: Int, height: Int): Map<String, Any?>? {
        try {
            // Convert camera bytes to Bitmap
            val bitmap = bytesToBitmap(bytes, width, height) ?: return null
            
            // Create MediaPipe Image
            val mpImage = BitmapImageBuilder(bitmap).build()
            
            // Detect hands
            val handResult = handLandmarker?.detect(mpImage)
            
            // Detect pose
            val poseResult = poseLandmarker?.detect(mpImage)
            
            // Parse results
            return parseResults(handResult, poseResult)
            
        } catch (e: Exception) {
            println("Frame processing error: ${e.message}")
            return null
        }
    }
    
    private fun bytesToBitmap(bytes: ByteArray, width: Int, height: Int): Bitmap? {
        return try {
            // Assuming NV21 format (standard Android camera format)
            val yuvImage = YuvImage(bytes, ImageFormat.NV21, width, height, null)
            val out = ByteArrayOutputStream()
            yuvImage.compressToJpeg(Rect(0, 0, width, height), 100, out)
            val imageBytes = out.toByteArray()
            BitmapFactory.decodeByteArray(imageBytes, 0, imageBytes.size)
        } catch (e: Exception) {
            println("Bitmap conversion error: ${e.message}")
            null
        }
    }
    
    private fun parseResults(
        handResult: HandLandmarkerResult?,
        poseResult: PoseLandmarkerResult?
    ): Map<String, Any?> {
        
        val result = mutableMapOf<String, Any?>()
        
        // Parse hand landmarks
        if (handResult != null && handResult.landmarks().isNotEmpty()) {
            // Separate left and right hands
            var leftHand: List<Map<String, Float>>? = null
            var rightHand: List<Map<String, Float>>? = null
            
            for (i in handResult.landmarks().indices) {
                val landmarks = handResult.landmarks()[i]
                val handedness = handResult.handedness()[i]
                
                val landmarkList = landmarks.map { landmark ->
                    mapOf(
                        "x" to landmark.x(),
                        "y" to landmark.y(),
                        "z" to landmark.z()
                    )
                }
                
                // Check if it's left or right hand
                val label = handedness.firstOrNull()?.categoryName()
                when (label) {
                    "Left" -> leftHand = landmarkList
                    "Right" -> rightHand = landmarkList
                }
            }
            
            result["left_hand"] = leftHand
            result["right_hand"] = rightHand
        } else {
            result["left_hand"] = null
            result["right_hand"] = null
        }
        
        // Parse pose landmarks
        if (poseResult != null && poseResult.landmarks().isNotEmpty()) {
            val poseLandmarks = poseResult.landmarks()[0]
            val poseList = poseLandmarks.map { landmark ->
                mapOf(
                    "x" to landmark.x(),
                    "y" to landmark.y(),
                    "z" to landmark.z()
                )
            }
            result["pose"] = poseList
        } else {
            result["pose"] = null
        }
        
        return result
    }
    
    fun close() {
        handLandmarker?.close()
        poseLandmarker?.close()
    }
}