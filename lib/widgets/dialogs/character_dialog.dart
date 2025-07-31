import 'package:flutter/material.dart';
import 'package:xiu_to_xiandi_tuixiu/models/character.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/cultivator_info_card.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/cultivation_status_panel.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/dialogs/cultivation_boost_dialog.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/dialogs/aptitude_upgrade_dialog.dart';
import 'package:xiu_to_xiandi_tuixiu/utils/cultivation_level.dart';
import 'package:xiu_to_xiandi_tuixiu/services/player_storage.dart';
import '../components/pill_consumer.dart';

class CharacterDialog extends StatefulWidget {
  final VoidCallback? onChanged; // 通用回调

  const CharacterDialog({super.key, this.onChanged});

  @override
  State<CharacterDialog> createState() => _CharacterDialogState();
}

class _CharacterDialogState extends State<CharacterDialog> {
  Future<void> _reloadData() async {
    setState(() {});
    widget.onChanged?.call(); // 每次刷新都同步父组件
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(40),
      child: Container(
        width: 720,
        height: 800,
        decoration: BoxDecoration(
          color: const Color(0xFFFFF8DC), // 米黄色
          borderRadius: BorderRadius.zero,
        ),
        child: FutureBuilder<List<dynamic>>(
          future: Future.wait([
            PlayerStorage.getPlayer(),
            getDisplayLevelFromPrefs(),
          ]),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.amber),
              );
            }

            final player = snapshot.data![0] as Character;
            final display = snapshot.data![1] as CultivationLevelDisplay;

            return Stack(
              children: [
                /// 背景图
                Positioned.fill(
                  child: Image.asset(
                    'assets/images/bg_xiuxian_mountain.webp',
                    fit: BoxFit.cover,
                  ),
                ),

                /// 主体内容
                Align(
                  alignment: const Alignment(0, 0.4),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CultivationStatusPanel(
                        player: player,
                        display: display,
                        showAura: false,
                        onAuraComplete: () {},
                        onChanged: _reloadData, // 刷新并通知
                      ),
                      CultivatorInfoCard(profile: player),
                    ],
                  ),
                ),

                /// 右上角：升修为、升资质
                Positioned(
                  top: 40,
                  right: 30,
                  child: Column(
                    children: [
                      if (display.max != BigInt.zero)
                        CultivationBoostDialog.buildButton(
                          context: context,
                          onUpdated: _reloadData, // 升级后同步回调
                        ),
                      if (display.max != BigInt.zero)
                        const SizedBox(height: 12),
                      AptitudeUpgradeDialog.buildButton(
                        context: context,
                        player: player,
                        onUpdated: _reloadData, // 升级后同步回调
                      ),
                    ],
                  ),
                ),

                /// 左上角：吞丹
                Positioned(
                  top: 40,
                  left: 30,
                  child: PillConsumer(
                    onConsumed: _reloadData, // 吞丹后同步回调
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
