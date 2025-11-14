import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false ,
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal,
      brightness: Brightness.dark )),

      home: Scaffold(
      appBar: AppBar(
        title: Text('Sign Language Recognition'),
        centerTitle: true,
       backgroundColor: Colors.teal,

      ),
        drawer: SafeArea(
          child: Column(
            children:[
              DrawerHeader(child: Text('Gesturewise')),
              ListTile(
            title: Text('Logout')
                ,
        ),
            ],
        ),
            
      ),

        floatingActionButton:FloatingActionButton(
            onPressed: (){
              print('button pressed');

    } ,
          child: Icon(Icons.browse_gallery),
        ),

    
        bottomNavigationBar:NavigationBar(
            destinations: [
          NavigationDestination(
              icon: Icon(Icons.home),
              label: 'Home',
          ),
              NavigationDestination(
                icon: Icon(Icons.video_camera_back),
                label: 'video',
              ),
              NavigationDestination(
                icon: Icon(Icons.person),
                label: 'profile',
              ),
        ],
        onDestinationSelected:(int value) {

        }  ,
        selectedIndex: 0,
        ),
      ),
    );
  }
}

