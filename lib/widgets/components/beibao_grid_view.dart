import 'package:flutter/material.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/beibao_tooltip_overlay.dart';
import 'package:xiu_to_xiandi_tuixiu/utils/number_format.dart';

import '../../models/beibao_item_type.dart';

class BeibaoItem {
  final String name;
  final String imagePath;
  final BigInt? quantity; // ✅ 改成 BigInt 专门表示资源类数量
  final int? level; // ✅ 新增，专门表示阶数
  final String description;
  final BeibaoItemType type;

  const BeibaoItem({
    required this.name,
    required this.imagePath,
    this.quantity,
    this.level,
    required this.description,
    required this.type,
  });
}

class BeibaoGridView extends StatefulWidget {
  final List<BeibaoItem> items;

  const BeibaoGridView({super.key, required this.items});

  @override
  State<BeibaoGridView> createState() => _BeibaoGridViewState();
}

class _BeibaoGridViewState extends State<BeibaoGridView> {
  static const int _itemsPerPage = 54;
  int _currentPage = 0;
  OverlayEntry? _tooltipEntry;

  int get _maxPage => (widget.items.length / _itemsPerPage).ceil().clamp(1, double.infinity).toInt();

  List<BeibaoItem?> _paddedItems(List<BeibaoItem> items) {
    final List<BeibaoItem?> padded = [...items];
    while (padded.length < _itemsPerPage) {
      padded.add(null);
    }
    return padded;
  }

  void _showItemTooltip(BuildContext context, Offset globalPosition, BeibaoItem item) {
    _tooltipEntry?.remove();

    _tooltipEntry = BeibaoTooltipOverlay.show(
      context: context,
      position: globalPosition,
      name: item.name,
      quantity: formatAnyNumber(item.quantity),
      description: item.description,
      onDismiss: () {
        _tooltipEntry?.remove();
        _tooltipEntry = null;
      },
      type: item.type,
    );
  }

  bool _shouldShowQuantity(BeibaoItem item) {
    // ✅ 仅图纸类资源显示数量
    // 判断标准：图纸通常命名为 "xxx · 1阶" 且图片路径非武器图标
    final isBlueprint = item.name.contains('·') && item.imagePath.contains('wuqi_');
    return isBlueprint;
  }

  @override
  Widget build(BuildContext context) {
    final start = _currentPage * _itemsPerPage;
    final end = (_currentPage + 1) * _itemsPerPage;
    final pageItems = widget.items.sublist(
      start,
      end > widget.items.length ? widget.items.length : end,
    );
    final items = _paddedItems(pageItems);

    // 定义需要显示阶数的类型集合
    const Set<BeibaoItemType> _showLevelTypes = {
      BeibaoItemType.weapon,
      BeibaoItemType.pill,
      BeibaoItemType.herb,
      // 后续扩展直接加
    };

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 6,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1,
            ),
            itemBuilder: (context, index) {
              final item = items[index];
              if (item == null) {
                return _buildEmptySlot();
              } else {
                return GestureDetector(
                  onTapDown: (details) {
                    _showItemTooltip(context, details.globalPosition, item);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white10),
                    ),
                    alignment: Alignment.center,
                    // 关键骚点：Stack+Positioned.fill让图片占满整个格子
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: Opacity(
                            opacity: (item.quantity == 0 || item.quantity == BigInt.zero) ? 0.3 : 1.0,
                            child: Image.asset(
                              item.imagePath,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        if (_showLevelTypes.contains(item.type))
                          Positioned(
                            top: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              child: Text(
                                '${item.level}阶',
                                style: const TextStyle(
                                  fontSize: 8,
                                  color: Colors.white,
                                  height: 1.1,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }
            },
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                icon: Icon(
                  Icons.arrow_left,
                  size: 32,
                  color: _currentPage == 0 ? Colors.white24 : Colors.white,
                ),
                onPressed: _currentPage == 0 ? null : () => setState(() => _currentPage--),
              ),
              IconButton(
                icon: Icon(
                  Icons.arrow_right,
                  size: 32,
                  color: _currentPage >= _maxPage - 1 ? Colors.white24 : Colors.white,
                ),
                onPressed: _currentPage >= _maxPage - 1
                    ? null
                    : () => setState(() => _currentPage++),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptySlot() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white10),
      ),
    );
  }
}
