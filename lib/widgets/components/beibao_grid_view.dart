import 'package:flutter/material.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/beibao_tooltip_overlay.dart';
import '../../services/beibao_slot_storage_service.dart';
import '../../services/resources_storage.dart';

import '../../data/favorability_data.dart';
import '../../models/beibao_item_type.dart';
import '../../services/favorability_material_service.dart';
import '../../services/herb_material_service.dart';
import '../../services/pill_storage_service.dart';
import '../../services/refine_material_service.dart';
import '../../services/weapons_storage.dart';
import '../../utils/lingshi_util.dart';
import '../common/toast_tip.dart';

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
  final VoidCallback? onSlotUnlocked; // 🔥 新增，传父级刷新回调

  const BeibaoGridView({
    super.key,
    required this.items,
    required this.onReload,
    this.onSlotUnlocked, // 🔥 记得接收
  });

  @override
  State<BeibaoGridView> createState() => _BeibaoGridViewState();
}

class _BeibaoGridViewState extends State<BeibaoGridView> {
  static const double _itemSize = 48.0;
  static const double _spacing = 4.0;
  static const int _rows = 10;
  static const int _columns = 14;
  int _currentSlotCount = _rows * _columns;
  OverlayEntry? _tooltipEntry;
  bool _loading = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _initSlotCount();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initSlotCount() async {
    final cnt = await BeibaoSlotStorageService.getSlotCount();
    setState(() {
      _currentSlotCount = cnt;
      _loading = false;
    });
    _scrollToBottom();
  }

  Future<void> _tryIncreaseSlotCount() async {
    final confirmed = await BeibaoSlotStorageService.getUnlockConfirmed();

    // 只弹一次
    if (!confirmed) {
      final confirm = await showDialog<bool>(
        context: context,
        barrierDismissible: true,
        builder: (ctx) => Align(
          alignment: Alignment.center,
          child: SizedBox(
            width: 420,
            child: Dialog(
              backgroundColor: const Color(0xFFFFF8E1),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
              insetPadding: EdgeInsets.zero,
              child: Container(
                padding: const EdgeInsets.fromLTRB(32, 24, 32, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      '解锁新格子',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.brown[900],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Image.asset(getLingShiImagePath(LingShiType.supreme), width: 14, height: 14),
                        const SizedBox(width: 8), // 控制间距
                        const Text(
                          '我自愿消耗 1 个极品灵石，解锁一个新格子！',
                          style: TextStyle(fontSize: 13, color: Color(0xFF7B5B19)),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    GestureDetector(
                      onTap: () => Navigator.of(ctx).pop(true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 10),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.check_circle, color: Colors.brown, size: 22),
                            SizedBox(width: 6),
                            Text(
                              '确定',
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.brown,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      if (confirm != true) return;
      await BeibaoSlotStorageService.setUnlockConfirmed(true);
    }

    // 灵石判断/扩容逻辑...
    BigInt count = await ResourcesStorage.getValue(lingShiFieldMap[LingShiType.supreme]!);
    if (count < BigInt.one) {
      ToastTip.show(context, '极品灵石不足，无法扩容');
      return;
    }

    await ResourcesStorage.subtract(lingShiFieldMap[LingShiType.supreme]!, BigInt.one);
    final next = _currentSlotCount + 1;
    await BeibaoSlotStorageService.setSlotCount(next);
    setState(() {
      _currentSlotCount = next;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    ToastTip.show(context, '已消耗1极品灵石，成功解锁新格子！');

    // 🔥 回调给父组件
    if (widget.onSlotUnlocked != null) {
      widget.onSlotUnlocked!();
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
      );
    }
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
            print('⚠️ Resource类型不允许丢弃：${item.name}');
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
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    // 最后一个格子永远为“+”
    final realSlotCount = _currentSlotCount;
    final showItems = widget.items.take(realSlotCount - 1).toList();
    final items = _paddedItems(showItems, realSlotCount - 1);

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
            for (var i = 0; i < items.length; i++)
              _buildSlot(items[i], _showLevelTypes),
            _buildAddSlot(),
          ],
        ),
      ),
    );
  }

  Widget _buildSlot(BeibaoItem? item, Set<BeibaoItemType> showLevelTypes) {
    if (item == null) {
      return _buildEmptySlot();
    }
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
                opacity: (item.quantity == 0 || item.quantity == BigInt.zero) ? 0.3 : 1.0,
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

  Widget _buildAddSlot() {
    return GestureDetector(
      onTap: _tryIncreaseSlotCount,
      child: Container(
        width: _itemSize,
        height: _itemSize,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black87, width: 1),
        ),
        alignment: Alignment.center,
        child: Icon(Icons.add, color: Colors.black87, size: 28),
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
