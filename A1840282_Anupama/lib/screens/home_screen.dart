import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:watchdog_correct/reusable_widgets/drawer.dart';
import 'package:watchdog_correct/screens/caregiver_profile_view.dart';
import 'package:watchdog_correct/screens/signin_screen.dart';
import 'package:http/http.dart' as http;
import '../classes/caregiver_class.dart';
import '../reusable_widgets/app_bar.dart';
import '../reusable_widgets/patient_card.dart';
import '../reusable_widgets/user_profile_provider.dart';
import '../utils/color_utils.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedSortOption = 'Default';

  Future<void> fetchUserProfile() async {
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
          phone: responseData['phone'] ?? '',
          assignedPatients: (responseData['assignedPatients'] as List<dynamic>?)
              ?.map((patientName) => Patient(name: patientName.toString()))
              ?.toList() ?? [],
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

  @override
  void initState() {
    super.initState();
    fetchUserProfile();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MyAppBar(), // menu
      drawer: MyDrawer(
        onProfileTap: () => {
          Navigator.pop(context),
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ProfileScreenView()),
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
            children: List.generate(
              10, // Replace with the number of cards you want
                  (index) => PatientCard(
                name: 'Patient $index',
                photoUrl: 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSLhi4qVtieeHmMjiglFczNiG1ijmVPa6BwGA&usqp=CAU',
                bedNumber: 'Bed $index',
                roomNumber: 'Room $index',
                age: 25 + index,
                isInRoom: index % 2 == 0, // Example: every even index is in room
                isInBed: index % 2 == 1, // Example: every odd index is in bed
              ),
            ),
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
