import 'package:flutter/material.dart';
import 'package:flutter_app/views/widget_tree.dart';
import 'package:flutter_app/views/widgets/hero_widget.dart';


class LoginPage extends StatefulWidget {
  const LoginPage({
    super.key,
    required this.title,
  });

  final String title;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>{
  TextEditingController controllerEmail = TextEditingController();
  TextEditingController controllerPw = TextEditingController();
  bool _obscurePassword = true;

  TextEditingController controller = TextEditingController();
  String ConfirmedEmail = '123';
  String ConfirmedPw = '456';

  @override
  void dispose(){
    controllerEmail.dispose();
    controllerPw.dispose();

    super.dispose();
  }


  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(children: [
            HeroWidget(title: 'Login',),
            SizedBox(height: 20.0,),
            TextField(
              controller: controllerEmail,
              decoration: InputDecoration(
                hintText: 'Email',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15.0),
                ),

              ),
            ),
            SizedBox(height: 10.0,),
            TextField(
              controller: controllerPw,
              obscureText: _obscurePassword,

              decoration: InputDecoration(
                hintText: 'Password',

                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15.0),
                ),

                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
              ),
            ),
            SizedBox(height: 20.0,),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueGrey,
                minimumSize: Size(double.infinity, 40.0),
              ),

              onPressed: () {
               return onLoginPressed();


              },
              child: Text('Login',
              style: TextStyle(
                color:Colors.black,
              ),
              ),



            ),
          ],
          ),
      ),
    );
  }
void onLoginPressed(){
    if(ConfirmedEmail == controllerEmail.text &&
        ConfirmedPw == controllerPw.text){
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration:Duration(seconds: 5),
          content: Text('Logged In'),
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
}
}
}

