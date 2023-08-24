import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:watchdog_correct/reusable_widgets/text_box.dart';
import 'package:watchdog_correct/screens/home_screen.dart';

import '../utils/color_utils.dart';

class Patient {
  final String name;

  Patient({required this.name});
}

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

  PickedFile ? _imageFile;
  final ImagePicker _picker = ImagePicker();
  List<Patient> assignedPatients = [
    Patient(name: 'Kaifeng'),
    Patient(name: 'ooom'),
    Patient(name: 'Revaan'),
    // Add more patients as needed
  ];

  void takePhoto(ImageSource source) async {
    final pickedFile = await _picker.pickImage(
      source: source,
    );
    setState(() {
      _imageFile = pickedFile as PickedFile;
    });
  }

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
                            image: _imageFile == null
                                ? AssetImage("assets/images/albert_dp.avif")
                                : AssetImage("assets/images/albert_dp.avif"),
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
                          child: InkWell(
                            onTap: () {
                              showModalBottomSheet(
                                  context: context,
                                  builder: ((builder) => bottomSheet())
                              );
                            },
                            child: Icon(
                              Icons.edit,
                              color: Colors.white,
                            ),
                          ),
                        )
                    )
                  ],
                ),
              ),
              SizedBox(height: 30),
              buildTextField("Full Name", "Anupama Dilshan", false),
              buildTextField("Email", "anupama.dilshan@icloud.com", false),
              buildTextField("Password", "******", true),
              buildTextField("Phone No", "0452575523", false),
              buildTextField("Address", "Adelaide CDB", false),
              buildTextField("Assigned Patients", assignedPatients.map((patient) => patient.name).join(', '), false),
              // Add the ListView.builder for the assigned patients
              // ListView.builder(
              //   shrinkWrap: true, // To allow the ListView to take the necessary height
              //   itemCount: assignedPatients.length,
              //   itemBuilder: (context, index) {
              //     final patient = assignedPatients[index];
              //     return buildTextField("Address", patient.name, false);
              //   },
              // ),
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

  Widget bottomSheet() {
    return Container(
      height: 100.0,
      width: MediaQuery.of(context).size.width,
      margin: EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 20,
      ),
      child: Column(
        children: <Widget>[
          Text(
            "Choose Profile photo",
            style: TextStyle(
              fontSize: 20.0,
            ),
          ),
          SizedBox(
            height: 20,
          ),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
            ElevatedButton.icon(
              icon: Icon(Icons.camera),
              onPressed: () {
                takePhoto(ImageSource.camera);
              },
              label: Text("Camera"),
            ),
            ElevatedButton.icon(
              icon: Icon(Icons.image),
              onPressed: () {
                takePhoto(ImageSource.gallery);
              },
              label: Text("Gallery"),
            ),
          ])
        ],
      ),
    );
  }

}
