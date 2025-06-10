import 'package:flutter/material.dart';

class MapButtonComponent extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  const MapButtonComponent({
    super.key,
    required this.text,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          color: Colors.white,
          fontFamily: 'ZcoolCangEr',
        ),
      ),
    );
  }
}
