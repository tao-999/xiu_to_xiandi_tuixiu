import 'package:flutter/material.dart';
import 'package:xiu_to_xiandi_tuixiu/models/character.dart';
import 'package:xiu_to_xiandi_tuixiu/services/player_storage.dart';

import '../../utils/number_format.dart';
import '../constants/aptitude_table.dart';

class CultivatorInfoCard extends StatelessWidget {
  final Character profile;

  const CultivatorInfoCard({super.key, required this.profile});

  String formatPercent(double value) {
    return '${(value * 100).toStringAsFixed(1)}%';
  }

  static const Map<String, String> elementLabels = {
    'gold': '金', 'wood': '木', 'water': '水', 'fire': '火', 'earth': '土',
    'jin': '金', 'mu': '木', 'shui': '水', 'huo': '火', 'tu': '土',
    '金': '金', '木': '木', '水': '水', '火': '火', '土': '土',
  };

  Widget _buildAttributeRow(String fullText) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: _buildStyledText(fullText),
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
          width: 48, // ✅ 控制 label 宽度（你可以调）
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(width: 4), // ✅ label 和 value 之间留一点间距
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 11,
            ),
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
    final totalElement = PlayerStorage.calculateTotalElement(profile.elements);
    final power = PlayerStorage.getPower(profile);

    // ✅ 拆分属性
    final baseHp = PlayerStorage.getBaseHp(profile);
    final extraHp = PlayerStorage.getExtraHp(profile);
    final pillBonusHp = PlayerStorage.getPillHp(profile);
    final baseAtk = PlayerStorage.getBaseAtk(profile);
    final extraAtk = PlayerStorage.getExtraAtk(profile);
    final pillBonusAtk= PlayerStorage.getPillAtk(profile);
    final baseDef = PlayerStorage.getBaseDef(profile);
    final extraDef = PlayerStorage.getExtraDef(profile);
    final pillBonusDef = PlayerStorage.getPillDef(profile);

    debugPrint('📊 角色属性计算：');
    debugPrint('▶️ 气血：base=$baseHp, extra=$extraHp, pill=$pillBonusHp');
    debugPrint('▶️ 攻击：base=$baseAtk, extra=$extraAtk, pill=$pillBonusAtk');
    debugPrint('▶️ 防御：base=$baseDef, extra=$extraDef, pill=$pillBonusDef');

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
                '战力：${formatAnyNumber(power)}',
                style: const TextStyle(color: Colors.black, fontSize: 12),
              ),
              const SizedBox(height: 4),
              Text(
                '五行属性：' +
                    profile.elements.entries
                        .where((e) => e.value > 0)
                        .map((e) => '${elementLabels[e.key] ?? e.key}${e.value}')
                        .join('  '),
                style: const TextStyle(color: Colors.black, fontSize: 12),
              ),
              const SizedBox(height: 4),
              Text(
                '资质：$totalElement（${_getAptitudeLabel(totalElement)}）',
                style: const TextStyle(color: Colors.black, fontSize: 12),
              ),
            ],
          ),
        ),

        // 下层卡片：属性值
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
              _buildAttributeRow('气血：${formatAnyNumber(baseHp)}（+${formatAnyNumber(extraHp + pillBonusHp)}）'),
              _buildAttributeRow('攻击：${formatAnyNumber(baseAtk)}（+${formatAnyNumber(extraAtk + pillBonusAtk)}）'),
              _buildAttributeRow('防御：${formatAnyNumber(baseDef)}（+${formatAnyNumber(extraDef + pillBonusDef)}）'),
            ],
          ),
        ),
      ],
    );
  }

  String _getAptitudeLabel(int total) {
    final gate = aptitudeTable
        .lastWhere((g) => total >= g.minAptitude, orElse: () => aptitudeTable.first);
    final name = gate.realmName;

    return '$name之资';
  }
}
