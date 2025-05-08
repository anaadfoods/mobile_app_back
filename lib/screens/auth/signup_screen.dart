
import 'package:flutter/material.dart';
import 'package:grocery_app/common_widgets/app_button.dart';
import 'package:grocery_app/common_widgets/imput_widget.dart';
import 'package:grocery_app/screens/auth/login_screen.dart';
class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key });

  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children:[
             Text("let's get started" , style: TextStyle(fontWeight: FontWeight.normal, fontSize: 20),),
          SizedBox(height: 5,),
             Text("Signup" , style: TextStyle(fontWeight: FontWeight.normal, fontSize: 30),),
          SizedBox(height: 15,),
           CustomInput(hintText: "Name", obscureText: false,controller: TextEditingController(),),
          SizedBox(height: 20,),
           CustomInput(hintText: "Email", obscureText: false,controller: TextEditingController(),),
          SizedBox(height: 20,),
          CustomInput(hintText: "Password", obscureText: true,controller: TextEditingController(),),
          SizedBox(height: 20,),
          AppButton(label: "Sign Up", fontWeight: FontWeight.bold, padding: EdgeInsets.symmetric(vertical: 20),),
          SizedBox(height: 10,),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Have an account ?"),
              TextButton(onPressed: (){
                Navigator.push(context , MaterialPageRoute(builder: (context) => LoginScreen(),));
              }, child: Text('Login'))
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