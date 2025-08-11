// 📂 lib/widgets/dialogs/cultivator_info_card_dialog.dart
import 'package:flutter/material.dart';
import 'package:xiu_to_xiandi_tuixiu/models/character.dart';
import 'package:xiu_to_xiandi_tuixiu/services/player_storage.dart';
import 'package:xiu_to_xiandi_tuixiu/utils/number_format.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/charts/polygon_radar_chart.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/dialogs/aptitude_upgrade_dialog.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/pill_consumer.dart';
import 'package:xiu_to_xiandi_tuixiu/utils/cultivation_level.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/dialogs/player_equip_dialog.dart';
// ❌ 删掉旧的速度面板
// import 'package:xiu_to_xiandi_tuixiu/widgets/components/movement_gongfa_equip_panel.dart';
// ✅ 使用新的“双槽合一”面板（速度+攻击）
import 'package:xiu_to_xiandi_tuixiu/widgets/components/gongfa_dual_equip_panel.dart';

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
              future: PlayerStorage.getPlayer(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data == null) {
                  return const Center(child: CircularProgressIndicator());
                }

                final player = snapshot.data!;
                final power = PlayerStorage.getPower(player);
                final hp = PlayerStorage.getHp(player);
                final atk = PlayerStorage.getAtk(player);
                final def = PlayerStorage.getDef(player);
                final speed = PlayerStorage.getMoveSpeed(player);

                String formatPercent(double value) =>
                    '${(value * 100).toStringAsFixed(2)}%';

                Widget _buildLabeledRow(String label, String value, {String? extra}) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline, // ✅ 改这里
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        SizedBox(
                          width: 60,
                          child: Text(
                            '$label：',
                            style: const TextStyle(color: Colors.black, fontSize: 10, height: 1.3),
                          ),
                        ),
                        Text(
                          value,
                          style: const TextStyle(color: Colors.black, fontSize: 11, height: 1.3),
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
                  width: 500,
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
                            // —— 左卡片 —— //
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
                                        style: const TextStyle(color: Colors.black, fontSize: 11, height: 1.3),
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
                                        width: 60,
                                        child: Text('资质：', style: TextStyle(color: Colors.black, fontSize: 10)),
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
                                  _buildLabeledRow('移动速度', formatAnyNumber(speed), extra: formatPercent(player.moveSpeedBoost)),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            // —— 右侧：装备栏 + 双槽功法面板 —— //
                            SizedBox(
                              width: 220, // 稍微宽一点，两个槽不挤
                              child: Padding(
                                padding: const EdgeInsets.only(top: 16),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Align(
                                      alignment: Alignment.topCenter,
                                      child: PlayerEquipDialog(
                                        onChanged: () {
                                          setState(() {});
                                          onUpdated();
                                        },
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    // ✅ 新的「速度+攻击」双槽合一组件
                                    GongfaDualEquipPanel(
                                      onChanged: () {
                                        setState(() {}); // 刷新显示
                                        onUpdated();
                                      },
                                      size: 40,
                                      spacing: 8,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // —— 雷达图 —— //
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
                              fillColor: const Color.fromARGB(100, 205, 133, 63),
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
