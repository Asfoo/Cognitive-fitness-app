import 'package:flutter/material.dart';

class MyAppbar extends StatelessWidget implements PreferredSizeWidget {
  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);

  final String title;
  final Color backgroundColor;
  final Color shadowColor;

   MyAppbar({required this.title, this.backgroundColor = Colors.blue, this.shadowColor = Colors.blueAccent});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      backgroundColor: backgroundColor,
      elevation: 10,
      shadowColor: shadowColor,
      centerTitle: true,
      foregroundColor: Colors.white,
    );
  }
}
