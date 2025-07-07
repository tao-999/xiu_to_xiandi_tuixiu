import 'package:flutter/material.dart';
import 'package:xiu_to_xiandi_tuixiu/services/zongmen_disciple_service.dart';

import '../../data/favorability_data.dart';
import '../../models/disciple.dart';
import '../../models/favorability_item.dart';
import '../../services/favorability_material_service.dart';
import '../charts/heart_painter.dart';
import '../common/toast_tip.dart';

class FavorabilityHeart extends StatefulWidget {
  final Disciple disciple;

  /// 🌟 回调
  final ValueChanged<Disciple>? onFavorabilityChanged;

  const FavorabilityHeart({
    Key? key,
    required this.disciple,
    this.onFavorabilityChanged,
  }) : super(key: key);

  @override
  State<FavorabilityHeart> createState() => _FavorabilityHeartState();
}

class _FavorabilityHeartState extends State<FavorabilityHeart> {
  late int _favorability;

  @override
  void initState() {
    super.initState();
    _favorability = widget.disciple.favorability;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        // 弹框前先加载材料库存
        final favorInventory = await FavorabilityMaterialService.getAllMaterials();
        final usableMaterials = favorInventory.entries
            .where((e) => e.value > 0)
            .map((e) {
          final item = FavorabilityData.getByIndex(e.key);
          return {
            'index': e.key,
            'item': item,
            'quantity': e.value,
          };
        }).toList();

        int totalSelectedFavor = 0;
        final Map<int, int> selectedCounts = {};

        // ignore: use_build_context_synchronously
        await showDialog(
          context: context,
          builder: (_) {
            return StatefulBuilder(
              builder: (context, setState) {
                return Dialog(
                  backgroundColor: const Color(0xFFFFF8DC),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                  child: Container(
                    width: 300,
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: usableMaterials.map((mat) {
                            final idx = mat['index'] as int;
                            final FavorabilityItem item = mat['item'] as FavorabilityItem;
                            final int stock = mat['quantity'] as int;
                            final selected = selectedCounts[idx] ?? 0;

                            return GestureDetector(
                              onTap: () {
                                if (selected < stock) {
                                  selectedCounts[idx] = selected + 1;
                                  setState(() {
                                    totalSelectedFavor += item.favorValue;
                                  });
                                }
                              },
                              onLongPress: () {
                                if (selected > 0) {
                                  selectedCounts[idx] = selected - 1;
                                  setState(() {
                                    totalSelectedFavor -= item.favorValue;
                                  });
                                }
                              },
                              child: Container(
                                width: 48,
                                padding: const EdgeInsets.all(2),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(
                                      height: 32,
                                      child: Image.asset(
                                        item.assetPath,
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '$selected/$stock',
                                      style: const TextStyle(fontSize: 8),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '预估提升好感度：$totalSelectedFavor',
                          style: const TextStyle(
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        GestureDetector(
                          onTap: () async {
                            if (totalSelectedFavor == 0) {
                              ToastTip.show(context, '空手套白狼？不行哦~');
                              return;
                            }

                            Navigator.pop(context);

                            int total = 0;
                            for (final e in selectedCounts.entries) {
                              final item = FavorabilityData.getByIndex(e.key);
                              await FavorabilityMaterialService.consumeMaterial(e.key, e.value);
                              total += item.favorValue * e.value;
                            }

                            if (total > 0) {
                              final updated = await ZongmenDiscipleService.increaseFavorability(
                                widget.disciple.id,
                                delta: total,
                              );
                              if (updated != null) {
                                setState(() {
                                  _favorability = updated.favorability;
                                });
                                widget.onFavorabilityChanged?.call(updated);
                              }
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.favorite, color: Colors.black, size: 14),
                                SizedBox(width: 4),
                                Text(
                                  '提升好感度',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
      child: SizedBox(
        width: 36,
        height: 36,
        child: CustomPaint(
          painter: HeartPainter(),
          child: Center(
            child: Text(
              '$_favorability',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
