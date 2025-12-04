import 'package:flutter/material.dart';
import 'package:flutter_app/data/notifiers.dart';
import 'package:flutter_app/views/pages/welcome_page.dart';



void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(valueListenable: selectedDarkModeNotifier,
      builder: (context, selectedDarkMode, child) {
     return MaterialApp(
       debugShowCheckedModeBanner: false,
       theme: ThemeData(
         colorScheme: ColorScheme.fromSeed(
           seedColor: Colors.teal,
           brightness: selectedDarkMode ? Brightness.dark: Brightness.light,
         ),
       ),

       home: const WelcomePage(),
     );
    },
    ) ;
  }
}


