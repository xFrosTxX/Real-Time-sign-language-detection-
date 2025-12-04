
import 'package:flutter/material.dart';
import 'package:flutter_app/data/notifiers.dart';
import 'package:flutter_app/views/pages/welcome_page.dart';
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(padding: EdgeInsets.all(20.0),
        child:Column(
          children: [
            Center(
              child: CircleAvatar(
                radius: 70,
                backgroundColor: Colors.teal.shade300,
                child: Icon(
                  Icons.person,
                  size: 80,
                  color: Colors.blueGrey,
                ),
              ),
            ),
            Text(
              "User",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),


            SizedBox(height: 10),

            SizedBox(height: 20),


            ListTile(
              title: Text('Logout'),
            onTap: (){
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  duration:Duration(seconds: 5),
                  content: Text('Logged Out'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
              selectedPageNotifier.value=0;
                Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) {
                    return WelcomePage();
                  },
                ),
              );
            },


            ),
    Divider(
      color: Colors.teal,
      thickness: 1.0,

    ),
    ListTile(
    title: Text('About'),
    onTap: (){
      showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('About'),
          content: Text('Made By Anmol with little help from arnav and gang'),
        );
      },
        );
    },
    ),
            Divider(
              color: Colors.teal,
              thickness: 1.0,

            ),


          ],
        ),);
  }
}

