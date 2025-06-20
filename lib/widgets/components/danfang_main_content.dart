import 'dart:async';
import 'package:flutter/material.dart';
import 'package:xiu_to_xiandi_tuixiu/models/pill_blueprint.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/alchemy_material_selector.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/danfang_header.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/select_pill_blueprint.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/alchemy_quantity_selector.dart';
import '../../models/pill.dart';
import '../../services/pill_storage_service.dart';
import '../effects/five_star_danfang_array.dart';
import '../../services/danfang_service.dart';
import '../../services/zongmen_storage.dart';
import '../common/toast_tip.dart';

class DanfangMainContent extends StatefulWidget {
  final int level;
  final GlobalKey<FiveStarAlchemyArrayState> arrayKey;
  final void Function(bool isRefining)? onRefineStateChanged;
  final void Function(bool isAnimationRunning)? onAnimationStateChanged;

  const DanfangMainContent({
    super.key,
    required this.level,
    required this.arrayKey,
    this.onRefineStateChanged,
    this.onAnimationStateChanged,
  });

  @override
  State<DanfangMainContent> createState() => _DanfangMainContentState();
}

class _DanfangMainContentState extends State<DanfangMainContent> {
  PillBlueprint? _selectedBlueprint;
  List<String> _selectedMaterials = [];
  Timer? _timer;
  bool _isRefining = false;
  int _maxAlchemyCount = 1;
  int _selectedCount = 1;

  @override
  void initState() {
    super.initState();
    _startTimer();
    _checkAndRestoreState();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _checkAndRestoreState());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _checkAndRestoreState() async {
    final end = await DanfangService.loadCooldown();
    final now = DateTime.now();

    // 1. 冷却中：正常逻辑
    if (end != null && now.isBefore(end)) {
      if (!_isRefining) {
        setState(() => _isRefining = true);
        widget.onRefineStateChanged?.call(true);
      }

      final bp = await DanfangService.loadSelectedBlueprint();
      final mats = await DanfangService.loadSelectedMaterials();

      if (mounted) {
        setState(() {
          _selectedBlueprint = bp;
          _selectedMaterials = List<String>.from(mats ?? []);
        });

        WidgetsBinding.instance.addPostFrameCallback((_) {
          widget.arrayKey.currentState?.setFinalStateManually();
        });
      }
    }
    // 2. 冷却时间刚结束：产出丹药！
    else if (_isRefining && (end != null && now.isAfter(end))) {
      // 💥 在这里调用发丹药的逻辑
      await _onRefineFinish(); // 记得防止多次触发！

      setState(() {
        _isRefining = false;
        _selectedBlueprint = null;
        _selectedMaterials = [];
      });
      widget.onRefineStateChanged?.call(false);

      await DanfangService.clearCooldown();
      await DanfangService.saveSelectedMaterials([]);
      await DanfangService.clearSelectedBlueprint();

      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.arrayKey.currentState?.resetToIdle();
      });
    }
    // 3. 彻底无炼丹状态，常规清理
    else {
      if (_isRefining) {
        setState(() {
          _isRefining = false;
          _selectedBlueprint = null;
          _selectedMaterials = [];
        });
        widget.onRefineStateChanged?.call(false);
      }

      await DanfangService.clearCooldown();
      await DanfangService.saveSelectedMaterials([]);
      await DanfangService.clearSelectedBlueprint();

      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.arrayKey.currentState?.resetToIdle();
      });
    }
  }

  void _onMaterialSelected(int index, String name) async {
    setState(() {
      if (_selectedMaterials.length > index) {
        _selectedMaterials[index] = name;
      } else {
        while (_selectedMaterials.length < index) {
          _selectedMaterials.add('');
        }
        _selectedMaterials.add(name);
      }
    });

    DanfangService.saveSelectedMaterials(_selectedMaterials);
    _updateMaxCount();
  }

  Future<void> _onRefineFinish() async {
    if (_selectedBlueprint == null) return;

    final newPill = Pill(
      name: _selectedBlueprint!.name,
      level: _selectedBlueprint!.level,
      type: switch (_selectedBlueprint!.type) {
        PillBlueprintType.attack => PillType.attack,
        PillBlueprintType.defense => PillType.defense,
        PillBlueprintType.health => PillType.health,
      },
      count: _selectedCount,
      bonusAmount: _selectedBlueprint!.effectValue,
      createdAt: DateTime.now(),
      iconPath: _selectedBlueprint!.iconPath, // 🏅骚气加上图标
    );

    await PillStorageService.addPill(newPill);

    ToastTip.show(context, '炼制成功！获得${newPill.name}x${newPill.count}');
  }

  void _onBlueprintSelected(PillBlueprint blueprint) {
    setState(() {
      _selectedBlueprint = blueprint;
      _selectedMaterials = [];
      _maxAlchemyCount = 1;
      _selectedCount = 1;
    });

    DanfangService.saveSelectedBlueprint(blueprint);
    DanfangService.saveSelectedMaterials([]);
  }

  Future<void> _updateMaxCount() async {
    final count = await DanfangService.getMaxAlchemyCount(_selectedMaterials);
    if (mounted) {
      setState(() {
        _maxAlchemyCount = count.clamp(1, 999);
        _selectedCount = _selectedCount.clamp(1, _maxAlchemyCount);
      });
    }
  }

  Future<void> _tryStartAlchemy() async {
    _timer?.cancel();

    if (_selectedBlueprint == null) {
      ToastTip.show(context, '请先选择丹方～');
      return;
    }

    if (_selectedMaterials.length < 3 || _selectedMaterials.any((e) => e.isEmpty)) {
      ToastTip.show(context, '请先选择三种草药材料～');
      return;
    }

    final disciples = await ZongmenStorage.getDisciplesByRoom('炼丹房');
    if (disciples.isEmpty) {
      ToastTip.show(context, '炼丹房还没有驻守弟子哦～');
      return;
    }

    final array = widget.arrayKey.currentState;
    if (array != null) {
      widget.onAnimationStateChanged?.call(true);

      array.onAnimationComplete = () async {
        final totalAptitude = disciples.fold<int>(0, (sum, d) => sum + (d.aptitude ?? 0));

        // ✅ 计算每颗的时间，再乘以炼制数量
        final perUnitTime = DanfangService.calculateRefineDuration(
          _selectedBlueprint!.level,
          totalAptitude,
        );
        final durationSeconds = perUnitTime * _selectedCount;

        final endTime = DateTime.now().add(Duration(seconds: durationSeconds));

        await DanfangService.saveCooldown(endTime);
        await DanfangService.saveSelectedBlueprint(_selectedBlueprint!);
        await DanfangService.saveSelectedMaterials(_selectedMaterials);
        await DanfangService.consumeHerbs(_selectedMaterials, _selectedCount);

        if (mounted) {
          setState(() => _isRefining = true);
          widget.onRefineStateChanged?.call(true);
          widget.onAnimationStateChanged?.call(false);
          _startTimer();

          ToastTip.show(
            context,
            '炼丹开始啦～共炼制 $_selectedCount 枚，预计${(durationSeconds ~/ 60)}分${(durationSeconds % 60)}秒后完成！',
          );
        }
      };

      await array.start();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40),
          DanfangHeader(level: widget.level),
          const SizedBox(height: 24),
          SelectPillBlueprintButton(
            currentSectLevel: widget.level,
            onSelected: _onBlueprintSelected,
            isDisabled: _isRefining,
          ),
          const SizedBox(height: 24),
          Center(
            child: GestureDetector(
              onTap: _isRefining ? null : _tryStartAlchemy,
              child: SizedBox(
                width: 300,
                height: 300,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    FiveStarAlchemyArray(
                      key: widget.arrayKey,
                      radius: 150,
                      bigDanluSize: 200,
                      smallDanluSize: 100,
                    ),
                    if (_selectedBlueprint != null)
                      Image.asset(
                        'assets/images/${_selectedBlueprint!.iconPath}',
                        width: 48,
                        height: 48,
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          AlchemyMaterialSelector(
            selectedBlueprint: _selectedBlueprint,
            selectedMaterials: _selectedMaterials,
            onMaterialSelected: _onMaterialSelected,
            isDisabled: _isRefining,
          ),
          if (!_isRefining && _maxAlchemyCount > 1)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: AlchemyQuantitySelector(
                maxCount: _maxAlchemyCount,
                initial: _selectedCount,
                onChanged: (value) {
                  setState(() {
                    _selectedCount = value;
                  });
                },
              ),
            ),
          FutureBuilder<DateTime?>(
            future: DanfangService.loadCooldown(),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data == null) return const SizedBox.shrink();
              final endTime = snapshot.data!;
              final now = DateTime.now();
              final left = endTime.difference(now);
              if (left.isNegative) return const SizedBox.shrink();

              final min = left.inMinutes;
              final sec = (left.inSeconds % 60).toString().padLeft(2, '0');

              return Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Center(
                  child: Text(
                    '$min:$sec',
                    style: const TextStyle(
                      color: Colors.orange,
                      fontSize: 18,
                      fontFamily: 'RobotoMono',
                      letterSpacing: 2,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 64),
        ],
      ),
    );
  }
}
