import 'package:flutter/material.dart';
import 'package:xiu_to_xiandi_tuixiu/models/disciple.dart';
import '../../services/disciple_storage.dart';
import '../../services/zongmen_disciple_service.dart';
import '../../utils/number_format.dart';
import '../dialogs/aptitude_charm_dialog.dart';
import '../components/favorability_heart.dart';

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
    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('道号', d.name),
            _buildInfoRow('性别', d.gender == 'male' ? '男' : '女'),
            _buildInfoRow('年龄', '${d.age} 岁'),
            _buildInfoRow('境界', d.realm),
            _buildInfoRow('忠诚', '${d.loyalty}%'),
            _buildInfoRow('特长', d.specialty.isNotEmpty ? d.specialty : '暂无'),
            _buildPowerRow(),
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
                      // 重新从Hive加载最新数据
                      final updated = await DiscipleStorage.load(widget.disciple.id);
                      if (updated != null) {
                        setState(() {
                          d = updated;
                        });
                      }
                    },
                  ),
                );
              },
            ),
            _buildInfoRow('职位', '${d.role}'),
          ],
        ),
        Positioned(
          top: 0,
          right: 0,
          child: FavorabilityHeart(favorability: d.favorability),
        ),
      ],
    );
  }

  Widget _buildInfoRow(
      String label,
      String value, {
        bool showPlus = false,
        VoidCallback? onPlusTap,
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(
            '$label：',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontFamily: 'ZcoolCangEr',
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontFamily: 'ZcoolCangEr',
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (showPlus)
                  GestureDetector(
                    onTap: onPlusTap,
                    child: const Icon(
                      Icons.add_circle_outline,
                      color: Colors.white70,
                      size: 18,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPowerRow() {
    final power = ZongmenDiscipleService.calculatePower(d);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                '战力：',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontFamily: 'ZcoolCangEr',
                ),
              ),
              const SizedBox(width: 6),
              Text(
                formatAnyNumber(power),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontFamily: 'ZcoolCangEr',
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Text(
                '属性：',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontFamily: 'ZcoolCangEr',
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '攻 ${formatAnyNumber(d.atk)} / 防 ${formatAnyNumber(d.def)} / 血 ${formatAnyNumber(d.hp)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontFamily: 'ZcoolCangEr',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
