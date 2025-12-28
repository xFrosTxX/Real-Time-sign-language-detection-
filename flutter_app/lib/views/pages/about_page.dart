import 'package:flutter/material.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("About")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              "GestureWise",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              "GestureWise is a real-time sign language detection app "
              "designed to help users communicate using hand gestures.",
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 20),
            Text("Version: 1.0.0"),
            SizedBox(height: 6),
            Text("Developed as semester project."),
          ],
        ),
      ),
    );
  }
}
