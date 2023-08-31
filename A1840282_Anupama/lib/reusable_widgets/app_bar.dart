import 'package:flutter/material.dart';
import 'package:watchdog_correct/screens/caregiver_profile_view.dart';

import '../screens/caregiver_profile.dart';

class MyAppBar extends StatefulWidget implements PreferredSizeWidget {
  @override
  _MyAppBarState createState() => _MyAppBarState();

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
}

class _MyAppBarState extends State<MyAppBar> {
  @override
  Widget build(BuildContext context) {
    return AppBar(
      // leading: IconButton(
      //   icon: Icon(Icons.menu),
      //   onPressed: () {
      //     // Implement your navigation logic here
      //   },
      // ),
      actions: [
        IconButton(
          icon: Icon(Icons.sort),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ProfileScreenView()),
            );
          },
        ),
      ],
      title: Container(
        height: kToolbarHeight - 20, // Adjust the height as needed
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: TextField(
          decoration: InputDecoration(
            hintText: 'Search',
            contentPadding: EdgeInsets.symmetric(horizontal: 16),
            border: InputBorder.none,
          ),
        ),
      ),
      centerTitle: true,
    );
  }
}
