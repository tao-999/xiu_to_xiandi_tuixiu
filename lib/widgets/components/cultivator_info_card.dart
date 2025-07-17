import 'package:flutter/material.dart';
import 'package:xiu_to_xiandi_tuixiu/models/character.dart';
import 'package:xiu_to_xiandi_tuixiu/services/player_storage.dart';

import '../../utils/number_format.dart';
import '../charts/polygon_radar_chart.dart';
import '../constants/aptitude_table.dart';

class CultivatorInfoCard extends StatelessWidget {
  final Character profile;

  const CultivatorInfoCard({super.key, required this.profile});

  String formatPercent(double value) => '${(value * 100).toStringAsFixed(2)}%';

  Widget _buildAttributeRow(String label, num value, double extra) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 48,
            child: Text(
              '$label：',
              style: const TextStyle(color: Colors.black, fontSize: 12),
            ),
          ),
          const SizedBox(width: 4),
          Flexible(
            child: RichText(
              textAlign: TextAlign.right,
              text: TextSpan(
                children: [
                  TextSpan(
                    text: formatAnyNumber(value),
                    style: const TextStyle(color: Colors.black, fontSize: 12),
                  ),
                  TextSpan(
                    text: ' (${formatPercent(extra)})',
                    style: const TextStyle(color: Colors.black, fontSize: 10),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStyledText(String text) {
    final regex = RegExp(r'^(.+?[:：])\s*(.+)$');
    final match = regex.firstMatch(text);
    if (match == null) return Text(text);

    final label = match.group(1)!;
    final value = match.group(2)!;

    return Row(
      children: [
        SizedBox(
          width: 48,
          child: Text(label, style: const TextStyle(color: Colors.black, fontSize: 12)),
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(color: Colors.black, fontSize: 11),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            softWrap: false,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final power = PlayerStorage.getPower(profile);
    final hp = PlayerStorage.getHp(profile);
    final atk = PlayerStorage.getAtk(profile);
    final def = PlayerStorage.getDef(profile);

    return Column(
      children: [
        // 上层卡片：基础信息
        Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFE5D7B8).withOpacity(0.6),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${profile.name} · ${profile.career}',
                  style: const TextStyle(color: Colors.black, fontSize: 12)),
              const SizedBox(height: 4),
              Text(
                '资质：${profile.aptitude}（${_getAptitudeLabel(profile.aptitude)}）',
                style: const TextStyle(color: Colors.black, fontSize: 12),
              ),
              const SizedBox(height: 6),
              Text('战力：${formatAnyNumber(power)}',
                  style: const TextStyle(color: Colors.black, fontSize: 12)),
              const SizedBox(height: 4),
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
        ),

        Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFE5D7B8).withOpacity(0.6),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAttributeRow('气血', hp, profile.extraHp),
              _buildAttributeRow('攻击', atk, profile.extraAtk),
              _buildAttributeRow('防御', def, profile.extraDef),
            ],
          ),
        ),
      ],
    );
  }

  String _getAptitudeLabel(int total) {
    final gate = aptitudeTable.lastWhere((g) => total >= g.minAptitude,
        orElse: () => aptitudeTable.first);
    return '${gate.realmName}之资';
  }
}
