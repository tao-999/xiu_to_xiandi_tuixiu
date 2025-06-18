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

import '../services/refine_material_service.dart';

class LianqiPage extends StatefulWidget {
  const LianqiPage({super.key});

  @override
  State<LianqiPage> createState() => _LianqiPageState();
}

class _LianqiPageState extends State<LianqiPage> {
  late Future<Zongmen?> _zongmenFuture;
  bool _hasZhushou = false;

  // 这几个状态只由 _initBlueprintAndRefineState 控制
  bool _isRefining = false;
  DateTime? _refineEndTime;
  List<RefineBlueprint> _ownedBlueprints = [];
  RefineBlueprint? _selectedBlueprint;
  List<String> _selectedMaterials = [];

  @override
  void initState() {
    super.initState();
    _zongmenFuture = _loadZongmenAndCheckZhushou();
    _initBlueprintAndRefineState();
  }

  Future<Zongmen?> _loadZongmenAndCheckZhushou() async {
    final zongmen = await ZongmenStorage.loadZongmen();
    final disciples = await ZongmenStorage.getDisciplesByRoom('炼器房');
    setState(() {
      _hasZhushou = disciples.isNotEmpty;
      if (!_hasZhushou) {
        _selectedMaterials.clear();
      }
    });
    return zongmen;
  }

  Future<void> _initBlueprintAndRefineState() async {
    // 1. 加载已拥有图纸
    final keys = await ResourcesStorage.getBlueprintKeys();
    final all = RefineBlueprintService.generateAllBlueprints();
    final owned = all.where((b) => keys.contains('${b.type.name}-${b.level}')).toList();

    // 2. 加载炼制状态
    final state = await RefineMaterialService.loadRefineState();

    RefineBlueprint? restoredBlueprint;
    List<String> restoredMaterials = [];
    DateTime? refineEndTime;

    if (state != null) {
      try {
        final typeName = state['blueprintType'];
        final level = state['blueprintLevel'];
        final name = state['blueprintName'];
        final endTimeStr = state['endTime'];
        final materials = state['materials'];

        if (typeName is String &&
            level is int &&
            name is String &&
            endTimeStr is String &&
            materials is List) {
          final type = BlueprintType.values.firstWhere(
                (e) => e.name == typeName,
            orElse: () => BlueprintType.weapon,
          );

          refineEndTime = DateTime.parse(endTimeStr);
          restoredMaterials = List<String>.from(materials);
          restoredBlueprint = owned.firstWhereOrNull(
                (b) => b.type == type && b.level == level && b.name == name,
          );
        } else {
          print('⚠️ 状态字段类型异常，放弃恢复');
        }
      } catch (e) {
        print('❌ 恢复炼制状态异常: $e');
      }
    }

    setState(() {
      _ownedBlueprints = owned;
      _selectedBlueprint = restoredBlueprint;
      _selectedMaterials = restoredMaterials;
      _refineEndTime = refineEndTime;
      _isRefining = refineEndTime != null && refineEndTime.isAfter(DateTime.now()); // ✅ 修复核心BUG
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
                    LianqiHeader(level: level),
                    const SizedBox(height: 24),

                    /// 图纸选择
                    BlueprintDropdownSelector(
                      blueprintList: _ownedBlueprints,
                      selected: _selectedBlueprint,
                      onSelected: (val) {
                        setState(() {
                          _selectedBlueprint = val;
                          _selectedMaterials.clear();
                        });
                      },
                      isDisabled: !_hasZhushou || _isRefining,
                      maxLevelAllowed: level,
                      hasZhushou: _hasZhushou,
                    ),

                    const SizedBox(height: 24),

                    /// 材料选择器 + 炼制逻辑
                    if (_selectedBlueprint != null)
                      Center(
                        child: RefineMaterialSelector(
                          blueprint: _selectedBlueprint!,
                          selectedMaterials: _selectedMaterials,
                          onMaterialSelected: (index, name) {
                            setState(() {
                              if (index < _selectedMaterials.length) {
                                _selectedMaterials[index] = name;
                              } else {
                                while (_selectedMaterials.length <= index) {
                                  _selectedMaterials.add('');
                                }
                                _selectedMaterials[index] = name;
                              }
                            });
                          },
                          isDisabled: !_hasZhushou || _isRefining,
                          hasDisciple: _hasZhushou,
                          onRefineStarted: () async {
                            await _loadZongmenAndCheckZhushou();
                            await _initBlueprintAndRefineState(); // ✅ 主动刷新状态，UI立即更新
                          },
                          onRefineCompleted: () async {
                            await _loadZongmenAndCheckZhushou();
                            await _initBlueprintAndRefineState(); // ✅ 完成后也要刷新一次
                          },
                        ),
                      ),

                  ],
                ),
              ),

              /// 驻守弟子
              Positioned(
                bottom: 150,
                right: 20,
                child: ZhushouDiscipleSlot(
                  roomName: '炼器房',
                  onChanged: (actionType) async {
                    await _loadZongmenAndCheckZhushou();

                    if (actionType == 'remove') {
                      // 弟子移除，重置炼制状态
                      await _initBlueprintAndRefineState();
                    }
                  },
                  isRefining: _isRefining,
                ),

              ),

              /// 返回按钮
              const BackButtonOverlay(),
            ],
          );
        },
      ),
    );
  }
}
