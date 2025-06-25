import 'dart:async';
import 'package:flutter/material.dart';
import 'package:collection/collection.dart';

import 'package:xiu_to_xiandi_tuixiu/models/refine_blueprint.dart';
import 'package:xiu_to_xiandi_tuixiu/models/zongmen.dart';
import 'package:xiu_to_xiandi_tuixiu/services/resources_storage.dart';
import 'package:xiu_to_xiandi_tuixiu/services/zongmen_storage.dart';
import 'package:xiu_to_xiandi_tuixiu/services/refine_blueprint_service.dart';
import 'package:xiu_to_xiandi_tuixiu/services/refine_material_service.dart';

import 'package:xiu_to_xiandi_tuixiu/widgets/components/back_button_overlay.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/lianqi_header.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/zhushou_disciple_slot.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/refine_material_selector.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/select_refine_blueprint_button.dart';

class LianqiPage extends StatefulWidget {
  const LianqiPage({super.key});

  @override
  State<LianqiPage> createState() => _LianqiPageState();
}

class _LianqiPageState extends State<LianqiPage> with WidgetsBindingObserver {
  late Future<Zongmen?> _zongmenFuture;
  bool _hasZhushou = false;

  bool _isRefining = false;
  List<RefineBlueprint> _ownedBlueprints = [];
  RefineBlueprint? _selectedBlueprint;
  List<String> _selectedMaterials = [];

  int _refineStateVersion = 0; // ✅ 强制刷新 RefineMaterialSelector 的 key

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _zongmenFuture = _loadZongmenAndCheckZhushou();
    _initBlueprintAndRefineState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _initBlueprintAndRefineState(); // ✅ 切换回前台时刷新炼制状态
    }
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
    final keys = await ResourcesStorage.getBlueprintKeys();
    final all = RefineBlueprintService.generateAllBlueprints();
    final owned = all.where((b) => keys.contains('${b.type.name}-${b.level}')).toList();

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
      _isRefining = refineEndTime != null && refineEndTime.isAfter(DateTime.now());
      _refineStateVersion++; // ✅ 每次刷新炼制状态都触发 Selector 重建
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
                    SelectRefineBlueprintButton(
                      selected: _selectedBlueprint,
                      onSelected: (val) {
                        setState(() {
                          _selectedBlueprint = val;
                          _selectedMaterials.clear();
                        });
                      },
                      maxLevelAllowed: level, // ✅ 来自宗门经验计算出的可炼阶数
                      isDisabled: !_hasZhushou || _isRefining,
                    ),
                    const SizedBox(height: 24),
                    if (_selectedBlueprint != null)
                      Center(
                        child: RefineMaterialSelector(
                          key: ValueKey('selector-$_refineStateVersion'), // ✅ 重建关键点
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
                            await _initBlueprintAndRefineState();
                          },
                          onRefineCompleted: () async {
                            await _loadZongmenAndCheckZhushou();
                            await _initBlueprintAndRefineState();
                          },
                        ),
                      ),
                  ],
                ),
              ),
              Positioned(
                bottom: 150,
                right: 20,
                child: ZhushouDiscipleSlot(
                  roomName: '炼器房',
                  onChanged: (actionType) async {
                    await _loadZongmenAndCheckZhushou();
                    if (actionType == 'remove') {
                      await _initBlueprintAndRefineState();
                    }
                  },
                  isRefining: _isRefining,
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
