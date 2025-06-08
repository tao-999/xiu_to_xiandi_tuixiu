import 'package:flutter/material.dart';
import 'package:xiu_to_xiandi_tuixiu/models/disciple.dart';
import 'package:xiu_to_xiandi_tuixiu/utils/aptitude_color_util.dart';
import 'package:xiu_to_xiandi_tuixiu/utils/format_large_number.dart';

class DiscipleDetailPage extends StatelessWidget {
  final Disciple disciple;

  const DiscipleDetailPage({super.key, required this.disciple});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1D1A17),
      body: SafeArea(
        child: Column(
          children: [
            // 顶部头像
            Container(
              width: double.infinity,
              height: 260,
              decoration: BoxDecoration(
                image: disciple.imagePath.isNotEmpty
                    ? DecorationImage(
                  image: AssetImage(disciple.imagePath),
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                )
                    : null,
                color: Colors.black26,
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: 16,
                    left: 16,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  Positioned(
                    bottom: 16,
                    left: 16,
                    child: Text(
                      disciple.name,
                      style: const TextStyle(
                        fontSize: 24,
                        color: Colors.white,
                        fontFamily: 'ZcoolCangEr',
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AptitudeColorUtil.getBackgroundColor(disciple.aptitude).withOpacity(0.8),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        '资质：${disciple.aptitude}',
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 14,
                          fontFamily: 'ZcoolCangEr',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 信息区域
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildInfoRow('性别', disciple.gender == 'male' ? '男' : '女'),
                  _buildInfoRow('年龄', '${disciple.age} 岁'),
                  _buildInfoRow('境界', disciple.realm),
                  _buildInfoRow('寿元', '${disciple.lifespan} 岁'),
                  _buildInfoRow('忠诚', '${disciple.loyalty}%'),
                  _buildInfoRow('特长', disciple.specialty.isNotEmpty ? disciple.specialty : '暂无'),
                  _buildInfoRow('战力', '攻 ${disciple.atk} / 防 ${disciple.def} / 血 ${formatLargeNumber(disciple.hp)}'),
                  _buildInfoRow('修为', '${formatLargeNumber(disciple.cultivation)}'),
                  _buildInfoRow('突破几率', '${disciple.breakthroughChance}%'),
                  _buildInfoRow('疲劳值', '${disciple.fatigue}'),
                  _buildInfoRow('任务状态', disciple.isOnMission ? '执行中' : '待命'),

                  const SizedBox(height: 12),
                  const Text('技能', style: TextStyle(color: Colors.white, fontSize: 16, fontFamily: 'ZcoolCangEr')),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: disciple.skills.isEmpty
                        ? [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Text('暂无技能', style: TextStyle(color: Colors.white70)),
                      ),
                    ]
                        : disciple.skills.map((skill) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.blueGrey.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(skill, style: const TextStyle(color: Colors.white)),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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
