import 'package:flutter/material.dart';
import 'package:xiu_to_xiandi_tuixiu/models/disciple.dart';
import 'package:xiu_to_xiandi_tuixiu/services/disciple_storage.dart';
import 'package:xiu_to_xiandi_tuixiu/services/zongmen_storage.dart';
import 'package:xiu_to_xiandi_tuixiu/utils/aptitude_color_util.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/common/toast_tip.dart';

class DiscipleListDialog extends StatefulWidget {
  final List<Disciple> disciples;

  const DiscipleListDialog({super.key, required this.disciples});

  /// ✅ 封装好的弟子列表按钮（点了会自动拉取数据 + 弹窗）
  static Widget showButton(BuildContext context) {
    return Positioned(
      right: 20,
      bottom: 30,
      child: GestureDetector(
        onTap: () async {
          final all = await DiscipleStorage.getAll();
          if (!context.mounted) return;
          showDialog(
            context: context,
            builder: (_) => DiscipleListDialog(disciples: all),
          );
        },
        child: const Text(
          '弟子列表',
          style: TextStyle(
            color: Colors.amber,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            fontFamily: 'ZcoolCangEr',
            shadows: [
              Shadow(color: Colors.black87, offset: Offset(0.5, 0.5), blurRadius: 2),
            ],
          ),
        ),
      ),
    );
  }

  @override
  State<DiscipleListDialog> createState() => _DiscipleListDialogState();
}

class _DiscipleListDialogState extends State<DiscipleListDialog> {
  String _sortOption = 'time_desc';

  List<Disciple> get sortedDisciples {
    final list = [...widget.disciples];
    switch (_sortOption) {
      case 'time_asc':
        return list;
      case 'time_desc':
        return list.reversed.toList();
      case 'apt_desc':
        list.sort((a, b) => b.aptitude.compareTo(a.aptitude));
        return list;
      case 'apt_asc':
        list.sort((a, b) => a.aptitude.compareTo(b.aptitude));
        return list;
      default:
        return list;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: double.maxFinite,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 📋 标题 + 筛选
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '📜 已招募修士',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                DropdownButton<String>(
                  value: _sortOption,
                  items: const [
                    DropdownMenuItem(value: 'time_desc', child: Text('时间：新 → 旧')),
                    DropdownMenuItem(value: 'time_asc', child: Text('时间：旧 → 新')),
                    DropdownMenuItem(value: 'apt_desc', child: Text('资质：高 → 低')),
                    DropdownMenuItem(value: 'apt_asc', child: Text('资质：低 → 高')),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => _sortOption = value);
                  },
                  style: const TextStyle(fontSize: 14, color: Colors.black),
                  underline: const SizedBox(),
                ),
              ],
            ),
            const Divider(),

            // 📄 弟子列表
            SizedBox(
              height: 400,
              child: sortedDisciples.isEmpty
                  ? const Center(child: Text('暂无记录，快去招募吧～'))
                  : ListView.builder(
                itemCount: sortedDisciples.length,
                itemBuilder: (_, index) {
                  final d = sortedDisciples[index];
                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: AptitudeColorUtil.getBackgroundColor(d.aptitude),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: d.imagePath.isNotEmpty
                                ? Image.asset(
                              d.imagePath,
                              width: 48,
                              height: 64,
                              fit: BoxFit.cover,
                              alignment: Alignment.topCenter,
                            )
                                : Container(
                              width: 48,
                              height: 64,
                              color: Colors.grey.shade200,
                              alignment: Alignment.center,
                              child: const Icon(Icons.person, size: 20, color: Colors.grey),
                            ),
                          ),
                          title: Row(
                            children: [
                              Text(d.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                              const SizedBox(width: 6),
                              Text(d.gender == 'female' ? '♀️' : '♂️', style: const TextStyle(fontSize: 14)),
                            ],
                          ),
                          subtitle: Text('资质: ${d.aptitude}｜年龄: ${d.age}'),
                          trailing: InkWell(
                            onTap: () async {
                              final zongmen = await ZongmenStorage.loadZongmen();

                              if (zongmen == null) {
                                ToastTip.show(context, '你还没有宗门，不能收弟子啊！');
                                return;
                              }

                              final current = zongmen.disciples.length;
                              final max = 5 * (1 << (zongmen.level - 1));

                              if (current >= max) {
                                ToastTip.show(context, '宗门弟子已满，无法再收人！');
                                return;
                              }

                              final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
                              final updated = d.copyWith(joinedAt: now);

                              await ZongmenStorage.addDisciple(updated);
                              await DiscipleStorage.removeById(d.id);

                              setState(() {
                                widget.disciples.remove(d);
                              });

                              ToastTip.show(context, '${d.name} 已加入宗门！');
                            },
                            child: const Text(
                              '加入宗门',
                              style: TextStyle(
                                fontSize: 14,
                                fontFamily: 'ZcoolCangEr',
                                color: Colors.blueAccent,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
