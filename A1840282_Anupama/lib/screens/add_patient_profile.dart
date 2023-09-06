import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:watchdog_correct/classes/caregiver_class.dart';
import 'package:watchdog_correct/classes/patient_class.dart';
import 'package:watchdog_correct/reusable_widgets/reusable_widget.dart';
import 'package:watchdog_correct/reusable_widgets/user_profile_provider.dart';
import 'package:watchdog_correct/reusable_widgets/validation_utils.dart';
import 'package:watchdog_correct/screens/home_screen.dart';
import 'package:watchdog_correct/utils/color_utils.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'caregiver_profile_view.dart';

class PatientProfileScreen extends StatefulWidget {
  @override
  _PatientProfileScreenState createState() => _PatientProfileScreenState();
}

class _PatientProfileScreenState extends State<PatientProfileScreen> {

  TextEditingController _firstNameTextController = TextEditingController();
  TextEditingController _lastNameTextController = TextEditingController();
  TextEditingController _assignedCaregiverTextController = TextEditingController();
  late CaregiverProfile assginedCaregiver;
  bool _allowedInBed = true;
  bool _allowedInRoom = true;

  // Editing state
  bool isEditing = false;
  bool isObscurePassword = true;

  PickedFile? _imageFile = null;
  final ImagePicker _picker = ImagePicker();

  void takePhoto(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);
    setState(() {
      if (pickedFile != null) {
        _imageFile = PickedFile(pickedFile.path);
      } else {
        _imageFile = null;
      }
    });

    print(_imageFile?.path);
    Navigator.pop(context);
  }

  Future<void> addProfileData() async {
    EasyLoading.show(status: 'loading...');
    final cachedProfile = context.read<UserProfileProvider>().cachedProfile;
    if (cachedProfile != null) {

      String? imageBase64;

      // Check if a new image was selected
      if (_imageFile != null) {
        final imageBytes = await _imageFile!.readAsBytes();

        // Encode the image bytes to base64
        imageBase64 = base64Encode(imageBytes);
      }

      final Map<String, dynamic> profileAdd = {
        'firstName': _firstNameTextController.text,
        'lastName': _lastNameTextController.text,
        'careGiverId': FirebaseAuth.instance.currentUser?.uid,
        'allowedInBed': _allowedInBed,
        'allowedInRoom': _allowedInRoom,
        'imageUrl': imageBase64
        // Add other fields you want to update
      };

      // Construct the Firebase Realtime Database endpoint URL
      const databaseUrl = 'https://us-central1-watchdog-gamma.cloudfunctions.net/app/patients';

      try {
        final response = await http.post(
          Uri.parse(databaseUrl),
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
          },
          body: json.encode(profileAdd),
        );

        if (response.statusCode == 200) {

          // Profile data updated successfully
          print('Profile data updated successfully');
          print(json.encode(profileAdd));
          EasyLoading.showSuccess('Patient successfully created!');
        } else {
          // Handle the error
          print('Failed to add profile data. Status code: ${response.body}');
          EasyLoading.showError('Failed to add patient data');
        }
      } catch (error) {
        // Handle the error
        print('Error adding patient data: $error');
      }
      EasyLoading.dismiss();
    }
  }


  @override
  Widget build(BuildContext context) {
    final cachedProfile = context.watch<UserProfileProvider>().cachedProfile;

    return Scaffold(
      appBar: AppBar(
        title: Text('Add Patient'),
      ),
      body: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        decoration: BoxDecoration(gradient: backgroundGradient()),
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                            color: Colors.black.withOpacity(0.1),
                          ),
                        ],
                        shape: BoxShape.circle,
                        image: DecorationImage(
                          fit: BoxFit.cover,
                          image: _imageFile == null
                              ? AssetImage("assets/images/empty-dp.png") as ImageProvider<Object>
                              : FileImage(File(_imageFile?.path ?? '')),
                        ),
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
                          border: Border.all(width: 4, color: Colors.white),
                          color: Colors.blue,
                        ),
                        child: InkWell(
                          onTap: () {
                              showModalBottomSheet(
                                context: context,
                                builder: ((builder) => bottomSheet()),
                              );
                          },
                          child: Icon(
                            Icons.edit,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 30),
              buildTextField('First Name', 'First Name', _firstNameTextController),
              buildTextField('Last Name', 'Last Name', _lastNameTextController),

              CheckboxListTile(
                title: Text('Allowed in Bed'),
                value: _allowedInBed,
                onChanged: (newValue) {
                  setState(() {
                    _allowedInBed = newValue ?? false;
                  });
                },
              ),
              CheckboxListTile(
                title: Text('Allowed in Room'),
                value: _allowedInRoom,
                onChanged: (newValue) {
                  setState(() {
                    _allowedInRoom = newValue ?? false;
                  });
                },
              ),
              // buildTextField('Assigned caregiver', 'Assigned caregiver', _assignedCaregiverTextController),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  addProfileData();
                },
                child: Text('Add Patient'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildTextField(
      String labelText,
      String placeholder,
      TextEditingController controller
      ) {
    return Padding(
      padding: EdgeInsets.only(bottom: 30),
      child: TextFormField(
        controller: controller,
        enabled: true,
        decoration: InputDecoration(
          contentPadding: EdgeInsets.only(bottom: 5),
          labelText: labelText,
          labelStyle: TextStyle(
            color: Colors.white70,
          ),
          floatingLabelBehavior: FloatingLabelBehavior.always,
          hintStyle: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
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
