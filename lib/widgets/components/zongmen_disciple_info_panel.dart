import 'package:flutter/material.dart';
import 'package:xiu_to_xiandi_tuixiu/models/disciple.dart';

import '../../utils/number_format.dart';

class ZongmenDiscipleInfoPanel extends StatelessWidget {
  final Disciple disciple;

  const ZongmenDiscipleInfoPanel({super.key, required this.disciple});

  @override
  Widget build(BuildContext context) {
    final d = disciple;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoRow('道号', d.name),
        _buildInfoRow('性别', d.gender == 'male' ? '男' : '女'),
        _buildInfoRow('年龄', '${d.age} 岁'),
        _buildInfoRow('境界', d.realm),
        _buildInfoRow('忠诚', '${d.loyalty}%'),
        _buildInfoRow('特长', d.specialty.isNotEmpty ? d.specialty : '暂无'),
        _buildInfoRow('战力', '攻 ${d.atk} / 防 ${d.def} / 血 ${formatAnyNumber(d.hp)}'),
        _buildInfoRow('修为', formatAnyNumber(d.cultivation)),
        _buildInfoRow('资质', '${d.aptitude}'), // ✅ 就这一行，干净利索
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
