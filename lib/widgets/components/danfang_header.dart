import 'package:flutter/material.dart';
import 'package:xiu_to_xiandi_tuixiu/services/pill_blueprint_service.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/pillInfo_bubble.dart';
import '../../models/pill_blueprint.dart';
import '../../models/pill_recipe.dart';

class DanfangHeader extends StatelessWidget {
  final int level;

  const DanfangHeader({super.key, required this.level});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text(
          '🔥 炼丹房',
          style: TextStyle(
            fontSize: 20,
            color: Colors.orangeAccent,
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
          onPressed: () => _showDescriptionDialog(context),
        ),
      ],
    );
  }

  void _showDescriptionDialog(BuildContext context) {
    OverlayEntry? tooltipEntry;

    void showTooltip(BuildContext context, PillBlueprint pill, RenderBox renderBox) {
      final overlay = Overlay.of(context);
      final position = renderBox.localToGlobal(Offset.zero);
      final screenSize = MediaQuery.of(context).size;

      const bubbleWidth = 180.0;
      const margin = 8.0;

      final targetRect = Rect.fromLTWH(
        position.dx,
        position.dy,
        renderBox.size.width,
        renderBox.size.height,
      );

      double left = 0;
      double top = 0;

      if (targetRect.right + margin + bubbleWidth <= screenSize.width) {
        left = targetRect.right + margin;
        top = targetRect.top;
      } else if (targetRect.left - margin - bubbleWidth >= 0) {
        left = targetRect.left - bubbleWidth - margin;
        top = targetRect.top;
      } else if (targetRect.top - margin - 60 >= 0) {
        left = targetRect.left;
        top = targetRect.top - 60 - margin;
      } else if (targetRect.bottom + margin + 60 <= screenSize.height) {
        left = targetRect.left;
        top = targetRect.bottom + margin;
      } else {
        left = screenSize.width - bubbleWidth - margin;
        top = screenSize.height - 60 - margin;
      }

      tooltipEntry = OverlayEntry(
        builder: (_) => Positioned(
          left: left,
          top: top,
          child: Material(
            color: Colors.transparent,
            child: PillInfoBubble(pill: pill),
          ),
        ),
      );

      overlay.insert(tooltipEntry!);
    }

    void hideTooltip() {
      tooltipEntry?.remove();
      tooltipEntry = null;
    }

    final allPills = PillBlueprintService.generateAllBlueprints();
    final Map<int, List<PillBlueprint>> grouped = {};
    for (final pill in allPills) {
      grouped.putIfAbsent(pill.level, () => []).add(pill);
    }

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => Dialog(
        backgroundColor: const Color(0xFFFFF7E5),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        insetPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 20),
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
                  final pills = entry.value;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$level阶',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF4E342E),
                            fontFamily: 'ZcoolCangEr',
                          ),
                        ),
                        const SizedBox(height: 8),
                        GridView.count(
                          crossAxisCount: 3,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 1.2,
                          children: pills.map((pill) {
                            final key = GlobalKey();

                            final imagePath = switch (pill.type) {
                              PillBlueprintType.attack => 'assets/images/danyao_gongji.png',
                              PillBlueprintType.defense => 'assets/images/danyao_fangyu.png',
                              PillBlueprintType.health => 'assets/images/danyao_xueliang.png',
                            };

                            return GestureDetector(
                              onTap: () {
                                final box = key.currentContext?.findRenderObject() as RenderBox?;
                                if (box != null) {
                                  if (tooltipEntry != null) {
                                    hideTooltip();
                                  } else {
                                    showTooltip(context, pill, box);
                                  }
                                }
                              },
                              child: Column(
                                key: key,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Image.asset(imagePath, width: 40, height: 40),
                                  const SizedBox(height: 4),
                                  Text(
                                    pill.name,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF4E342E),
                                      fontFamily: 'ZcoolCangEr',
                                    ),
                                  ),
                                ],
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
