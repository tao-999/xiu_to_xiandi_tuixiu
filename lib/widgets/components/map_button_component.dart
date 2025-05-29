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
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      child: Text(text),
    );
  }
}
