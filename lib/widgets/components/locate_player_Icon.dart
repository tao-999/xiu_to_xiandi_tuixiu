import 'package:flutter/material.dart';

class LocatePlayerIcon extends StatelessWidget {
  final VoidCallback onLocate;

  const LocatePlayerIcon({
    Key? key,
    required this.onLocate,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topRight,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: GestureDetector(
          onTap: onLocate,
          child: Icon(
            Icons.my_location,
            size: 28,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
