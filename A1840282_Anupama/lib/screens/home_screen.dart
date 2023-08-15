import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:watchdog_correct/screens/signin_screen.dart';

import '../reusable_widgets/app_bar.dart';
import '../reusable_widgets/patient_card.dart';
import '../utils/color_utils.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedSortOption = 'Default';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MyAppBar(), // menu
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
