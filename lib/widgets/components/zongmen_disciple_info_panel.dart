import 'package:flutter/material.dart';
import 'package:xiu_to_xiandi_tuixiu/models/disciple.dart';
import '../../services/disciple_storage.dart';
import '../../services/zongmen_disciple_service.dart';
import '../../utils/number_format.dart';
import '../dialogs/aptitude_charm_dialog.dart';
import '../components/favorability_heart.dart';
import '../dialogs/improve_disciple_realm_dialog.dart';

class ZongmenDiscipleInfoPanel extends StatefulWidget {
  final Disciple disciple;

  /// 🌟 新增：回调最新Disciple给父组件
  final ValueChanged<Disciple>? onDiscipleChanged;

  const ZongmenDiscipleInfoPanel({
    super.key,
    required this.disciple,
    this.onDiscipleChanged,
  });

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
    final bool isMaxLevel = d.realmLevel >= ZongmenDiscipleService.maxRealmLevel;
    final realmName = ZongmenDiscipleService.getRealmNameByLevel(d.realmLevel);
    print('d.realmLevel=====${d.realmLevel}');
    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('道号', d.name),
            _buildInfoRow(
              '境界',
              isMaxLevel ? '$realmName（已满级）' : realmName,
              showPlus: !isMaxLevel,
              onPlusTap: isMaxLevel
                  ? null
                  : () {
                showDialog(
                  context: context,
                  builder: (_) => ImproveDiscipleRealmDialog(
                    disciple: d,
                    onRealmUpgraded: () async {
                      final updated = await DiscipleStorage.load(d.id);
                      if (updated != null) {
                        setState(() => d = updated);
                        widget.onDiscipleChanged?.call(updated);
                      }
                    },
                  ),
                );
              },
            ),
            _buildInfoRow('战力', formatAnyNumber(ZongmenDiscipleService.calculatePower(d))),
            _buildStatRow('血量', d.hp, d.extraHp),
            _buildStatRow('攻击', d.atk, d.extraAtk),
            _buildStatRow('防御', d.def, d.extraDef),
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
                      final updated = await DiscipleStorage.load(widget.disciple.id);
                      if (updated != null) {
                        setState(() {
                          d = updated;
                        });
                        widget.onDiscipleChanged?.call(updated);
                      }
                    },
                  ),
                );
              },
            ),
            _buildInfoRow('职位', '${d.role}'),
            _buildInfoRow('资料', d.description),
          ],
        ),
        Positioned(
          top: 0,
          right: 0,
          child: FavorabilityHeart(
            disciple: d,
            onFavorabilityChanged: (updated) {
              setState(() {
                d = updated;
              });
              widget.onDiscipleChanged?.call(updated);
            },
          ),
        ),
      ],
    );
  }

  /// 属性展示：带括号加成（仅血/攻/防用）
  Widget _buildStatRow(String label, int base, double extraPercent) {
    final total = (base * (1 + extraPercent)).floor();
    return _buildInfoRow(
      label,
      '',
      valueWidget: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: formatAnyNumber(total),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontFamily: 'ZcoolCangEr',
              ),
            ),
            if (extraPercent > 0)
              TextSpan(
                text: '（+${(extraPercent * 100).toStringAsFixed(0)}%）',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12, // 小2号
                  fontFamily: 'ZcoolCangEr',
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// 通用信息行（支持右侧加号、支持替代value为Widget）
  Widget _buildInfoRow(
      String label,
      String value, {
        Widget? valueWidget,
        bool showPlus = false,
        VoidCallback? onPlusTap,
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                valueWidget ??
                    Text(
                      value,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontFamily: 'ZcoolCangEr',
                      ),
                    ),
                if (showPlus)
                  GestureDetector(
                    onTap: onPlusTap,
                    child: const Padding(
                      padding: EdgeInsets.only(left: 4),
                      child: Icon(
                        Icons.add_circle_outline,
                        color: Colors.white70,
                        size: 18,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
