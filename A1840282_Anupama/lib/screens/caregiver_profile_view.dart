import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:watchdog_correct/reusable_widgets/reusable_widget.dart';
import 'package:watchdog_correct/reusable_widgets/text_box.dart';
import 'package:watchdog_correct/screens/caregiver_profile.dart';
import 'package:watchdog_correct/screens/home_screen.dart';

import '../utils/color_utils.dart';

class CaregiverProfile {
  final String id;
  final String username;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final List<dynamic> assignedPatients;

  CaregiverProfile({
    required this.id,
    required this.username,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.assignedPatients,
  });
}

class Patient {
  final String name;

  Patient({required this.name});
}

class ProfileScreenView extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();

}

class _ProfileScreenState extends State<ProfileScreenView> {

  late CaregiverProfile caregiver = CaregiverProfile(
      id: '',
      username: '',
      firstName: '',
      lastName: '',
      email: '',
      phone: '',
      assignedPatients: []
  );

  // Editing state
  bool isEditing = false;
  bool isObscurePassword = true;



  PickedFile? _imageFile = null;
  final ImagePicker _picker = ImagePicker();

  List<Patient> assignedPatients = [
    Patient(name: 'Kaifeng'),
    Patient(name: 'ooom'),
    Patient(name: 'Revaan'),
    // Add more patients as needed
  ];

  Future<void> fetchUserProfile() async {
    // Replace this URL with your actual API endpoint
    final url = 'https://us-central1-watchdog-gamma.cloudfunctions.net/app/caregivers/${FirebaseAuth.instance.currentUser?.uid}';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body)['data'];

        setState(() {
          caregiver = CaregiverProfile(
            id: responseData['id'] ?? '',
            username: responseData['username'] ?? '',
            firstName: responseData['firstName'] ?? '',
            lastName: responseData['lastName'] ?? '',
            email: responseData['email'] ?? '',
            phone: responseData['phone'] ?? '',
            assignedPatients: (responseData['assignedPatients'] as List<dynamic>?)
                ?.map((patientName) => Patient(name: patientName.toString()))
                ?.toList() ?? [],
          );
        });
        // print(userData['email']);
        print(FirebaseAuth.instance.currentUser?.uid);
        print(response.body);
      } else {
        // Handle error response
        print('Failed to fetch user details: ${response.statusCode}');
      }
    } catch (error) {
      // Handle network error
      print('Error fetching user details: $error');
    }
  }

  @override
  void initState() {
    super.initState();
    fetchUserProfile();
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
                onPressed: (){
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ProfileScreen()),
                  );
                },
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
                                ? AssetImage("assets/images/albert_dp.avif") as ImageProvider<Object>
                                : FileImage(File(_imageFile?.path ?? '')),
                          )
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 30),
              buildTextFieldViewValue("First Name", caregiver.firstName),
              buildTextFieldViewValue("Last Name", caregiver.lastName),
              buildTextFieldViewValue("Username", caregiver.username),
              // buildTextFieldViewValue("Password", "******"),
              buildTextFieldViewValue("Email", caregiver.email),
              buildTextFieldViewValue("Phone No", caregiver.phone),
              buildTextFieldViewValue("Assigned Patients", caregiver.assignedPatients.toString()),
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

}
