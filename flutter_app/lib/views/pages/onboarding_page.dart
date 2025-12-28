import 'package:flutter/material.dart';
import 'package:flutter_app/views/pages/login_page.dart';
import 'package:lottie/lottie.dart';

class KTextStyle {
  static const TextStyle descriptionText = TextStyle(
    fontSize: 18,
    color: Colors.teal,
    fontWeight: FontWeight.w500,
    height: 1.6,
    letterSpacing: 0.4,
  );
}

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Lottie.asset('assets/lotties/Welcome.json'),
                const SizedBox(height: 40),
                const Text(
                  'Welcome to the Sign Language Recognition App',
                  style: KTextStyle.descriptionText,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    minimumSize: const Size(double.infinity, 40),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    // Navigate to LoginPage in REGISTER mode
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const LoginPage(isLogin: false), // false = register
                      ),
                    );
                  },
                  child: const Text(
                    'Register Now',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // Optional: if user wants to go directly to LOGIN
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const LoginPage(isLogin: true), // true = login
                      ),
                    );
                  },
                  child: const Text(
                    'Already have an account? Login',
                    style: TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
