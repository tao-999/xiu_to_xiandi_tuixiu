import 'package:flutter/material.dart';
import '../../utils/number_format.dart';
import '../../models/beibao_item_type.dart';

class BeibaoTooltipOverlay {
  static OverlayEntry show({
    required BuildContext context,
    required Offset position,
    required String name,
    required BeibaoItemType type,
    dynamic quantity,
    required String description,
    required VoidCallback onDismiss,
    VoidCallback? onDiscard,
  }) {
    final overlay = Overlay.of(context);
    final RenderBox overlayBox = overlay.context.findRenderObject() as RenderBox;
    final Size screenSize = overlayBox.size;

    double left = position.dx + 10;
    double top = position.dy - 40;
    const double tooltipWidth = 200;
    const double tooltipHeight = 100;

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
                  child: Stack(
                    children: [
                      // 内容部分
                      Padding(
                        padding: const EdgeInsets.only(right: 28), // 给右上角留位置
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
                      // 右上角丢弃按钮
                      if (onDiscard != null)
                        Positioned(
                          top: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: () async {
                              onDismiss();
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (_) {
                                  return Dialog(
                                    backgroundColor: const Color(0xFFFFF8DC),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.zero,
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            '真的要将「$name」丢弃吗？',
                                            style: const TextStyle(
                                              color: Colors.black,
                                              fontSize: 14,
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          GestureDetector(
                                            onTap: () => Navigator.of(context).pop(true),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: const [
                                                Icon(Icons.delete, color: Colors.redAccent, size: 18),
                                                SizedBox(width: 4),
                                                Text(
                                                  '确认丢弃',
                                                  style: TextStyle(
                                                    color: Colors.redAccent,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              );
                              if (confirmed == true) {
                                onDiscard();
                              }
                            },
                            child: const Icon(
                              Icons.delete,
                              color: Colors.redAccent,
                              size: 16,
                            ),
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
