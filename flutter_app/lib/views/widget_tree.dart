import 'package:flutter/material.dart';
import 'package:flutter_app/views/pages/home_page.dart';
import 'package:flutter_app/views/pages/videos.dart';
import 'package:flutter_app/views/pages/profile.dart';
import '../widgets/navbar_widget.dart';
List<Widget> pages =[
  HomePage(),
  ProfilePage(),
  VideoPage(),
];
class WidgetTree extends StatelessWidget {
  const WidgetTree ({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sign Language Recognition'),
        centerTitle: true,
        backgroundColor: Colors.teal,
      ),
      body: pages.elementAt(2) ,

      drawer: Drawer(
        child: SafeArea(
          child: Column(
            children: [
              DrawerHeader(child: Text('Gesturewise')),
              ListTile(
                title: Text('Logout'),
              ),
            ],
          ),
        ),
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          print('button pressed');
        },
        child: Icon(Icons.browse_gallery),
      ),

      bottomNavigationBar: NavBarWidget(),
    );;
  }
}
