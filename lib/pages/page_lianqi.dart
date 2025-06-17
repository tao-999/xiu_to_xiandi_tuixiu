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

class _LianqiPageState extends State<LianqiPage> with TickerProviderStateMixin {
  late Future<Zongmen?> _zongmenFuture;
  bool _hasZhushou = false;

  List<RefineBlueprint> _ownedBlueprints = [];
  RefineBlueprint? _selectedBlueprint;
  List<String> _selectedMaterials = [];

  late AnimationController _floatController;
  late Animation<double> _floatAnimation;

  @override
  void initState() {
    super.initState();

    _zongmenFuture = _loadZongmenAndCheckZhushou();
    _loadBlueprints();

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _floatAnimation = Tween<double>(begin: -6.0, end: 6.0).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
  }

  Future<Zongmen?> _loadZongmenAndCheckZhushou() async {
    final zongmen = await ZongmenStorage.loadZongmen();
    final disciples = await ZongmenStorage.getDisciplesByRoom('炼器房');
    setState(() {
      _hasZhushou = disciples.isNotEmpty;
      if (!_hasZhushou) {
        _selectedMaterials.clear(); // ✅ 清空材料选择
      }
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
                      isDisabled: !_hasZhushou,
                      maxLevelAllowed: level,
                    ),

                    const SizedBox(height: 16),

                    /// 中心浮动展示图标
                    Center(
                      child: _selectedBlueprint == null
                          ? const SizedBox.shrink()
                          : AnimatedBuilder(
                        animation: _floatAnimation,
                        builder: (context, child) {
                          return Transform.translate(
                            offset: Offset(0, _floatAnimation.value),
                            child: Image.asset(
                              'assets/images/${_selectedBlueprint!.iconPath}',
                              width: 256,
                              height: 256,
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 16),

                    /// 材料选择器
                    if (_selectedBlueprint != null)
                      RefineMaterialSelector(
                        blueprint: _selectedBlueprint!,
                        selectedMaterials: _selectedMaterials,
                        onMaterialSelected: (index, name) {
                          setState(() {
                            if (index < _selectedMaterials.length) {
                              _selectedMaterials[index] = name;
                            } else {
                              // ✅ 补空位
                              while (_selectedMaterials.length <= index) {
                                _selectedMaterials.add('');
                              }
                              _selectedMaterials[index] = name;
                            }
                          });
                        },
                        isDisabled: !_hasZhushou, // ✅ 是否禁用
                      ),

                    const SizedBox(height: 16),

                    ZhushouDiscipleSlot(
                      roomName: '炼器房',
                      onChanged: _loadZongmenAndCheckZhushou,
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
