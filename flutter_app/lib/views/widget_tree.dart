import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/data/notifiers.dart';
import 'package:flutter_app/views/pages/home_page.dart';
import 'package:flutter_app/views/pages/settings.dart';
import 'package:flutter_app/views/pages/videos.dart';
import 'package:flutter_app/views/pages/profile.dart';
import 'package:flutter_app/views/pages/welcome_page.dart';
import 'widgets/navbar_widget.dart';

List<Widget> pages = [
  const HomePage(),
  const VideoPage(),
  const ProfilePage(),
  const SettingsPage(),
];

class WidgetTree extends StatelessWidget {
  const WidgetTree({super.key});

  Future<void> signOut(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          duration: Duration(seconds: 5),
          content: Text('Logged Out'),
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const WelcomePage()),
        (route) => false,
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error logging out: $e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color.fromARGB(255, 1, 72, 107),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign Language Recognition'),
        actions: [
          IconButton(
            onPressed: () {
              selectedDarkModeNotifier.value = !selectedDarkModeNotifier.value;
            },
            icon: ValueListenableBuilder(
              valueListenable: selectedDarkModeNotifier,
              builder: (context, selectedDarkModeNotifier, child) {
                return Icon(
                  selectedDarkModeNotifier ? Icons.dark_mode : Icons.light_mode,
                );
              },
            ),
          ),
        ],
        centerTitle: true,
        backgroundColor: Colors.teal,
      ),
      body: ValueListenableBuilder(
        valueListenable: selectedPageNotifier,
        builder: (context, selectedPage, child) {
          return pages.elementAt(selectedPage);
        },
      ),
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            children: [
              DrawerHeader(
                decoration: BoxDecoration(),
                child: Text(
                  'Gesturewise',
                  style: TextStyle(
                    color: Colors.teal,
                    fontSize: 24,
                  ),
                ),
              ),
              ListTile(
                title: Text('Logout'),
                onTap: () {
                  Navigator.pop(context);
                  signOut(context);
                },
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          print('button pressed');
        },
        child: const Icon(Icons.browse_gallery),
      ),
      bottomNavigationBar: const NavBarWidget(),
    );
  }
}
