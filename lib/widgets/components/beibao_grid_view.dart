import 'package:flutter/material.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/beibao_tooltip_overlay.dart';
import 'package:xiu_to_xiandi_tuixiu/utils/number_format.dart';

class BeibaoItem {
  final String name;
  final String imagePath;
  final dynamic quantity;
  final String description;

  const BeibaoItem({
    required this.name,
    required this.imagePath,
    required this.quantity,
    required this.description,
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
    );
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
                    child: Opacity(
                      opacity: (item.quantity == 0 || item.quantity == BigInt.zero) ? 0.3 : 1.0,
                      child: Image.asset(
                        item.imagePath,
                        width: 32,
                        height: 32,
                        fit: BoxFit.contain,
                      ),
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
