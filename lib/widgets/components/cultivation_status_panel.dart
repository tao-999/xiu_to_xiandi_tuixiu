import 'package:flutter/material.dart';
import 'package:xiu_to_xiandi_tuixiu/models/character.dart';
import 'package:xiu_to_xiandi_tuixiu/utils/format_large_number.dart';
import 'package:xiu_to_xiandi_tuixiu/utils/cultivation_level.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/meditation_widget.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/effects/break_through_aura.dart';

class CultivationStatusPanel extends StatelessWidget {
  final Character player;
  final CultivationLevelDisplay display;
  final bool showAura;
  final VoidCallback? onAuraComplete;

  const CultivationStatusPanel({
    super.key,
    required this.player,
    required this.display,
    this.showAura = false,
    this.onAuraComplete,
  });

  @override
  Widget build(BuildContext context) {
    final realmText = "${display.realm}${display.rank}层";

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            MeditationWidget(
              imagePath: player.gender == 'female'
                  ? 'assets/images/icon_dazuo_female_256.png'
                  : 'assets/images/icon_dazuo_male_256.png',
              ready: true,
              offset: const AlwaysStoppedAnimation(Offset.zero),
              opacity: const AlwaysStoppedAnimation(1.0),
              createdAt: DateTime.now().subtract(const Duration(hours: 3)),
            ),
            if (showAura)
              BreakthroughAura(
                onComplete: onAuraComplete,
              ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 32),
          child: Column(
            children: [
              Text(
                realmText,
                style: const TextStyle(
                  color: Colors.black54,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "修为：${formatLargeNumber(display.current)} / ${formatLargeNumber(display.max)}",
                style: const TextStyle(color: Colors.black45, fontSize: 14),
              ),
              const SizedBox(height: 4),
              LinearProgressIndicator(
                value: (display.current / display.max).clamp(0.0, 1.0),
                backgroundColor: Colors.white24,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.orangeAccent),
                minHeight: 10,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
