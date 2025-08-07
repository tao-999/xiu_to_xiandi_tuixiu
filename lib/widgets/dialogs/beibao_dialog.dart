import 'package:flutter/material.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/beibao_grid_view.dart';
import '../../services/gongfa_collected_storage.dart';
import '../../services/resources_storage.dart';
import '../../data/beibao_resource_config.dart';
import '../../models/beibao_item_type.dart';
import '../../models/pill.dart';
import '../../services/favorability_material_service.dart';
import '../../services/herb_material_service.dart';
import '../../services/pill_storage_service.dart';
import '../../services/refine_material_service.dart';
import '../../services/weapons_storage.dart';
import '../../data/favorability_data.dart';

class BeibaoDialog extends StatefulWidget {
  final VoidCallback? onChanged; // 🔥 新增

  const BeibaoDialog({super.key, this.onChanged});

  @override
  State<BeibaoDialog> createState() => _BeibaoDialogState();
}

class _BeibaoDialogState extends State<BeibaoDialog> {
  List<BeibaoItem> items = [];

  @override
  void initState() {
    super.initState();
    _loadResources();
  }

  Future<void> _loadResources() async {
    List<BeibaoItem> newItems = [];

    for (final config in beibaoResourceList) {
      final quantity = await ResourcesStorage.getValue(config.field);
      if (quantity == null || quantity == BigInt.zero) continue;

      newItems.add(BeibaoItem(
        name: config.name,
        imagePath: config.imagePath,
        quantity: quantity,
        description: config.description,
        type: BeibaoItemType.resource,
      ));
    }

    final weaponsWithKeys = await WeaponsStorage.loadWeaponsWithKeys();
    weaponsWithKeys.forEach((key, w) {
      if (w.equippedById != null) return;

      String attrText = '';
      if (w.attackBoost > 0) attrText += '攻击 +${w.attackBoost}% ';
      if (w.defenseBoost > 0) attrText += '防御 +${w.defenseBoost}% ';
      if (w.hpBoost > 0) attrText += '血量 +${w.hpBoost}%';

      newItems.add(BeibaoItem(
        name: w.name,
        imagePath: w.iconPath,
        level: w.level,
        quantity: null,
        description: '效果：$attrText',
        type: BeibaoItemType.weapon,
        hiveKey: key,
      ));
    });

    final pills = await PillStorageService.loadAllPills();
    for (final p in pills) {
      String effect = '';
      switch (p.type) {
        case PillType.attack:
          effect = '攻击 +${p.bonusAmount}';
          break;
        case PillType.defense:
          effect = '防御 +${p.bonusAmount}';
          break;
        case PillType.health:
          effect = '血气 +${p.bonusAmount}';
          break;
      }

      newItems.add(BeibaoItem(
        name: p.name,
        imagePath: p.iconPath.startsWith('assets/')
            ? p.iconPath
            : 'assets/images/${p.iconPath}',
        level: p.level,
        quantity: BigInt.from(p.count),
        description: '效果：$effect',
        type: BeibaoItemType.pill,
      ));
    }

    final allHerbs = HerbMaterialService.generateAllMaterials();
    final herbInventory = await HerbMaterialService.loadInventory();

    for (final herb in allHerbs) {
      final count = herbInventory[herb.name] ?? 0;
      if (count > 0) {
        newItems.add(BeibaoItem(
          name: herb.name,
          imagePath: herb.image,
          level: herb.level,
          quantity: BigInt.from(count),
          description: '炼制${herb.level}阶丹药',
          type: BeibaoItemType.herb,
        ));
      }
    }

    final allMats = RefineMaterialService.generateAllMaterials();
    final matInventory = await RefineMaterialService.loadInventory();

    for (final mat in allMats) {
      final count = matInventory[mat.name] ?? 0;
      if (count > 0) {
        newItems.add(BeibaoItem(
          name: mat.name,
          imagePath: mat.image,
          level: mat.level,
          quantity: BigInt.from(count),
          description: '炼制${mat.level}阶武器',
          type: BeibaoItemType.refineMaterial,
        ));
      }
    }

    final favorInventory = await FavorabilityMaterialService.getAllMaterials();
    favorInventory.forEach((index, qty) {
      if (qty > 0) {
        final item = FavorabilityData.getByIndex(index);
        newItems.add(BeibaoItem(
          name: item.name,
          imagePath: item.assetPath,
          level: null,
          quantity: BigInt.from(qty),
          description: '可提升弟子好感度 +${item.favorValue}',
          type: BeibaoItemType.favorabilityMaterial,
        ));
      }
    });

    final gongfaList = await GongfaCollectedStorage.getAllGongfa();
    for (final g in gongfaList) {
      newItems.add(BeibaoItem(
        name: g.name,
        imagePath: g.iconPath.startsWith('assets/')
            ? g.iconPath
            : 'assets/images/${g.iconPath}', // 保底兜个路径
        level: g.level,
        quantity: BigInt.from(g.count),
        description: '品阶：${g.level}，描述：${g.description}',
        type: BeibaoItemType.gongfa, // 你要在 enum 里加这个类型哦！
        hiveKey: '${g.id}_${g.level}', // 可选，给未来操作用
      ));
    }

    setState(() {
      items = newItems;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(40),
      child: Container(
        width: 800,
        height: 900,
        color: const Color(0xFFFFF8DC),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: BeibaoGridView(
            items: items,
            onReload: _loadResources,
          ),
        ),
      ),
    );
  }
}
