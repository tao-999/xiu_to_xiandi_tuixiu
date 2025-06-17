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
  bool _isRefining = false;
  DateTime? _refineEndTime;

  List<RefineBlueprint> _ownedBlueprints = [];
  RefineBlueprint? _selectedBlueprint;
  List<String> _selectedMaterials = [];

  @override
  void initState() {
    super.initState();

    _zongmenFuture = _loadZongmenAndCheckZhushou();
    _loadBlueprints();
    _tryRestoreRefineState();
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

  Future<void> _tryRestoreRefineState() async {
    final state = await RefineMaterialService.loadRefineState();
    if (state == null) return;

    final type = BlueprintType.values.firstWhere((e) => e.name == state['blueprintType']);
    final level = state['blueprintLevel'] as int;
    final name = state['blueprintName'] as String;

    final matchedBlueprint = _ownedBlueprints.firstWhere(
          (b) => b.type == type && b.level == level && b.name == name,
      orElse: () => _ownedBlueprints.first, // 找不到就默认第一个
    );

    final selectedMaterials = List<String>.from(state['materials']);
    final startTime = DateTime.parse(state['startTime']);
    final durationMinutes = state['durationMinutes'] as int;
    final endTime = startTime.add(Duration(minutes: durationMinutes));
    final now = DateTime.now();

    if (endTime.isBefore(now)) {
      // 如果时间已过 → 清除状态
      await RefineMaterialService.clearRefineState();
      return;
    }

    setState(() {
      _selectedBlueprint = matchedBlueprint;     // ✅ 必须是 dropdown 列表里的引用！
      _selectedMaterials = selectedMaterials;
      _isRefining = true;
      _refineEndTime = endTime;
    });

    // 🔥 如果你有炼制动画组件，可以在这里直接启动（比如调用 overlay 显示）
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
                      isDisabled: !_hasZhushou || _isRefining, // ✅ 加上炼制中禁用判断！
                      maxLevelAllowed: level,
                      hasZhushou: _hasZhushou,
                    ),

                    const SizedBox(height: 24),

                    /// 整合后的武器图标 + 材料选择器
                    /// 整合后的武器图标 + 材料选择器
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
                          isDisabled: !_hasZhushou || _isRefining, // ✅ 别忘判断炼制状态！
                          hasDisciple: _hasZhushou,
                          onRefineCompleted: () async {
                            await _loadZongmenAndCheckZhushou();
                            await _loadBlueprints();
                            setState(() {
                              _selectedMaterials.clear();
                              _isRefining = false;
                            });
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
                  onChanged: _loadZongmenAndCheckZhushou,
                  allowRemove: !_isRefining, // ✅ 炼制中不允许任何操作
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
