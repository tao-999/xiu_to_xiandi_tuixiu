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
        backgroundColor: const Color(0xFFF9F5E3),
        foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13, // 👈 你想要多大就改这个值
        ),
      ),
    );
  }
}
