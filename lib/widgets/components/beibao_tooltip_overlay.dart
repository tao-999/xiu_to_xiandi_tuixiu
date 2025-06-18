import 'package:flutter/material.dart';
import '../../utils/number_format.dart';
import '../../models/beibao_item_type.dart'; // ✅ 确保你有这个 enum

class BeibaoTooltipOverlay {
  static OverlayEntry show({
    required BuildContext context,
    required Offset position,
    required String name,
    required BeibaoItemType type, // ✅ 新增参数
    dynamic quantity,
    required String description,
    required VoidCallback onDismiss,
  }) {
    final overlay = Overlay.of(context);
    final RenderBox overlayBox = overlay.context.findRenderObject() as RenderBox;
    final Size screenSize = overlayBox.size;

    double left = position.dx + 10;
    double top = position.dy - 40;
    const double tooltipWidth = 200;
    const double tooltipHeight = 80;

    if (left + tooltipWidth > screenSize.width) {
      left = screenSize.width - tooltipWidth - 10;
    }
    if (top + tooltipHeight > screenSize.height) {
      top = screenSize.height - tooltipHeight - 10;
    }
    if (top < 10) {
      top = 10;
    }

    final entry = OverlayEntry(
      builder: (ctx) => GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: onDismiss,
        child: Stack(
          children: [
            Positioned(
              left: left,
              top: top,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white24),
                  ),
                  constraints: const BoxConstraints(maxWidth: 200),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                      if (type != BeibaoItemType.weapon && quantity != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          '数量：${formatAnyNumber(quantity)}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                          ),
                        ),
                      ],
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    overlay.insert(entry);
    return entry;
  }
}
