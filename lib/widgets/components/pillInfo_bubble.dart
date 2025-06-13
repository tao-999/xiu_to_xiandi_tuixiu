import 'package:flutter/material.dart';
import 'package:xiu_to_xiandi_tuixiu/models/pill_recipe.dart';

class PillInfoBubble extends StatelessWidget {
  final PillRecipe pill;

  const PillInfoBubble({super.key, required this.pill});

  @override
  Widget build(BuildContext context) {
    final effectType = switch (pill.type) {
      PillType.attack => '攻击',
      PillType.defense => '防御',
      PillType.health => '血气',
    };

    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFFFCF5E5),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.orangeAccent),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 6,
              offset: Offset(2, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("材料：${pill.requirements.join('、')}",
                style: const TextStyle(fontSize: 10, color: Colors.brown)),
            const SizedBox(height: 2),
            Text("效果：$effectType +${pill.effectValue}",
                style: const TextStyle(fontSize: 10, color: Colors.deepOrange)),
          ],
        ),
      ),
    );
  }
}
