# GestureWise — Real-Time Sign Language Recognition Mobile App (Sign-to-Text)

Real-time sign language recognition mobile application that translates hand gestures into readable text, built to bridge the communication gap between sign language users and non-signers.

## Overview

People with hearing and speech impairment often face communication barriers due to limited widespread knowledge of sign language. **GestureWise** addresses this by using a smartphone camera and an on-device machine learning model to recognize hand gestures and instantly convert them into text — no external hardware or sensors required.

The app performs real-time inference directly on Android devices using **TensorFlow Lite**, with a cross-platform interface built in **Flutter**.

## Features

- 🔐 **Secure Authentication** — Register/login with Firebase Authentication
- 📷 **Live Camera Input** — Real-time gesture capture using the device camera
- 🤖 **On-Device ML Inference** — Low-latency gesture recognition via TensorFlow Lite
- 📝 **Sign-to-Text Translation** — Recognized gestures converted into readable text instantly
- 👤 **Profile Management** — Update username (Firestore) and profile picture (local storage)
- 🌙 **Dark Mode** support

## Tech Stack

| Layer | Technology |
|---|---|
| App Framework | Flutter (Dart) |
| ML Inference | TensorFlow Lite |
| Auth & Database | Firebase Authentication, Cloud Firestore |
| Local Storage | On-device storage (profile pictures) |
| Dev Tools | Android Studio, Visual Studio Code |
| Version Control | Git & GitHub |

## System Architecture

The system follows a modular architecture with clear separation of concerns:

- **Presentation Layer** — Flutter widgets (Login, Camera, Result, Profile screens)
- **App Controller** — Coordinates data flow between modules
- **Gesture Recognition Module** — Preprocessing → keypoint extraction → TFLite inference → smoothing
- **Data Module** — Profile and history caching
- **Firebase Layer** — Authentication + Firestore for user data

```
User → Presentation Layer → App Controller → Camera Module → Recognition Module → Local ML Model (TFLite)
                                     ↓
                              Data Module ↔ Firebase Auth + Firestore
```

## Machine Learning Model

- **Input:** Time-series hand, pose, and body landmark coordinates extracted from sign language videos (normalized for translation/scale invariance, padded/truncated to fixed length)
- **Architecture:** Lightweight **Conv1D-based neural network** with stacked 1D convolutions, batch normalization, pooling, global average pooling, and fully connected layers
- **Size:** ~2.06 million parameters (~7.8 MB), converted to TensorFlow Lite for on-device deployment
- **Training:** Supervised learning, categorical cross-entropy loss, 100 epochs

### Performance

| Metric | Result |
|---|---|
| Training Accuracy | ~82% |
| Validation Accuracy | ~75–76% |
| Top-5 Validation Accuracy | >90% |

Validation loss stabilizes after ~40–50 epochs; mild overfitting is controlled with dropout, batch normalization, and early stopping.

## Getting Started

### Prerequisites

- Flutter SDK
- Android Studio / VS Code with Flutter & Dart plugins
- A Firebase project (Authentication + Cloud Firestore enabled)
- Android device/emulator (API level per `android/app/build.gradle`)

### Installation

```bash
# Clone the repository
git clone https://github.com/<your-username>/gesturewise.git
cd gesturewise

# Install dependencies
flutter pub get

# Add your Firebase config files
#   - android/app/google-services.json

# Run the app
flutter run
```

### Hardware Requirements (Development)

- Processor: Intel i3 or equivalent (minimum)
- RAM: 4 GB or more
- Storage: 50 GB free space
- Internet connection (for Firebase & API testing)

## Project Structure

```
lib/
├── auth/           # Login, Register, Auth gate
├── camera/         # Camera capture & frame processing
├── ml/             # TFLite inference & preprocessing
├── profile/        # Profile management (username, picture)
├── screens/         # Home, Settings, and other UI screens
└── main.dart
assets/
└── model/          # TensorFlow Lite model + labels
```

## How It Works

1. User authenticates via Firebase (Login/Register)
2. On the Home screen, user opens the camera and starts detection
3. Camera frames are preprocessed (resized, normalized) and keypoints extracted
4. TensorFlow Lite model performs inference and outputs a predicted gesture
5. Smoothing is applied to stabilize predictions
6. Recognized text is displayed in real time
7. Profile updates (username → Firestore, picture → local storage) are handled separately

## App Images

<p align="center">
  <img width="267" height="453" alt="Login screen" src="https://github.com/user-attachments/assets/27d24345-4f9e-4d84-a232-2846ddd65480" />
  <img width="269" height="583" alt="Home screen" src="https://github.com/user-attachments/assets/23872eb4-dd3d-4a4c-a694-69ea0e4e6cf1" />
</p>

## Limitations

- Supports only a predefined, limited vocabulary of **isolated static gestures** (no continuous/sentence-level recognition)
- Recognition accuracy is sensitive to lighting, background clutter, and hand occlusion
- No facial expression or dynamic gesture recognition
- Tested on a limited set of Android devices; performance may vary on low-end hardware

## Future Enhancements

- Expand and diversify the gesture training dataset
- Support continuous/sentence-level sign language recognition
- Incorporate dynamic gestures and facial expressions
- Add text-to-speech for two-way communication
- iOS support and further optimization for low-end devices

## References

- Starner, T. & Pentland, A. (1998). *Real-time American Sign Language Recognition from Video Using Hidden Markov Models.* IEEE ISCV.
- Ong, S. K. & Ranganath, S. (2005). *Automatic Sign Language Analysis: A Survey and the Future Beyond Lexical Meaning.* IEEE TPAMI, 27(6):873–891.
- Molchanov, P., Gupta, S., Kim, K., & Kautz, J. (2016). *Online Detection and Classification of Dynamic Hand Gestures with Recurrent 3D CNNs.* IEEE CVPR.
- Zhang, J., Zhou, W., & Xie, C. (2019). *Hand Gesture Recognition Based on Deep Learning for Mobile Devices.* Journal of Visual Communication and Image Representation, 62:102–112.
