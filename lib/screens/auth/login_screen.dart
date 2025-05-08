
import 'package:flutter/material.dart';
import 'package:grocery_app/common_widgets/app_button.dart';
import 'package:grocery_app/common_widgets/imput_widget.dart';
import 'package:grocery_app/screens/auth/signup_screen.dart' show SignupScreen;
import 'package:grocery_app/screens/home/home_screen.dart';
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key });

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(actions: [
        TextButton(onPressed: (){
          Navigator.push(context , MaterialPageRoute(builder: (context) => HomeScreen(),));
        }, child: Text("Skip"))
      ],),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children:[ 
            Text("let's get started" , style: TextStyle(fontWeight: FontWeight.normal , fontSize: 20),),
            SizedBox(height: 5,),
            Text("Login" , style: TextStyle(fontWeight: FontWeight.normal , fontSize: 30),),
          SizedBox(height: 15,),
           CustomInput(hintText: "Email", obscureText: false,controller: TextEditingController(),),
          SizedBox(height: 20,),
          CustomInput(hintText: "Password", obscureText: true,controller: TextEditingController(),),
          SizedBox(height: 20,),
          AppButton(label: "Login", fontWeight: FontWeight.bold, padding: EdgeInsets.symmetric(vertical: 20),),
          SizedBox(height: 10,),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("New to Anaad Foods ?"),
              TextButton(onPressed: (){
                Navigator.push(context , MaterialPageRoute(builder: (context) => SignupScreen(),));
              }, child: Text("Sign Up"))
            ],
          ),
          SizedBox(height: 5,),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Forgot Password ?"),
              TextButton(onPressed: (){}, child: Text("Reset Password"))
            ],
          ),
          SizedBox(height: 10,),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(1.0),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(50.0),
                ),
                child: IconButton(
                  icon: Icon(Icons.g_mobiledata, size: 25), // Google icon placeholder
                  onPressed: () {
                    // Handle Google login
                  },
                ),
              ),
              SizedBox(width: 20),
              Container(
                padding: EdgeInsets.all(1.0),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(50.0),
                ),
                child: IconButton(
                  icon: Icon(Icons.apple, size: 25), // Apple icon placeholder
                  onPressed: () {
                    // Handle Apple login
                  },
                ),
              ),
            ],
          )
          ],
        ),
      ),
    );
  }
}