import 'package:flutter/material.dart';

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
      leading: IconButton(
        icon: Icon(Icons.account_circle),
        onPressed: () {
          // Implement your profile screen logic here
        },
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.sort),
          onPressed: () {
            // Implement your sort logic here
          },
        ),
        IconButton(
          icon: Icon(Icons.logout),
          onPressed: () {
            // Implement your logout logic here
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
      centerTitle: false,
      backgroundColor: Colors.transparent,
      elevation: 0,
      actionsIconTheme: IconThemeData(color: Colors.black),
    );
  }
}
