import 'package:flutter/material.dart';
import 'package:watchdog_correct/reusable_widgets/text_box.dart';
import 'package:watchdog_correct/screens/home_screen.dart';

import '../utils/color_utils.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Profile details
  String fullName = 'John Doe';
  String phoneNumber = '123-456-7890';
  String address = '123 Main St';

  // Editing state
  bool isEditing = false;
  bool isObscurePassword = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
        leading: IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => HomeScreen()),
              );
            },
            icon: Icon(
              Icons.arrow_back,
              color: Colors.black,
            )),
        actions: [
          IconButton(
              onPressed: (){},
              icon: const Icon(
                Icons.settings,
                color: Colors.black,
              ))
        ]),
      body: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        decoration: BoxDecoration(gradient: backgroundGradient()),
        padding: EdgeInsets.only(left: 15, top: 20, right: 15),
        child: GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();
          },
          child: ListView(
            children: [
              Center(
                child: Stack(
                  children: [
                    Container(
                      width: 130,
                      height: 130,
                      decoration: BoxDecoration(
                          border: Border.all(width: 4, color: Colors.white),
                          boxShadow: [
                            BoxShadow(
                                spreadRadius: 2,
                                blurRadius: 10,
                                color: Colors.black.withOpacity(0.1)
                            )
                          ],
                          shape: BoxShape.circle,
                          image: DecorationImage(
                              fit: BoxFit.cover,
                              image: NetworkImage(
                                  'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSLhi4qVtieeHmMjiglFczNiG1ijmVPa6BwGA&usqp=CAU'
                              )
                          )
                      ),
                    ),
                    Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          height: 40,
                          width: 40,
                          decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                  width: 4,
                                  color: Colors.white
                              ),
                              color: Colors.blue
                          ),
                          child: Icon(
                            Icons.edit,
                            color: Colors.white,
                          ),
                        )
                    )
                  ],
                ),
              ),
              SizedBox(height: 30),
              buildTextField("Full Name", "Demon", false),
              buildTextField("Email", "anupama.dilshan@icloud.com", false),
              buildTextField("Password", "******", true),
              buildTextField("Address", "Adelaide CDB", false),
              SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  OutlinedButton(
                      onPressed: () {},
                      child: const Text("CANCEL",
                        style: TextStyle(
                          fontSize: 15,
                          letterSpacing: 2,
                          color: Colors.white
                        )),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))
                    ),
                  ),
                  ElevatedButton(
                      onPressed: () {},
                      child: Text("SAVE", style: TextStyle(
                        fontSize: 15,
                        letterSpacing: 2,
                        color: Colors.white
                      )),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: EdgeInsets.symmetric(horizontal: 50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))
                    ),
                  )
                ],
              )
            ],
          ),
        ),

      ),
    );
  }

  Widget buildTextField(String labelText, String placeholder, bool isPasswordTextField){
    return Padding(
      padding: EdgeInsets.only(bottom: 30),
      child: TextField(
        obscureText: isPasswordTextField ? isObscurePassword : false,
        decoration: InputDecoration(
          suffixIcon: isPasswordTextField ?
          IconButton(
              onPressed: () {},
              icon: Icon(Icons.remove_red_eye, color: Colors.white)
          ): null,
          contentPadding: EdgeInsets.only(bottom: 5),
          labelText: labelText,
          labelStyle: TextStyle(
            color: Colors.white70
          ),
          floatingLabelBehavior: FloatingLabelBehavior.always,
          hintText: placeholder,
          hintStyle: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white
          ),
        ),
      ),
    );
  }
}
