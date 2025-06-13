import 'package:flutter/material.dart';
import 'package:xiu_to_xiandi_tuixiu/models/refine_blueprint.dart';
import 'package:xiu_to_xiandi_tuixiu/services/refine_blueprint_service.dart';

class LianqiHeader extends StatelessWidget {
  final int level;

  const LianqiHeader({super.key, required this.level});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text(
          '⚒️ 炼器房',
          style: TextStyle(
            fontSize: 20,
            color: Colors.deepOrangeAccent,
            fontFamily: 'ZcoolCangEr',
          ),
        ),
        const SizedBox(width: 12),
        Text(
          '$level 级',
          style: const TextStyle(
            fontSize: 16,
            color: Colors.white,
            fontFamily: 'ZcoolCangEr',
          ),
        ),
        const Spacer(),
        IconButton(
          icon: const Icon(Icons.info_outline, color: Colors.white70),
          onPressed: () => _showBlueprintDialog(context),
        ),
      ],
    );
  }

  void _showBlueprintDialog(BuildContext context) {
    final List<RefineBlueprint> all = RefineBlueprintService.generateAllBlueprints();
    final Map<int, List<RefineBlueprint>> grouped = {};

    for (final bp in all) {
      grouped.putIfAbsent(bp.level, () => []).add(bp);
    }

    OverlayEntry? tooltipEntry;

    void hideTooltip() {
      tooltipEntry?.remove();
      tooltipEntry = null;
    }

    void showTooltip(BuildContext context, RefineBlueprint blueprint, RenderBox renderBox) {
      final overlay = Overlay.of(context);
      final position = renderBox.localToGlobal(Offset.zero);
      final screenSize = MediaQuery.of(context).size;

      const width = 180.0;
      const height = 120.0;
      const margin = 8.0;

      final rect = Rect.fromLTWH(
        position.dx,
        position.dy,
        renderBox.size.width,
        renderBox.size.height,
      );

      double left = 0;
      double top = 0;

      if (rect.right + width + margin <= screenSize.width) {
        left = rect.right + margin;
        top = rect.top;
      } else if (rect.left - width - margin >= 0) {
        left = rect.left - width - margin;
        top = rect.top;
      } else if (rect.top - height - margin >= 0) {
        left = rect.left;
        top = rect.top - height - margin;
      } else if (rect.bottom + height + margin <= screenSize.height) {
        left = rect.left;
        top = rect.bottom + margin;
      } else {
        left = margin;
        top = margin;
      }

      // 正确展示真实增幅
      final effectShort = switch (blueprint.type) {
        BlueprintType.weapon => '攻击 +${blueprint.attackBoost}%',
        BlueprintType.armor => '防御 +${blueprint.defenseBoost}%',
        BlueprintType.accessory => '血量 +${blueprint.healthBoost}%',
      };

      tooltipEntry = OverlayEntry(
        builder: (_) => Positioned(
          left: left,
          top: top,
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: width,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF2E1C0C),
                border: Border.all(color: Colors.brown),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    blueprint.name,
                    style: const TextStyle(
                      fontSize: 13,
                      fontFamily: 'ZcoolCangEr',
                      color: Colors.orangeAccent,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '效果：$effectShort',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.orange,
                      fontFamily: 'ZcoolCangEr',
                    ),
                  ),
                  const SizedBox(height: 6),
                  ...blueprint.materials.map((m) => Text(
                    '• $m',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                      fontFamily: 'ZcoolCangEr',
                    ),
                  )),
                ],
              ),
            ),
          ),
        ),
      );

      overlay.insert(tooltipEntry!);
    }

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => Dialog(
        backgroundColor: const Color(0xFFFFF7E5),
        insetPadding: const EdgeInsets.all(16),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: hideTooltip,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: SizedBox(
              width: double.infinity,
              height: 500,
              child: ListView(
                children: grouped.entries.map((entry) {
                  final level = entry.key;
                  final blueprints = entry.value;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$level 阶图纸',
                          style: const TextStyle(
                            fontSize: 14,
                            fontFamily: 'ZcoolCangEr',
                            color: Color(0xFF4E342E),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: blueprints.map((b) {
                            final key = GlobalKey();
                            final iconName = switch (b.type) {
                              BlueprintType.weapon => 'wuqi_gongji.png',
                              BlueprintType.armor => 'wuqi_fangyu.png',
                              BlueprintType.accessory => 'wuqi_xueliang.png',
                            };

                            return Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  final box = key.currentContext?.findRenderObject() as RenderBox?;
                                  if (box != null) {
                                    if (tooltipEntry != null) {
                                      hideTooltip();
                                    } else {
                                      showTooltip(context, b, box);
                                    }
                                  }
                                },
                                child: Column(
                                  key: key,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Image.asset(
                                      'assets/images/$iconName',
                                      width: 48,
                                      height: 48,
                                      fit: BoxFit.contain,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      b.name.replaceAll(' · ${b.level}阶', ''),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontFamily: 'ZcoolCangEr',
                                        color: Color(0xFF2E1C0C),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        )
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ),
    ).then((_) => hideTooltip());
  }
}
