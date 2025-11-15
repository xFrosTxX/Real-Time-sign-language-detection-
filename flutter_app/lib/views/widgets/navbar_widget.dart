import 'package:flutter/material.dart';
import 'package:flutter_app/data/notifiers.dart';

class NavBarWidget extends StatelessWidget {
  const NavBarWidget({super.key});

@override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(valueListenable: selectedPageNotifier,
      builder: (context, selectedPage, child) {
      return NavigationBar(
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.video_camera_back),
            label: 'Video',
          ),
          NavigationDestination(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],

        selectedIndex: selectedPage,

        onDestinationSelected: (int value) {

        selectedPageNotifier.value = value;
        },
      );

    },
    );
  }
}
