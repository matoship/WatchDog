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

class PatientProfileScreenView extends StatefulWidget {
  final Map<String, dynamic> patientData;

  PatientProfileScreenView({required this.patientData});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<PatientProfileScreenView> {

  TextEditingController _firstNameTextController = TextEditingController();
  TextEditingController _lastNameTextController = TextEditingController();

  bool allowedInBed = false;
  bool allowedInRoom = false;

  // Editing state
  bool isEditing = false;

  PickedFile? _imageFile = null;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    // Load patient data when the widget is initialized
    loadPatientData();
  }

  void loadPatientData() {
    final patientData = widget.patientData;
    if (patientData != null) {
      _firstNameTextController.text = patientData['firstName'] ?? '';
      _lastNameTextController.text = patientData['lastName'] ?? '';
      allowedInBed = patientData['allowedInBed'] ?? false;
      allowedInRoom = patientData['allowedInRoom'] ?? false;
      // Load other data as needed
    }
  }

  void takePhoto(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);
    setState(() {
      if (pickedFile != null) {
        _imageFile = PickedFile(pickedFile.path);
      } else {
        _imageFile = null;
      }
    });

    Navigator.pop(context);
  }

  Future<void> updateProfileData() async {
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

      final Map<String, dynamic> profileUpdate = {
        'firstName': _firstNameTextController.text,
        'lastName': _lastNameTextController.text,
        'allowedInBed': allowedInBed,
        'allowedInRoom': allowedInRoom,
        // 'imageUrl': imageBase64
        // Add other fields you want to update
      };

      // Construct the Firebase Realtime Database endpoint URL
      final databaseUrl = 'https://us-central1-watchdog-gamma.cloudfunctions.net/app/patients/${FirebaseAuth.instance.currentUser?.uid}';

      try {
        final response = await http.put(
          Uri.parse(databaseUrl),
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
          },
          body: json.encode(profileUpdate),
        );

        if (response.statusCode == 200) {
          EasyLoading.showSuccess('Profile successfully updated!');
        } else {
          // Handle the error
          print('Failed to update profile data. Status code: ${response.body}');
          EasyLoading.showError('Failed to update profile data');
        }
      } catch (error) {
        // Handle the error
        print('Error updating profile data: $error');
      }
      EasyLoading.dismiss();
    }
  }


  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Profile'),
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
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                // Toggle the editing state
                isEditing = !isEditing;
                if (isEditing) {
                  // Enable editing mode - populate text fields with data
                  loadPatientData();
                }
              });
            },
            icon: Icon(
              isEditing ? Icons.save : Icons.edit,
              color: Colors.black,
            ),
          ),
        ],
      ),
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
                            if (isEditing) {
                              showModalBottomSheet(
                                context: context,
                                builder: ((builder) => bottomSheet()),
                              );
                            }
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
              buildTextField(
                "First Name",
                _firstNameTextController.text ?? '',
                false,
                _firstNameTextController,
                    (value) {
                  if (isEditing) {
                    if (value!.isEmpty) {
                      return "Please enter your first name";
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(
                height: 20,
              ),
              buildTextField(
                "Last Name",
                _lastNameTextController.text ?? '',
                false,
                _lastNameTextController,
                    (value) {
                  if (isEditing) {
                    if (value!.isEmpty) {
                      return "Please enter your last name";
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(
                height: 20,
              ),
              // buildTextField(
              //   "Allowed in Bed",
              //   allowedInBed.toString() ?? '',
              //   false,
              //   allowedInBed as TextEditingController,
              //       (value) {
              //     if (isEditing) {
              //       if (value!.isEmpty) {
              //         return "Please enter a username";
              //       }
              //     }
              //     return null;
              //   },
              // ),
              // const SizedBox(
              //   height: 20,
              // ),
              // buildTextField(
              //   "Allowed in Room",
              //   allowedInRoom.toString() ?? '',
              //   false,
              //   allowedInRoom as TextEditingController,
              //       (value) {
              //     if (isEditing) {
              //       if (value!.isEmpty) {
              //         return "Please enter a username";
              //       }
              //     }
              //     return null;
              //   },
              // ),
              SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  OutlinedButton(
                    onPressed: () {
                      if (isEditing) {
                        // Handle cancel button when in editing mode
                        setState(() {
                          isEditing = false;
                        });
                        // Reload the profile data to discard changes
                        loadPatientData();
                      }
                    },
                    child: const Text(
                      "CANCEL",
                      style: TextStyle(
                        fontSize: 15,
                        letterSpacing: 2,
                        color: Colors.white,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      if (isEditing) {
                        // Handle save button when in editing mode
                        // Save the edited profile data
                        // You can access the entered values using the text controllers
                        updateProfileData();
                        setState(() {
                          isEditing = false;
                        });
                      } else {
                        // Handle edit button
                        setState(() {
                          isEditing = true;
                        });
                      }
                    },
                    child: Text(
                      isEditing ? "SAVE" : "EDIT",
                      style: TextStyle(
                        fontSize: 15,
                        letterSpacing: 2,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: EdgeInsets.symmetric(horizontal: 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget buildTextField(
      String labelText,
      String placeholder,
      bool isPasswordTextField,
      TextEditingController controller,
      String? Function(String?)? validator,
      ) {
    return Padding(
      padding: EdgeInsets.only(bottom: 30),
      child: TextFormField(
        controller: controller,
        obscureText: isPasswordTextField,
        enabled: isEditing,
        decoration: InputDecoration(
          contentPadding: EdgeInsets.only(bottom: 5),
          labelText: labelText,
          labelStyle: TextStyle(
            color: Colors.white70,
          ),
          floatingLabelBehavior: FloatingLabelBehavior.always,
          hintText: isEditing ? placeholder : '',
          hintStyle: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        validator: validator,
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
