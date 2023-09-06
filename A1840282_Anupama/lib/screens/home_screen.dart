import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:provider/provider.dart';
import 'package:watchdog_correct/classes/patient_class.dart';
import 'package:watchdog_correct/reusable_widgets/drawer.dart';
import 'package:watchdog_correct/screens/caregiver_profile.dart';
import 'package:watchdog_correct/screens/caregiver_profile_view.dart';
import 'package:watchdog_correct/screens/signin_screen.dart';
import 'package:http/http.dart' as http;
import '../classes/caregiver_class.dart';
import '../reusable_widgets/app_bar.dart';
import '../reusable_widgets/patient_card.dart';
import '../reusable_widgets/user_profile_provider.dart';
import '../utils/color_utils.dart';
import 'add_patient_profile.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedSortOption = 'Default';
  List<dynamic> patientsList = [];

  Future<void> fetchUserProfile() async {
    EasyLoading.show(status: 'loading...');
    final url = 'https://us-central1-watchdog-gamma.cloudfunctions.net/app/caregivers/${FirebaseAuth.instance.currentUser?.uid}';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body)['data'];

        final caregiverProfile = CaregiverProfile(
          id: responseData['id'] ?? '',
          username: responseData['username'] ?? '',
          firstName: responseData['firstName'] ?? '',
          lastName: responseData['lastName'] ?? '',
          email: responseData['email'] ?? '',
          phone: responseData['phone'] ?? '', assignedPatients: [],
          // assignedPatients: List<String>.from(responseData['assignedPatients']) ?? [],
        );

        // Update the cached profile in UserProfileProvider
        context.read<UserProfileProvider>().setCachedProfile(caregiverProfile);

      } else {
        print('Failed to fetch user details: ${response.statusCode}');
      }
    } catch (error) {
      print('Error fetching user details: $error');
    }
  }

  Future<void> fetchPatients() async {
    String? currentUserUID = FirebaseAuth.instance.currentUser?.uid;
    String url = 'https://us-central1-watchdog-gamma.cloudfunctions.net/app/getpatientList?id=$currentUserUID';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final List<dynamic> responseData = json.decode(response.body)['data'];
        patientsList = responseData;
        print(responseData);

      } else {
        print('Failed to fetch patients details: ${response.statusCode}');
      }
    } catch (error) {
      print('Error fetching user details: $error');
    }
    EasyLoading.dismiss();
  }

  @override
  void initState() {
    super.initState();
    fetchUserProfile();
    fetchPatients();
  }

  @override
  Widget build(BuildContext context) {
    final cachedProfile = context.watch<UserProfileProvider>().cachedProfile;

    return Scaffold(
      appBar: MyAppBar(), // menu
      drawer: MyDrawer(
        onProfileTap: () => {
          Navigator.pop(context),
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ProfileScreen()),
          )
        },
        onLogoutTap: () => {
          FirebaseAuth.instance.signOut(),
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => SignInScreen()),
          )
        },
      ),
      body: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        decoration: BoxDecoration(gradient: backgroundGradient()),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Welcome, ${cachedProfile?.username ?? ""}',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => PatientProfileScreen())
                        );
                      },
                      child: Text('Add Patients'),
                    ),
                  ],
                ),
              ),

              SingleChildScrollView(
                child: Column(
                  children: [
                    ListView.builder(
                      shrinkWrap: true,
                      itemCount: patientsList.length, // Use the length of the fetched data
                      itemBuilder: (context, index) {
                        final patientData = patientsList[index];
                        print(patientData);
                        return PatientCard(
                          id: patientData['id'],
                          firstName: patientData['firstName'],
                          lastName: patientData['lastName'],
                          imageUrl: 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSLhi4qVtieeHmMjiglFczNiG1ijmVPa6BwGA&usqp=CAU', // Use the patient's image URL
                          allowedInRoom : patientData['allowedInRoom'], // You can customize this based on patientData
                          allowedInBed: patientData['allowedInBed'],
                          careGiverId: patientData['careGiverId'], // You can customize this based on patientData
                        );
                      },
                    ),
                  ],
                ),
              )

            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search...',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildSortDropdownButton() {
    return DropdownButton<String>(
      value: _selectedSortOption,
      onChanged: (newValue) {
        setState(() {
          _selectedSortOption = newValue!;
        });
        // Implement sort logic here based on selected option
      },
      items: <String>['Default', 'Name', 'Date', 'Rating'].map<DropdownMenuItem<String>>(
            (String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value),
          );
        },
      ).toList(),
    );
  }
}
