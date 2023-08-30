import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:watchdog_correct/reusable_widgets/reusable_widget.dart';
import 'package:watchdog_correct/utils/color_utils.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'home_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  TextEditingController _passwordTextController = TextEditingController();
  TextEditingController _emailTextController = TextEditingController();
  TextEditingController _userNameTextController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "Sign Up",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
      body: Container(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          decoration: BoxDecoration(
              gradient: backgroundGradient()),
          child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 120, 20, 0),
                child: Column(
                  children: <Widget>[
                    const SizedBox(
                      height: 20,
                    ),
                    reusableTextField("Enter UserName", Icons.person_outline, false,
                        _userNameTextController),
                    const SizedBox(
                      height: 20,
                    ),
                    reusableTextField("Enter Email Id", Icons.person_outline, false,
                        _emailTextController),
                    const SizedBox(
                      height: 20,
                    ),
                    reusableTextField("Enter Password", Icons.lock_outlined, true,
                        _passwordTextController),
                    const SizedBox(
                      height: 20,
                    ),
                    firebaseUIButton(context, "Sign up", () async {
                      try {
                        await FirebaseAuth.instance
                            .createUserWithEmailAndPassword(
                            email: _emailTextController.text,
                            password: _passwordTextController.text)
                            .then((value) async {

                          // Create a map with the user data to send to the API
                          final Map<String, dynamic> userData = {
                            'userId': FirebaseAuth.instance.currentUser?.uid,
                            'username': _userNameTextController.text,
                            'email': _emailTextController.text,
                            'firstName': '',
                            'lastName': '',
                            'phone': '',
                            'assignedPatients': []
                            // Add other user data here
                          };

                          // Encode the userData map to JSON and exclude undefined values
                          final jsonData = json.encode(userData, toEncodable: (dynamic value) {
                            if (value == null) {
                              return null;
                            }
                            return value;
                          });

                          final response = await http.post(
                            Uri.parse('https://us-central1-watchdog-gamma.cloudfunctions.net/app/caregivers'), // Replace with your API endpoint URL
                            headers: {'Content-Type': 'application/json'},
                            body: jsonData,
                          );

                          print(response.body);
                          print(jsonData);

                          if (response.statusCode == 200) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Created New Account')));
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => HomeScreen()),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Failed to add user')));
                          }
                        });
                      } catch (error) {
                        // Handle different error scenarios
                        if (error is FirebaseAuthException) {
                          String errorMessage = '';

                          if (error.code == 'email-already-in-use') {
                            errorMessage = 'The email address is already in use by another account.';
                          } else if (error.code == 'weak-password') {
                            errorMessage = 'The password is too weak.';
                          } else if (error.code == 'invalid-email') {
                            errorMessage = 'Invalid email address.';
                          } else {
                            errorMessage = 'An error occurred: ${error.message}';
                          }

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(errorMessage)),
                          );
                        } else {
                          // Fallback for any other errors
                          print("Error: $error");
                        }
                      }
                    })
                  ],
                ),
              ))),
    );
  }
}