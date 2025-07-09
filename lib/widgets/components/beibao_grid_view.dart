import 'package:flutter/material.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/beibao_tooltip_overlay.dart';

import '../../data/favorability_data.dart';
import '../../models/beibao_item_type.dart';
import '../../services/favorability_material_service.dart';
import '../../services/herb_material_service.dart';
import '../../services/pill_storage_service.dart';
import '../../services/refine_material_service.dart';
import '../../services/weapons_storage.dart';

class BeibaoItem {
  final String name;
  final String imagePath;
  final BigInt? quantity;
  final int? level;
  final String description;
  final BeibaoItemType type;
  final dynamic hiveKey; // 🌟 新增，用于持久化定位

  const BeibaoItem({
    required this.name,
    required this.imagePath,
    this.quantity,
    this.level,
    required this.description,
    required this.type,
    this.hiveKey, // 🌟
  });
}

class BeibaoGridView extends StatefulWidget {
  final List<BeibaoItem> items;
  final Future<void> Function() onReload;

  const BeibaoGridView({
    super.key,
    required this.items,
    required this.onReload,
  });

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

  void _showItemTooltip(BuildContext context, TapDownDetails details, BeibaoItem item) {
    _tooltipEntry?.remove();

    final globalPosition = details.globalPosition;

    _tooltipEntry = BeibaoTooltipOverlay.show(
      context: context,
      position: globalPosition,
      name: item.name,
      quantity: item.quantity,
      description: item.description,
      type: item.type,
      onDismiss: () {
        _tooltipEntry?.remove();
        _tooltipEntry = null;
      },
      onDiscard: item.type != BeibaoItemType.resource
          ? () async {
        // 先移除 Tooltip
        _tooltipEntry?.remove();
        _tooltipEntry = null;

        // 根据类型进行删除
        switch (item.type) {
          case BeibaoItemType.weapon:
            if (item.hiveKey != null) {
              await WeaponsStorage.deleteWeaponByKey(item.hiveKey);
              print('✅ 已精准删除武器：${item.name}');
            } else {
              print('⚠️ 无法删除武器：未找到hiveKey');
            }
            break;

          case BeibaoItemType.pill:
            await PillStorageService.deletePillByKey(item.hiveKey);
            print('✅ 已删除所有丹药：${item.name}');
            break;

          case BeibaoItemType.herb:
            await HerbMaterialService.remove(item.name);
            print('✅ 已清空草药：${item.name}');
            break;

          case BeibaoItemType.refineMaterial:
            await RefineMaterialService.remove(item.name);
            print('✅ 已清空炼器材料：${item.name}');
            break;

          case BeibaoItemType.favorabilityMaterial:
            final index = FavorabilityData.indexOf(item.name);
            await FavorabilityMaterialService.consumeMaterial(index, item.quantity?.toInt() ?? 999999);
            print('✅ 已清空好感度材料：${item.name}');
            break;

          default:
          // resource不允许丢弃
            print('⚠️ Resource类型不允许丢弃：${item.name}');
            break;
        }
        // 重新加载背包
        await widget.onReload();

        print('✅已丢弃：${item.name}');
      }
          : null,
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

    // 定义需要显示阶数的类型集合
    const Set<BeibaoItemType> _showLevelTypes = {
      BeibaoItemType.weapon,
      BeibaoItemType.pill,
      BeibaoItemType.herb,
      BeibaoItemType.refineMaterial,
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
                    _showItemTooltip(context, details, item);
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
