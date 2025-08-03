import 'package:flutter/material.dart';
import 'package:xiu_to_xiandi_tuixiu/models/character.dart';
import 'package:xiu_to_xiandi_tuixiu/services/player_storage.dart';
import 'package:xiu_to_xiandi_tuixiu/utils/number_format.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/charts/polygon_radar_chart.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/dialogs/aptitude_upgrade_dialog.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/pill_consumer.dart';
import 'package:xiu_to_xiandi_tuixiu/utils/cultivation_level.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/dialogs/player_equip_dialog.dart';

class CultivatorInfoCardDialog {
  static Future<void> show({
    required BuildContext context,
    required Character player,
    required CultivationLevelDisplay display,
    required VoidCallback onUpdated,
  }) async {

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => Dialog(
        insetPadding: EdgeInsets.zero,
        backgroundColor: Colors.transparent,
        child: StatefulBuilder(
          builder: (context, setState) {
            return FutureBuilder<Character?>(
              future: PlayerStorage.getPlayer(), // 🧠 每次都获取最新 player！
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data == null) {
                  return const Center(child: CircularProgressIndicator());
                }

                final player = snapshot.data!;
                final power = PlayerStorage.getPower(player);
                final hp = PlayerStorage.getHp(player);
                final atk = PlayerStorage.getAtk(player);
                final def = PlayerStorage.getDef(player);

                String formatPercent(double value) => '${(value * 100).toStringAsFixed(2)}%';

                Widget _buildLabeledRow(String label, String value, {String? extra}) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        SizedBox(
                          width: 48,
                          child: Text(
                            '$label：',
                            style: const TextStyle(color: Colors.black, fontSize: 12, height: 1.3),
                          ),
                        ),
                        Text(
                          value,
                          style: const TextStyle(color: Colors.black, fontSize: 12, height: 1.3),
                        ),
                        if (extra != null) ...[
                          const SizedBox(width: 6),
                          Text(
                            '($extra)',
                            style: const TextStyle(color: Colors.black54, fontSize: 10, height: 1.3),
                          ),
                        ],
                      ],
                    ),
                  );
                }

                return Container(
                  width: 350,
                  height: 350,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFF8DC),
                    borderRadius: BorderRadius.zero,
                  ),
                  child: Column(
                    children: [
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 左卡片
                            Container(
                              width: 250,
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '${player.name} · ${player.career}',
                                        style: const TextStyle(color: Colors.black, fontSize: 12, height: 1.3),
                                      ),
                                      PillConsumer(onConsumed: () {
                                        setState(() {});
                                        onUpdated();
                                      }),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const SizedBox(
                                        width: 48,
                                        child: Text('资质：', style: TextStyle(color: Colors.black, fontSize: 12)),
                                      ),
                                      Text('${player.aptitude}', style: const TextStyle(color: Colors.black, fontSize: 12)),
                                      const SizedBox(width: 4),
                                      AptitudeUpgradeDialog.buildButton(
                                        context: context,
                                        player: player,
                                        onUpdated: () {
                                          setState(() {});
                                          onUpdated();
                                        },
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  _buildLabeledRow('战力', formatAnyNumber(power)),
                                  _buildLabeledRow('气血', formatAnyNumber(hp), extra: formatPercent(player.extraHp)),
                                  _buildLabeledRow('攻击', formatAnyNumber(atk), extra: formatPercent(player.extraAtk)),
                                  _buildLabeledRow('防御', formatAnyNumber(def), extra: formatPercent(player.extraDef)),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            SizedBox(
                              width: 60,
                              child: Padding(
                                padding: const EdgeInsets.only(top: 16),
                                child: Align(
                                  alignment: Alignment.topCenter,
                                  child: PlayerEquipDialog(
                                    onChanged: () {
                                      setState(() {}); // ✅ 触发重新加载 player
                                      onUpdated();
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // 雷达图
                      SizedBox(
                        height: 160,
                        child: Center(
                          child: SizedBox(
                            width: 150,
                            height: 150,
                            child: PolygonRadarChart(
                              values: ['gold', 'wood', 'water', 'fire', 'earth']
                                  .map((e) => player.elements[e] ?? 0)
                                  .toList(),
                              labels: const ['金', '木', '水', '火', '土'],
                              max: 14,
                              strokeColor: Colors.brown,
                              fillColor: Color.fromARGB(100, 205, 133, 63),
                              labelStyle: const TextStyle(fontSize: 11, color: Colors.black),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );

  }
}
