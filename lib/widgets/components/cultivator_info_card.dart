import 'package:flutter/material.dart';
import 'package:xiu_to_xiandi_tuixiu/models/character.dart';

class CultivatorInfoCard extends StatelessWidget {
  final Character profile;

  const CultivatorInfoCard({super.key, required this.profile});

  String formatPercent(double value) {
    return '${(value * 100).toStringAsFixed(1)}%';
  }

  Widget _buildAttributeRow(String labelLeft, String labelRight) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(child: _buildStyledText(labelLeft)),
          const SizedBox(width: 16), // ✅ 中间加一丢丢间距
          Expanded(child: _buildStyledText(labelRight)),
        ],
      ),
    );
  }

  Widget _buildStyledText(String text) {
    final regex = RegExp(r'^(.+?[:：])\s*(.+)$');
    final match = regex.firstMatch(text);

    if (match == null) {
      return Text(text); // fallback：没匹配上就直接返回普通文本
    }

    final label = match.group(1)!; // e.g. "气血："
    final value = match.group(2)!; // e.g. "300"

    return Row(
      children: [
        Expanded(
          flex: 1,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              label,
              textAlign: TextAlign.left,
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        ),
        Expanded(
          flex: 1,
          child: Align(
            alignment: Alignment.centerRight,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 🔹 上层：基础信息卡
        Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFE5D7B8),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5D7B8), width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${profile.name} · ${profile.career} · 等级 ${profile.level}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black, // ✅ 设置黑色
                ),
              ),
              const SizedBox(height: 4),
              Text('战力：${profile.power}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black, // ✅ 设置黑色
                  )),
              const SizedBox(height: 4),
              Text('五行属性：' +
                  profile.elements.entries
                      .map((e) => '${e.key}${e.value}')
                      .join('  '),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black, // ✅ 设置黑色
                  )),
            ],
          ),
        ),

        // 🔸 下层：属性值卡
        Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFE5D7B8),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5D7B8), width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAttributeRow('气血：${profile.hp}', '攻击：${profile.atk}'),
              _buildAttributeRow('防御：${profile.def}', '攻速：${profile.atkSpeed.toStringAsFixed(2)}秒'),
              _buildAttributeRow('暴击率：${formatPercent(profile.critRate)}', '暴击伤害：${formatPercent(profile.critDamage)}'),
              _buildAttributeRow('闪避率：${formatPercent(profile.dodgeRate)}', '吸血：${formatPercent(profile.lifeSteal)}'),
              _buildAttributeRow('破甲：${formatPercent(profile.breakArmorRate)}', '幸运：${formatPercent(profile.luckRate)}'),
              _buildAttributeRow('连击率：${formatPercent(profile.comboRate)}', '邪气环：${formatPercent(profile.evilAura)}'),
              _buildAttributeRow('虚弱环：${formatPercent(profile.weakAura)}', '腐蚀环：${formatPercent(profile.corrosionAura)}'),
            ],
          ),
        ),
      ],
    );
  }
}
