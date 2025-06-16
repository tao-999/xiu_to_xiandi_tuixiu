import 'package:flutter/material.dart';
import 'package:collection/collection.dart';

import 'package:xiu_to_xiandi_tuixiu/models/refine_blueprint.dart';
import 'package:xiu_to_xiandi_tuixiu/models/zongmen.dart';
import 'package:xiu_to_xiandi_tuixiu/services/resources_storage.dart';
import 'package:xiu_to_xiandi_tuixiu/services/zongmen_storage.dart';
import 'package:xiu_to_xiandi_tuixiu/services/refine_blueprint_service.dart';

import 'package:xiu_to_xiandi_tuixiu/widgets/components/back_button_overlay.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/lianqi_header.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/zhushou_disciple_slot.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/refine_material_selector.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/blueprint_dropdown_selector.dart';

class LianqiPage extends StatefulWidget {
  const LianqiPage({super.key});

  @override
  State<LianqiPage> createState() => _LianqiPageState();
}

class _LianqiPageState extends State<LianqiPage> {
  late Future<Zongmen?> _zongmenFuture;
  bool _hasZhushou = false;

  List<RefineBlueprint> _ownedBlueprints = [];
  RefineBlueprint? _selectedBlueprint;

  @override
  void initState() {
    super.initState();
    _zongmenFuture = _loadZongmenAndCheckZhushou();
    _loadBlueprints();
  }

  /// ✅ 拉 Hive 判断有没有驻守弟子
  Future<Zongmen?> _loadZongmenAndCheckZhushou() async {
    final zongmen = await ZongmenStorage.loadZongmen();
    final disciples = await ZongmenStorage.getDisciplesByRoom('炼器房');
    setState(() {
      _hasZhushou = disciples.isNotEmpty;
    });
    return zongmen;
  }

  Future<void> _loadBlueprints() async {
    final keys = await ResourcesStorage.getBlueprintKeys();
    final all = RefineBlueprintService.generateAllBlueprints();
    final owned = all.where((b) => keys.contains('${b.type.name}-${b.level}')).toList();

    setState(() {
      _ownedBlueprints = owned;
      _selectedBlueprint ??= owned.firstWhereOrNull((b) => b.type == BlueprintType.weapon);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<Zongmen?>(
        future: _zongmenFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final zongmen = snapshot.data!;
          final level = ZongmenStorage.calcSectLevel(zongmen.sectExp);

          return Stack(
            children: [
              Positioned.fill(
                child: Image.asset(
                  'assets/images/zongmen_bg_lianqifang.webp',
                  fit: BoxFit.cover,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 40),

                    /// 顶部标题 + 等级
                    LianqiHeader(level: level),

                    const SizedBox(height: 24),

                    /// 🔥 图纸选择（禁用逻辑已加）
                    BlueprintDropdownSelector(
                      blueprintList: _ownedBlueprints,
                      selected: _selectedBlueprint,
                      onSelected: (val) {
                        setState(() {
                          _selectedBlueprint = val;
                        });
                      },
                      isDisabled: !_hasZhushou,
                      maxLevelAllowed: level, // ✅ 传入当前宗门等级
                    ),

                    const SizedBox(height: 16),

                    /// 👇 特效区域预留位
                    Center(
                      child: Container(
                        width: 200,
                        height: 120,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          border: Border.all(color: Colors.white24),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          '（此处预留炼器特效）',
                          style: TextStyle(
                            color: Colors.white54,
                            fontFamily: 'ZcoolCangEr',
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    /// 材料选择（后续可传入 _selectedBlueprint）
                    const RefineMaterialSelector(),

                    const SizedBox(height: 16),

                    /// 驻守弟子组件
                    ZhushouDiscipleSlot(
                      roomName: '炼器房',
                      onChanged: _loadZongmenAndCheckZhushou, // 重新判断禁用状态
                    ),
                  ],
                ),
              ),
              const BackButtonOverlay(),
            ],
          );
        },
      ),
    );
  }
}
