import 'package:flutter/material.dart';
import 'package:xiu_to_xiandi_tuixiu/models/character.dart';
import 'package:xiu_to_xiandi_tuixiu/utils/number_format_util.dart';

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

  Widget _buildAttributeRow(String labelLeft, String labelRight) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(child: _buildStyledText(labelLeft)),
          const SizedBox(width: 16),
          Expanded(child: _buildStyledText(labelRight)),
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
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
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
        // 上层卡片：基础信息
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
              Text('${profile.name} · ${profile.career}',
                  style: const TextStyle(color: Colors.black, fontSize: 16)),
              const SizedBox(height: 4),
              Text('战力：${formatLargeNumber(profile.power)}',
                  style: const TextStyle(color: Colors.black, fontSize: 16)),
              const SizedBox(height: 4),
              Text(
                '五行属性：' +
                    profile.elements.entries
                        .where((e) => e.value > 0)
                        .map((e) => '${elementLabels[e.key] ?? e.key}${e.value}')
                        .join('  '),
                style: const TextStyle(color: Colors.black, fontSize: 16),
              ),
              const SizedBox(height: 4),
              Text(
                '资质：${profile.totalElement}（${_getAptitudeLabel(profile.totalElement)}）',
                style: const TextStyle(color: Colors.black, fontSize: 16),
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
            color: const Color(0xFFE5D7B8),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5D7B8), width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAttributeRow('气血：${formatLargeNumber(profile.hp)}', '攻击：${formatLargeNumber(profile.atk)}'),
              _buildAttributeRow('防御：${formatLargeNumber(profile.def)}', '攻速：${profile.atkSpeed.toStringAsFixed(2)}秒'),
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

  String _getAptitudeLabel(int total) {
    if (total >= 191) return '仙帝之资';
    if (total >= 181) return '太乙仙之资';
    if (total >= 171) return '混元仙之资';
    if (total >= 161) return '圣仙之资';
    if (total >= 151) return '虚仙之资';
    if (total >= 141) return '灵仙之资';
    if (total >= 131) return '玄仙之资';
    if (total >= 121) return '真仙之资';
    if (total >= 111) return '天仙之资';
    if (total >= 101) return '地仙之资';
    if (total >= 91) return '飞升之资';
    if (total >= 81) return '渡劫之资';
    if (total >= 71) return '大乘之资';
    if (total >= 61) return '合体之资';
    if (total >= 51) return '炼虚之资';
    if (total >= 41) return '化神之资';
    if (total >= 31) return '元婴之资';
    if (total >= 21) return '金丹之资';
    if (total >= 11) return '筑基之资';
    return '练气之资';
  }
}
