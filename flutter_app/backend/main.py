from fastapi import FastAPI, File, UploadFile, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from tensorflow import keras
import numpy as np
import cv2
import mediapipe as mp
import io
import json
import uvicorn
from pathlib import Path

app = FastAPI(title="ASL Word Recognition API")

# Enable CORS for Flutter app
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Global variables
model = None
label_map = {}
index_to_label = {}
mp_hands = None
hands = None

def load_label_map():
    """Load label mapping from JSON file"""
    global label_map, index_to_label
    try:
        json_path = Path(__file__).parent / 'model' / 'sign_to_prediction_index_map.json'

        with open(json_path, 'r') as f:
            label_map = json.load(f)

        # Create reverse mapping: index -> label
        index_to_label = {v: k for k, v in label_map.items()}

        print(f"✅ Loaded {len(label_map)} ASL word labels")
        print(f"📝 Labels: {list(label_map.keys())[:10]}...")

    except FileNotFoundError:
        print("❌ Error: sign_to_prediction_index_map.json not found!")
        print("   Please place it in the backend/model/ folder")
        raise
    except json.JSONDecodeError as e:
        print(f"❌ Error parsing JSON file: {e}")
        raise

def load_model():
    """Load the Keras model"""
    global model
    try:
        model_path = Path(__file__).parent / 'model' / 'hand_sign_model.keras'

        if not model_path.exists():
            model_path = Path(__file__).parent / 'model' / 'hand_sign_model.h5'

        model = keras.models.load_model(str(model_path))
        print(f"✅ Model loaded successfully from {model_path.name}")
        print(f"📊 Model input shape: {model.input_shape}")
        print(f"📊 Model output shape: {model.output_shape}")
        print(f"📝 Number of classes: {len(index_to_label)}")

    except Exception as e:
        print(f"❌ Error loading model: {e}")
        raise

def init_mediapipe():
    """Initialize MediaPipe Hands - NOTE: Only tracking hands, not pose"""
    global mp_hands, hands
    mp_hands = mp.solutions.hands
    hands = mp_hands.Hands(
        static_image_mode=False,
        max_num_hands=1,  # Track one hand at a time
        min_detection_confidence=0.3,  # Lower for better detection
        min_tracking_confidence=0.3
    )
    print("✅ MediaPipe Hands initialized (hands only, no pose)")

def extract_landmarks(frame):
    """
    Extract hand landmarks from a single frame
    Returns 150 features matching training preprocessing:
    - 21 left hand landmarks (x,y) = 42 features
    - 21 right hand landmarks (x,y) = 42 features
    - 33 pose landmarks (x,y) = 66 features
    Total = 150 features
    """
    # Convert BGR to RGB
    rgb_frame = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)

    # Process with MediaPipe
    results = hands.process(rgb_frame)

    # Initialize feature vector with zeros
    landmarks = np.zeros(150, dtype=np.float32)

    if results.multi_hand_landmarks:
        hand_landmarks = results.multi_hand_landmarks[0]

        # Determine if left or right hand
        handedness = results.multi_handedness[0].classification[0].label

        # Extract 21 landmarks (x, y) = 42 features
        hand_features = []
        for landmark in hand_landmarks.landmark:
            hand_features.extend([landmark.x, landmark.y])

        hand_features = np.array(hand_features, dtype=np.float32)

        # Place in correct position: left_hand (0-41) or right_hand (42-83)
        if handedness == "Left":
            landmarks[0:42] = hand_features
        else:  # Right hand
            landmarks[42:84] = hand_features

    # Note: Pose landmarks (84-149) remain zeros since we only track hands
    # This matches your training data structure

    return landmarks

def normalize_sequence(sequence):
    """
    Normalize sequence EXACTLY like training code:
    1. Reshape to [frames, landmarks, coords]
    2. For each frame with non-zero landmarks:
       - Center around mean (translation invariance)
       - Scale by std (scale invariance)
    3. Reject if too few valid frames
    """
    if sequence is None or len(sequence) == 0:
        return None

    num_frames = sequence.shape[0]
    num_landmarks = 75  # (21 + 21 + 33)

    # Reshape to [frames, landmarks, coords]
    coords = sequence.reshape(num_frames, num_landmarks, 2)

    # Check if sequence is all zeros
    if np.all(sequence == 0):
        print("⚠️  Sequence is all zeros")
        return None

    valid_frame_count = 0

    # Normalize each frame
    for frame_idx in range(num_frames):
        frame_landmarks = coords[frame_idx]  # [75, 2]

        # Skip if all zeros (empty frame)
        if np.all(frame_landmarks == 0):
            continue

        # Get non-zero landmarks
        non_zero_mask = np.any(frame_landmarks != 0, axis=1)
        if not np.any(non_zero_mask):
            continue

        valid_frame_count += 1
        non_zero_landmarks = frame_landmarks[non_zero_mask]

        # Center around mean (translation invariance)
        mean_pos = np.mean(non_zero_landmarks, axis=0)
        frame_landmarks[non_zero_mask] -= mean_pos

        # Scale to unit variance (scale invariance)
        std = np.std(non_zero_landmarks)
        if std > 1e-6:
            frame_landmarks[non_zero_mask] /= std

        coords[frame_idx] = frame_landmarks

    print(f"Valid frames: {valid_frame_count}/{num_frames}")

    # Require at least 20 valid frames (like training)
    if valid_frame_count < 20:
        print(f"⚠️  Too few valid frames: {valid_frame_count} < 20")
        return None

    # Flatten back
    normalized = coords.reshape(num_frames, -1)

    # Check for NaN/Inf
    if not np.all(np.isfinite(normalized)):
        print("⚠️  Contains NaN or Inf after normalization")
        return None

    return normalized.astype(np.float32)

def process_video_to_sequence(video_bytes, target_frames=64):
    """
    Process video bytes and extract landmark sequence
    MATCHES training preprocessing exactly
    Returns: numpy array of shape (64, 150)
    """
    try:
        # Save to temp file
        import tempfile
        import os

        with tempfile.NamedTemporaryFile(delete=False, suffix='.mp4') as tmp_file:
            tmp_file.write(video_bytes)
            tmp_path = tmp_file.name

        # Open video
        cap = cv2.VideoCapture(tmp_path)

        all_landmarks = []
        frame_count = 0

        print(f"Processing video...")

        while cap.isOpened():
            ret, frame = cap.read()
            if not ret:
                break

            # Extract landmarks from this frame
            landmarks = extract_landmarks(frame)
            all_landmarks.append(landmarks)
            frame_count += 1

        cap.release()
        os.unlink(tmp_path)

        print(f"Extracted landmarks from {frame_count} frames")

        if len(all_landmarks) == 0:
            print("⚠️  No frames processed")
            return None

        # Convert to numpy array [num_frames, 150]
        landmarks_array = np.array(all_landmarks, dtype=np.float32)

        # Resample to exactly 64 frames (like training)
        if len(landmarks_array) != target_frames:
            from scipy.interpolate import interp1d

            old_indices = np.linspace(0, len(landmarks_array) - 1, len(landmarks_array))
            new_indices = np.linspace(0, len(landmarks_array) - 1, target_frames)

            interpolated = []
            for i in range(150):  # For each feature
                f = interp1d(old_indices, landmarks_array[:, i], kind='linear')
                interpolated.append(f(new_indices))

            landmarks_array = np.array(interpolated).T

        print(f"Resampled to {landmarks_array.shape}")

        # CRITICAL: Normalize EXACTLY like training
        normalized = normalize_sequence(landmarks_array)

        if normalized is None:
            print("⚠️  Normalization failed")
            return None

        print(f"Final sequence shape: {normalized.shape}")
        print(f"Sequence stats - min: {normalized.min():.4f}, max: {normalized.max():.4f}, mean: {normalized.mean():.4f}")
        print(f"Zero percentage: {(normalized == 0).mean() * 100:.1f}%")

        return normalized

    except Exception as e:
        print(f"❌ Error processing video: {e}")
        import traceback
        traceback.print_exc()
        return None

@app.on_event("startup")
async def startup_event():
    """Load model and labels on startup"""
    load_label_map()
    load_model()
    init_mediapipe()

@app.get("/")
async def root():
    return {
        "message": "ASL Word Recognition API (Video + MediaPipe)",
        "status": "running",
        "model_loaded": model is not None,
        "labels_loaded": len(index_to_label) > 0,
        "num_classes": len(index_to_label),
        "requires": "Video input with hand signs"
    }

@app.get("/health")
async def health_check():
    """Health check endpoint"""
    if model is None:
        raise HTTPException(status_code=503, detail="Model not loaded")
    if len(index_to_label) == 0:
        raise HTTPException(status_code=503, detail="Labels not loaded")
    if hands is None:
        raise HTTPException(status_code=503, detail="MediaPipe not initialized")
    return {
        "status": "healthy",
        "model_loaded": True,
        "labels_loaded": True,
        "mediapipe_ready": True,
        "num_classes": len(index_to_label)
    }

@app.post("/predict")
async def predict(file: UploadFile = File(...)):
    """Predict ASL word from uploaded video"""
    if model is None:
        raise HTTPException(status_code=503, detail="Model not loaded")
    if len(index_to_label) == 0:
        raise HTTPException(status_code=503, detail="Labels not loaded")

    try:
        # Read video
        video_bytes = await file.read()
        print(f"Received video: {len(video_bytes)} bytes")

        # Extract landmark sequence
        sequence = process_video_to_sequence(video_bytes, target_frames=64)
        print(f"Sequence shape: {sequence.shape}")

        # Add batch dimension: (1, 64, 150)
        sequence = np.expand_dims(sequence, axis=0)

        # Predict
        predictions = model.predict(sequence, verbose=0)
        print(f"Predictions shape: {predictions.shape}")

        # Get predicted class and confidence
        predicted_class_idx = int(np.argmax(predictions[0]))
        confidence = float(predictions[0][predicted_class_idx])

        # Get label from index
        predicted_label = index_to_label.get(predicted_class_idx, f"Unknown_{predicted_class_idx}")

        # Get top 5 predictions
        top_5_indices = np.argsort(predictions[0])[-5:][::-1]
        top_5_predictions = {
            index_to_label.get(int(idx), f"Unknown_{idx}"): float(predictions[0][idx])
            for idx in top_5_indices
        }

        print(f"✅ Predicted: {predicted_label} ({confidence:.2%})")

        return {
            "label": predicted_label,
            "confidence": confidence,
            "top_5_predictions": top_5_predictions
        }

    except Exception as e:
        import traceback
        print(f"❌ PREDICTION ERROR:")
        print(traceback.format_exc())
        raise HTTPException(status_code=500, detail=f"Prediction error: {str(e)}")

@app.get("/classes")
async def get_classes():
    """Get list of recognized ASL words"""
    return {
        "classes": sorted(label_map.keys()),
        "count": len(label_map),
        "index_map": label_map
    }

if __name__ == "__main__":
    uvicorn.run(
        app,
        host="0.0.0.0",
        port=8000,
        log_level="info"
    )