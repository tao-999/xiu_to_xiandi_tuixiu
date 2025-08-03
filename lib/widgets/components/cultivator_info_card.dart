import 'package:flutter/material.dart';
import 'package:xiu_to_xiandi_tuixiu/models/character.dart';
import 'package:xiu_to_xiandi_tuixiu/services/player_storage.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/pill_consumer.dart';

import '../../utils/number_format.dart';
import '../charts/polygon_radar_chart.dart';
import '../dialogs/aptitude_upgrade_dialog.dart';

class CultivatorInfoCard extends StatelessWidget {
  final Character profile;

  const CultivatorInfoCard({super.key, required this.profile});

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

  @override
  Widget build(BuildContext context) {
    final power = PlayerStorage.getPower(profile);
    final hp = PlayerStorage.getHp(profile);
    final atk = PlayerStorage.getAtk(profile);
    final def = PlayerStorage.getDef(profile);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE5D7B8).withOpacity(0.6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min, // ✅ 不要撑满整行
            children: [
              Text(
                '${profile.name} · ${profile.career}',
                style: const TextStyle(color: Colors.black, fontSize: 12, height: 1.3),
              ),
              PillConsumer(
                onConsumed: () {
                  // 可选：刷新逻辑
                },
              ),
            ],
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center, // ✅ 改成 center！
              children: [
                const SizedBox(
                  width: 48,
                  child: Text(
                    '资质：',
                    style: TextStyle(color: Colors.black, fontSize: 12, height: 1.3),
                  ),
                ),
                Text(
                  '${profile.aptitude}',
                  style: const TextStyle(color: Colors.black, fontSize: 12, height: 1.3),
                ),
                const SizedBox(width: 4),
                AptitudeUpgradeDialog.buildButton(
                  context: context,
                  player: profile,
                  onUpdated: () {
                    // 可选刷新
                  },
                )
              ],
            ),
          ),
          const SizedBox(height: 4),
          _buildLabeledRow('战力', formatAnyNumber(power)),
          _buildLabeledRow('气血', formatAnyNumber(hp), extra: formatPercent(profile.extraHp)),
          _buildLabeledRow('攻击', formatAnyNumber(atk), extra: formatPercent(profile.extraAtk)),
          _buildLabeledRow('防御', formatAnyNumber(def), extra: formatPercent(profile.extraDef)),
          Center(
            child: SizedBox(
              width: 150,
              height: 150,
              child: PolygonRadarChart(
                values: ['gold', 'wood', 'water', 'fire', 'earth']
                    .map((e) => profile.elements[e] ?? 0)
                    .toList(),
                labels: ['金', '木', '水', '火', '土'],
                max: 14,
                strokeColor: Colors.brown,
                fillColor: const Color.fromARGB(100, 205, 133, 63),
                labelStyle: const TextStyle(fontSize: 11, color: Colors.black),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
