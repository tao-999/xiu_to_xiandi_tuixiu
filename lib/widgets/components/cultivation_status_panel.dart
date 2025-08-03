import 'package:flutter/material.dart';
import 'package:xiu_to_xiandi_tuixiu/models/character.dart';
import 'package:xiu_to_xiandi_tuixiu/services/player_storage.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/meditation_widget.dart';
import '../../utils/cultivation_level.dart';
import '../dialogs/cultivator_info_card_dialog.dart';
import 'cultivation_progress_bar.dart';

class CultivationStatusPanel extends StatefulWidget {
  final Character player;
  final CultivationLevelDisplay display;
  final bool showAura;
  final VoidCallback? onAuraComplete;
  final VoidCallback? onChanged;

  const CultivationStatusPanel({
    super.key,
    required this.player,
    required this.display,
    this.showAura = false,
    this.onAuraComplete,
    this.onChanged,
  });

  @override
  State<CultivationStatusPanel> createState() => _CultivationStatusPanelState();
}

class _CultivationStatusPanelState extends State<CultivationStatusPanel> {
  late Character _player;

  @override
  void initState() {
    super.initState();
    _player = widget.player;
  }

  String getMeditationImagePath() {
    final isFemale = _player.gender == 'female';
    return isFemale
        ? 'assets/images/dazuo_female.png'
        : 'assets/images/dazuo_male.png';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            GestureDetector(
              onTap: () {
                CultivatorInfoCardDialog.show(
                  context: context,
                  player: _player,
                  display: widget.display,
                  onUpdated: () async {
                    final updatedPlayer = await PlayerStorage.getPlayer();
                    if (updatedPlayer == null) return;

                    setState(() {
                      _player = updatedPlayer;
                    });

                    widget.onChanged?.call();
                  },
                );
              },
              child: MeditationWidget(
                imagePath: getMeditationImagePath(), // ✅ 只判断性别
                ready: true,
                offset: const AlwaysStoppedAnimation(Offset.zero),
                opacity: const AlwaysStoppedAnimation(1.0),
                createdAt: DateTime.now().subtract(const Duration(hours: 3)),
              ),
            ),
          ],
        ),
        CultivationProgressBar(
          current: widget.display.current,
          max: widget.display.max,
          realm: widget.display.realm,
          rank: widget.display.rank,
          onUpdated: () async {
            final updatedPlayer = await PlayerStorage.getPlayer();
            if (updatedPlayer == null) return;

            setState(() {
              _player = updatedPlayer;
            });
            widget.onChanged?.call();
          },
        ),
      ],
    );
  }
}
