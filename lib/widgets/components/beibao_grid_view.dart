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
  final dynamic hiveKey;

  const BeibaoItem({
    required this.name,
    required this.imagePath,
    this.quantity,
    this.level,
    required this.description,
    required this.type,
    this.hiveKey,
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
  static const double _itemSize = 48.0;
  static const double _spacing = 4.0;
  static const int _rows = 50;
  static const int _columns = 14;

  final ScrollController _scrollController = ScrollController();
  OverlayEntry? _tooltipEntry;

  int get _fixedSlotCount => _rows * _columns;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  List<BeibaoItem?> _paddedItems(List<BeibaoItem> items, int targetLength) {
    final List<BeibaoItem?> padded = [...items];
    while (padded.length < targetLength) {
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
        _tooltipEntry?.remove();
        _tooltipEntry = null;

        switch (item.type) {
          case BeibaoItemType.weapon:
            if (item.hiveKey != null) {
              await WeaponsStorage.deleteWeaponByKey(item.hiveKey);
              print('✅ 已精准删除武器：${item.name}');
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
            break;
        }

        await widget.onReload();
        print('✅已丢弃：${item.name}');
      }
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = _paddedItems(widget.items.take(_fixedSlotCount).toList(), _fixedSlotCount);

    const Set<BeibaoItemType> _showLevelTypes = {
      BeibaoItemType.weapon,
      BeibaoItemType.pill,
      BeibaoItemType.herb,
      BeibaoItemType.refineMaterial,
    };

    return Padding(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        controller: _scrollController,
        child: Wrap(
          spacing: _spacing,
          runSpacing: _spacing,
          children: [
            for (var i = 0; i < items.length; i++) _buildSlot(items[i], _showLevelTypes),
          ],
        ),
      ),
    );
  }

  Widget _buildSlot(BeibaoItem? item, Set<BeibaoItemType> showLevelTypes) {
    if (item == null) return _buildEmptySlot();
    return GestureDetector(
      onTapDown: (details) => _showItemTooltip(context, details, item),
      child: Container(
        width: _itemSize,
        height: _itemSize,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black12),
        ),
        alignment: Alignment.center,
        child: Stack(
          children: [
            Positioned.fill(
              child: Opacity(
                opacity: (item.quantity == BigInt.zero) ? 0.3 : 1.0,
                child: Image.asset(item.imagePath, fit: BoxFit.contain),
              ),
            ),
            if (showLevelTypes.contains(item.type))
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  child: Text(
                    '${item.level}阶',
                    style: const TextStyle(fontSize: 8, color: Colors.white, height: 1.1),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptySlot() {
    return Container(
      width: _itemSize,
      height: _itemSize,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black12),
      ),
    );
  }
}
