import 'dart:async';
import 'package:flutter/material.dart';
import 'package:xiu_to_xiandi_tuixiu/models/character.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/meditation_widget.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/cultivator_info_card.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/back_button_overlay.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/effects/break_through_aura.dart';
import 'package:xiu_to_xiandi_tuixiu/utils/cultivation_level.dart';
import 'package:xiu_to_xiandi_tuixiu/services/cultivation_tracker.dart';
import 'package:xiu_to_xiandi_tuixiu/utils/format_large_number.dart';
import 'package:xiu_to_xiandi_tuixiu/services/player_storage.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/resource_bar.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/dialogs/aptitude_upgrade_dialog.dart';

class CharacterPage extends StatefulWidget {
  const CharacterPage({super.key});

  @override
  State<CharacterPage> createState() => _CharacterPageState();
}

class _CharacterPageState extends State<CharacterPage> {
  late Character player;
  late CultivationLevelDisplay display;
  bool showAura = false;

  Future<void> _reloadData() async {
    final updated = await PlayerStorage.getPlayer();
    if (mounted && updated != null) {
      setState(() {
        player = updated;
      });
    }
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: Future.wait([
        PlayerStorage.getPlayer(),
        getDisplayLevelFromPrefs(),
      ]),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            backgroundColor: Colors.black,
            body: Center(child: CircularProgressIndicator(color: Colors.amber)),
          );
        }

        player = snapshot.data![0] as Character;
        display = snapshot.data![1] as CultivationLevelDisplay;
        final realmText = "${display.realm}${display.rank}层";

        return Scaffold(
          body: Stack(
            children: [
              Positioned.fill(
                child: Image.asset(
                  'assets/images/bg_xiuxian_mountain.webp',
                  fit: BoxFit.cover,
                ),
              ),
              ResourceBar(player: player),
              Align(
                alignment: const Alignment(0, 0.4),
                child: Column(
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
                            onComplete: () => setState(() => showAura = false),
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
                    CultivatorInfoCard(profile: player),
                  ],
                ),
              ),
              const BackButtonOverlay(),
              Positioned(
                top: 100,
                right: 30,
                child: Column(
                  children: [
                    FloatingActionButton(
                      mini: true,
                      backgroundColor: Colors.deepPurple,
                      onPressed: () async {
                        await CultivationTracker.applyRewardedExp(
                          display.current,
                          onUpdate: () => _reloadData(),
                        );
                      },
                      child: const Icon(Icons.bolt),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        minimumSize: const Size(40, 32),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      onPressed: () async {
                        await showDialog(
                          context: context,
                          builder: (context) => AptitudeUpgradeDialog(player: player),
                        );
                        await _reloadData();
                      },
                      child: const Text("升资质", style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
