import 'package:flutter/material.dart';

class XianrenDialog extends StatelessWidget {
  final String name;
  final String description;
  final String imagePath; // 缩略图
  final int aptitude;
  final VoidCallback? onJoinSect;

  const XianrenDialog({
    super.key,
    required this.name,
    required this.description,
    required this.imagePath,
    required this.aptitude,
    this.onJoinSect,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      backgroundColor: const Color(0xFFFFF8DC), // 米黄色
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.zero, // 直角
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '仙人来访',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Image.asset(
              imagePath,
              width: 160,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 12),
            Text(
              name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF8E44AD),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '资质：$aptitude',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () {
                // 🚨这里不再 pop，由外部决定
                if (onJoinSect != null) {
                  onJoinSect!();
                }
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.add, size: 20, color: Colors.black87),
                  SizedBox(width: 6),
                  Text(
                    '加入宗门',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                '下次再会',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.blueGrey,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
