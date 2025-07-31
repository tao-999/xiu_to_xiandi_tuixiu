import 'package:flutter/material.dart';
import 'package:xiu_to_xiandi_tuixiu/models/disciple.dart';
import 'package:xiu_to_xiandi_tuixiu/services/disciple_storage.dart';
import 'package:xiu_to_xiandi_tuixiu/services/zongmen_storage.dart';
import 'package:xiu_to_xiandi_tuixiu/utils/aptitude_color_util.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/common/toast_tip.dart';
import '../../services/resources_storage.dart';
import '../../services/zongmen_disciple_service.dart';

class DiscipleListDialog extends StatefulWidget {
  final List<Disciple> disciples;

  const DiscipleListDialog({super.key, required this.disciples});

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

  @override
  void initState() {
    super.initState();
    _loadSortOption();
  }

  Future<void> _loadSortOption() async {
    final saved = await DiscipleStorage.loadSortOption();
    if (mounted) setState(() => _sortOption = saved);
  }

  List<Disciple> get sortedDisciples {
    final list = widget.disciples.where((d) => d.joinedAt == null).toList();

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
    final hasDisintegratable = sortedDisciples.any((d) => d.aptitude <= 30);

    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: Container(
        width: 480,
        height: 620,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 标题及排序
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('📜 已招募修士', style: TextStyle(fontSize: 16)),
                DropdownButton<String>(
                  value: _sortOption,
                  items: const [
                    DropdownMenuItem(value: 'time_desc', child: Text('时间：新 → 旧')),
                    DropdownMenuItem(value: 'time_asc', child: Text('时间：旧 → 新')),
                    DropdownMenuItem(value: 'apt_desc', child: Text('资质：高 → 低')),
                    DropdownMenuItem(value: 'apt_asc', child: Text('资质：低 → 高')),
                  ],
                  onChanged: (v) async {
                    if (v != null) {
                      await DiscipleStorage.saveSortOption(v);
                      setState(() => _sortOption = v);
                    }
                  },
                  style: const TextStyle(fontSize: 14, color: Colors.black),
                  underline: const SizedBox(),
                ),
              ],
            ),
            const Divider(),
            // 列表区域
            SizedBox(
              height: 470,
              child: sortedDisciples.isEmpty
                  ? const Center(child: Text('暂无记录，快去招募吧～'))
                  : ListView.builder(
                itemCount: sortedDisciples.length,
                itemBuilder: (_, index) {
                  final d = sortedDisciples[index];
                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    decoration: AptitudeColorUtil.getBackgroundDecoration(d.aptitude),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListTile(
                          leading: ClipRRect(
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
                          trailing: d.aptitude > 30
                              ? InkWell(
                            onTap: () async {
                              final zongmen = await ZongmenStorage.loadZongmen();
                              if (zongmen == null) {
                                ToastTip.show(context, '你还没有宗门，不能收弟子啊！');
                                return;
                              }

                              final level = zongmen.sectLevel;
                              final max = 5 * (1 << (level - 1));

                              final all = await DiscipleStorage.getAll();
                              final joinedCount = all.where((d) => d.joinedAt != null).length;

                              if (joinedCount >= max) {
                                ToastTip.show(context, '宗门弟子已满，无法再收人！');
                                return;
                              }

                              final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
                              final updated = d.copyWith(joinedAt: now);

                              await DiscipleStorage.save(updated);

                              widget.disciples.removeWhere((e) => e.id == d.id);

                              if (mounted) setState(() {});
                              ToastTip.show(context, '${d.name} 已加入宗门！');
                            },
                            child: const Text(
                              '加入宗门',
                              style: TextStyle(
                                fontSize: 14,
                                fontFamily: 'ZcoolCangEr',
                                color: Colors.blueAccent,
                              ),
                            ),
                          )
                              : InkWell(
                            onTap: () async {
                              final gained = BigInt.from(d.aptitude * 10);
                              await ResourcesStorage.add('spiritStoneLow', gained);
                              await DiscipleStorage.delete(d.id);
                              widget.disciples.removeWhere((e) => e.id == d.id);

                              if (mounted) setState(() {});
                              ToastTip.show(context, '${d.name} 被分解，获得下品灵石 +$gained');
                            },
                            child: const Text(
                              '分解',
                              style: TextStyle(
                                fontSize: 14,
                                fontFamily: 'ZcoolCangEr',
                                color: Colors.redAccent,
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
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (hasDisintegratable)
                  GestureDetector(
                    onTap: () async {
                      final toDisintegrate = sortedDisciples.where((d) => d.aptitude <= 30).toList();

                      if (toDisintegrate.isEmpty) return;

                      // 一次性计算总奖励
                      BigInt totalStones = toDisintegrate.fold(
                        BigInt.zero,
                            (sum, d) => sum + BigInt.from(d.aptitude * 10),
                      );

                      // 一次性加资源
                      await ResourcesStorage.add('spiritStoneLow', totalStones);

                      // 并行删除
                      await Future.wait([
                        for (final d in toDisintegrate) DiscipleStorage.delete(d.id),
                      ]);

                      widget.disciples.removeWhere((d) => d.aptitude <= 30);

                      if (mounted) setState(() {});
                      ToastTip.show(context, '已分解${toDisintegrate.length}名弟子，获得下品灵石 +$totalStones');
                    },
                    child: const Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Text(
                        '一键分解',
                        style: TextStyle(
                          fontSize: 14,
                          fontFamily: 'ZcoolCangEr',
                          color: Colors.redAccent,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
