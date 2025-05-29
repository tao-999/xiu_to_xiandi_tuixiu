import 'package:flutter/material.dart';

class BackButtonOverlay extends StatelessWidget {
  const BackButtonOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 16,
      bottom: 16,
      child: GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.4),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.arrow_back, size: 20, color: Colors.white),
              SizedBox(width: 6),
              Text('返回', style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }
}
