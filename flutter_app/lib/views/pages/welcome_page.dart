import 'package:flutter/material.dart';
import 'package:flutter_app/views/pages/home_page.dart';
import 'package:flutter_app/views/pages/login_page.dart';
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
              color: Colors.teal,      // ✅ text color
              fontSize: 100,
              fontWeight: FontWeight.bold,
              letterSpacing: 10,
            ),
            ),
          ),
          SizedBox(height: 20.0),


          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.tealAccent,
              minimumSize: Size(double.infinity, 40.0),
            ),

            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                 SnackBar(
                   duration:Duration(seconds: 5),
                     content: Text('SignUp New account'),
                   behavior: SnackBarBehavior.floating,
                 ),
              );
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) {
                    return LoginPage();
                  },
                ),
              );
            },
                child: Text('Get Started'),

          ),
          TextButton(
            style: FilledButton.styleFrom(
              minimumSize: Size(double.infinity, 40.0),

            ),

            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  duration:Duration(seconds: 5),
                  content: Text('Login Successful'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) {
                    return WidgetTree();
                  },
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
