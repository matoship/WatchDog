import 'package:flutter/material.dart';
import 'package:watchdog_correct/reusable_widgets/text_box.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Profile')),
      body: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        decoration: BoxDecoration(gradient: backgroundGradient()),
        child: Column(
          children: [
            CircleAvatar(
              backgroundImage: NetworkImage('https://image.shutterstock.com/image-photo/closeup-portrait-old-man-260nw-62671255.jpg'),
            ),
            isEditing
                ? TextField(
              decoration: InputDecoration(labelText: 'Full Name'),
              onChanged: (value) {
                setState(() {
                  fullName = value;
                });
              },
            )
                : MyTextBox(text: fullName, sectionName: fullName),
            isEditing
                ? TextField(
              decoration: InputDecoration(labelText: 'Phone Number'),
              onChanged: (value) {
                setState(() {
                  phoneNumber = value;
                });
              },
            )
                : Text(phoneNumber),
            isEditing
                ? TextField(
              decoration: InputDecoration(labelText: 'Address'),
              onChanged: (value) {
                setState(() {
                  address = value;
                });
              },
            )
                : Text(address),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      if (isEditing) {
                        // Save changes
                      }
                      isEditing = !isEditing;
                    });
                  },
                  child: Text(isEditing ? 'Save' : 'Edit'),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Show confirmation dialog for account removal
                    showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: Text('Remove Account'),
                          content: Text(
                              'Are you sure you want to remove your account?'),
                          actions: [
                            TextButton(
                              onPressed: () {
                                // Perform account removal
                                Navigator.pop(context);
                              },
                              child: Text('Yes'),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              child: Text('No'),
                            ),
                          ],
                        );
                      },
                    );
                  },
                  child: Text('Remove Account'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
