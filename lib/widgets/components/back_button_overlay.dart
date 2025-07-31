import 'package:flutter/material.dart';

class BackButtonOverlay extends StatelessWidget {
  final Widget? targetPage;

  const BackButtonOverlay({super.key, this.targetPage});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      bottom: -35,
      child: GestureDetector(
        onTap: () {
          if (targetPage != null) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => targetPage!),
            );
          } else {
            Navigator.of(context).pop();
          }
        },
        child: SizedBox(
          width: 82,
          height: 82,
          child: Image.asset(
            'assets/images/back.png',
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
