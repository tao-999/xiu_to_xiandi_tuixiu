import 'package:flutter/material.dart';

class CultivatorInfoCard extends StatelessWidget {
  final String name;
  final String realm;
  final Map<String, int> elements;
  final int currentQi;
  final int maxQi;
  final String technique;

  const CultivatorInfoCard({
    super.key,
    required this.name,
    required this.realm,
    required this.elements,
    required this.currentQi,
    required this.maxQi,
    required this.technique,
  });

  @override
  Widget build(BuildContext context) {
    final percent = (currentQi / maxQi).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFEEDCB7), // 背景色：古卷纸风
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFBFA373), // 边框色：土金混合（低饱和度）
            width: 2.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.brown.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(2, 4),
            )
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$name · $realm',
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.black87,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '五行属性：金${elements['金']} 木${elements['木']} 水${elements['水']} 火${elements['火']} 土${elements['土']}',
                style: const TextStyle(fontSize: 14, color: Colors.black87),
              ),
              const SizedBox(height: 8),
              Text(
                '灵气值：$currentQi / $maxQi',
                style: const TextStyle(fontSize: 14, color: Colors.black87),
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: percent,
                  backgroundColor: Colors.black12,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.teal.shade700),
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '当前心法：$technique',
                style: const TextStyle(fontSize: 14, color: Colors.black87),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
