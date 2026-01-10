import 'package:flutter/material.dart';
import 'package:flutter_app/views/pages/login_page.dart';
import 'package:flutter_app/views/pages/onboarding_page.dart';
import 'package:flutter_app/views/widget_tree.dart';
import 'package:flutter_app/views/widgets/hero_widget.dart';
import 'package:lottie/lottie.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Center(
              child: SizedBox(
                height: 250,
                child: Lottie.asset('assets/lotties/home.json'),
              ),
            ),
            FittedBox(
              child: Text(
                'GestureWise',
                style: TextStyle(
                  color: Colors.teal, // ✅ text color
                  fontSize: 100,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 10,
                ),
              ),
            ),
            SizedBox(height: 20.0),
            FilledButton(
              onPressed: () {
                // Navigate to onboarding page first
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const OnboardingPage(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                minimumSize: const Size(double.infinity, 45),
                // width: full, height: 50
              ),
              child: const Text('Get Started'),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        LoginPage(isLogin: true), // Login mode
                  ),
                );
              },
              child: Text('Login'),
            ),
          ],
        ),
      ),
    );
  }
}
