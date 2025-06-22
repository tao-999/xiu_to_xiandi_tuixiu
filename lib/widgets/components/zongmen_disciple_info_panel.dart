import 'package:flutter/material.dart';
import 'package:xiu_to_xiandi_tuixiu/models/disciple.dart';
import '../../utils/number_format.dart';
import '../dialogs/aptitude_charm_dialog.dart';

class ZongmenDiscipleInfoPanel extends StatefulWidget {
  final Disciple disciple;

  const ZongmenDiscipleInfoPanel({super.key, required this.disciple});

  @override
  State<ZongmenDiscipleInfoPanel> createState() => _ZongmenDiscipleInfoPanelState();
}

class _ZongmenDiscipleInfoPanelState extends State<ZongmenDiscipleInfoPanel> {
  late Disciple d;

  @override
  void initState() {
    super.initState();
    d = widget.disciple;
  }

  @override
  Widget build(BuildContext context) {
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
        _buildInfoRow(
          '资质',
          '${d.aptitude}',
          showPlus: true,
          onPlusTap: () {
            showDialog(
              context: context,
              builder: (_) => AptitudeCharmDialog(
                disciple: d,
                onUpdated: () async {
                  setState(() {}); // ✅ 刷新显示
                },
              ),
            );
          },
        ),
        _buildInfoRow('好感度', '${d.favorability}'),
        _buildInfoRow('职位', '${d.role}'),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, {bool showPlus = false, VoidCallback? onPlusTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text('$label：', style: const TextStyle(color: Colors.white70, fontSize: 14, fontFamily: 'ZcoolCangEr')),
          const SizedBox(width: 6),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value,
                    style: const TextStyle(color: Colors.white, fontSize: 14, fontFamily: 'ZcoolCangEr'),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (showPlus)
                  GestureDetector(
                    onTap: onPlusTap,
                    child: const Icon(Icons.add_circle_outline, color: Colors.white70, size: 18),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
