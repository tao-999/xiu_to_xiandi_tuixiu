import 'package:flutter/material.dart';
import 'package:xiu_to_xiandi_tuixiu/models/disciple.dart';
import 'package:xiu_to_xiandi_tuixiu/utils/format_large_number.dart';

class ZongmenDiscipleInfoPanel extends StatelessWidget {
  final Disciple disciple;

  const ZongmenDiscipleInfoPanel({super.key, required this.disciple});

  @override
  Widget build(BuildContext context) {
    final d = disciple;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoRow('性别', d.gender == 'male' ? '男' : '女'),
        _buildInfoRow('年龄', '${d.age} 岁'),
        _buildInfoRow('境界', d.realm),
        _buildInfoRow('寿元', '${d.lifespan} 岁'),
        _buildInfoRow('忠诚', '${d.loyalty}%'),
        _buildInfoRow('特长', d.specialty.isNotEmpty ? d.specialty : '暂无'),
        _buildInfoRow('战力', '攻 ${d.atk} / 防 ${d.def} / 血 ${formatLargeNumber(d.hp)}'),
        _buildInfoRow('修为', formatLargeNumber(d.cultivation)),
        _buildInfoRow('突破几率', '${d.breakthroughChance}%'),
        _buildInfoRow('疲劳值', '${d.fatigue}'),
        _buildInfoRow('任务状态', d.isOnMission ? '执行中' : '待命'),
        const SizedBox(height: 16),
        const Text('技能', style: TextStyle(color: Colors.white, fontSize: 16, fontFamily: 'ZcoolCangEr')),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: d.skills.isEmpty
              ? [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text('暂无技能', style: TextStyle(color: Colors.white70)),
            )
          ]
              : d.skills.map((s) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.blueGrey.withOpacity(0.5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(s, style: const TextStyle(color: Colors.white)),
            );
          }).toList(),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text('$label：', style: const TextStyle(color: Colors.white70, fontSize: 14, fontFamily: 'ZcoolCangEr')),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 14, fontFamily: 'ZcoolCangEr'),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
