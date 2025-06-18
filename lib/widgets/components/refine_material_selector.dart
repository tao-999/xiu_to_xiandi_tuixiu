import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:xiu_to_xiandi_tuixiu/models/refine_blueprint.dart';
import 'package:xiu_to_xiandi_tuixiu/services/refine_material_service.dart';
import '../../services/weapons_storage.dart';
import '../common/toast_tip.dart';

class RefineMaterialSelector extends StatefulWidget {
  final RefineBlueprint blueprint;
  final List<String> selectedMaterials;
  final void Function(int index, String name) onMaterialSelected;
  final bool isDisabled;
  final bool hasDisciple;
  final VoidCallback? onRefineCompleted;
  final VoidCallback? onRefineStarted;

  const RefineMaterialSelector({
    super.key,
    required this.blueprint,
    required this.selectedMaterials,
    required this.onMaterialSelected,
    this.isDisabled = false,
    this.hasDisciple = true,
    this.onRefineCompleted,
    this.onRefineStarted,
  });

  @override
  State<RefineMaterialSelector> createState() => _RefineMaterialSelectorState();
}

class _RefineMaterialSelectorState extends State<RefineMaterialSelector> with SingleTickerProviderStateMixin {
  Map<String, int> ownedMaterials = {};
  final double stackSize = 300;
  final double weaponSize = 200;
  late final List<Offset> _materialOffsets;

  bool _isRefining = false;
  int _remainingSeconds = 0;
  Timer? _refineTimer;

  late Ticker _ticker;
  double _rotationAngle = 0;

  @override
  void initState() {
    super.initState();
    _loadOwnedMaterials();
    _restoreRefineState();

    final center = Offset(stackSize / 2 - 24, stackSize / 2 - 24);
    final r = 100.0;
    _materialOffsets = [
      Offset(center.dx + r * cos(-pi / 2), center.dy + r * sin(-pi / 2)),
      Offset(center.dx + r * cos(pi / 6), center.dy + r * sin(pi / 6)),
      Offset(center.dx + r * cos(5 * pi / 6), center.dy + r * sin(5 * pi / 6)),
    ];

    _ticker = createTicker((elapsed) {
      if (_isRefining) {
        setState(() => _rotationAngle += 0.05);
      }
    })..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _refineTimer?.cancel();
    super.dispose();
  }

  Future<void> _restoreRefineState() async {
    final state = await RefineMaterialService.loadRefineState();
    if (state == null) {
      print('📦 没有炼制状态，跳过恢复');
      return;
    }

    print('📦 读取炼制状态：$state');

    final blueprintName = state['blueprintName'];
    final blueprintLevel = state['blueprintLevel'];
    final blueprintType = state['blueprintType'];
    final endTimeStr = state['endTime'];

    if (widget.blueprint.name != blueprintName ||
        widget.blueprint.level != blueprintLevel ||
        widget.blueprint.type.name != blueprintType) {
      print('⚠️ 炼制状态不属于当前蓝图，跳过恢复');
      return;
    }

    if (endTimeStr == null) {
      print('❌ 缺少 endTime 字段，无法恢复');
      return;
    }

    final endTime = DateTime.tryParse(endTimeStr);
    if (endTime == null) {
      print('❌ endTime 无法解析');
      return;
    }

    final now = DateTime.now();
    final remaining = endTime.difference(now).inSeconds;

    // 🧾 打印核心数据
    print('🔧 当前时间: $now');
    print('🔧 应结束时间: $endTime');
    print('🔧 剩余秒数: $remaining');

    if (remaining <= 0) {
      print('✅ 已过期 → 自动领取武器');
      await RefineMaterialService.clearRefineState();
      await WeaponsStorage.createFromBlueprint(widget.blueprint, createdAt: endTime);
      if (widget.onRefineCompleted != null) {
        widget.onRefineCompleted!();
      }
      ToastTip.show(context, '🎉 炼制完成，武器已自动领取！');
      return;
    }

    // 🔄 正常恢复倒计时
    print('⏳ 炼制仍在进行中，开始倒计时');
    setState(() {
      _isRefining = true;
      _remainingSeconds = remaining;
    });

    _refineTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (_remainingSeconds <= 1) {
        print('🧨 倒计时结束，发放武器');
        timer.cancel();
        setState(() {
          _isRefining = false;
          _rotationAngle = 0;
        });

        await RefineMaterialService.clearRefineState();
        await WeaponsStorage.createFromBlueprint(widget.blueprint);
        ToastTip.show(context, '🎉 炼制完成！武器已入库！');

        setState(() {
          widget.selectedMaterials.clear(); // ✅ 清空材料状态
        });

        if (widget.onRefineCompleted != null) {
          widget.onRefineCompleted!();
        }
      } else {
        _remainingSeconds--;
        print('⏱️ 还剩 $_remainingSeconds 秒');
        setState(() {});
      }
    });
  }

  Future<void> _loadOwnedMaterials() async {
    final inv = await RefineMaterialService.loadInventory();
    setState(() {
      ownedMaterials = inv..removeWhere((key, value) => value <= 0);
    });
  }

  Future<void> _startRefining() async {
    final duration = await RefineMaterialService.getRefineDuration(widget.blueprint.level);
    if (duration == null) {
      ToastTip.show(context, '炼器房空空如也，没弟子还想炼器？先派一个吧～');
      return;
    }

    for (final name in widget.selectedMaterials) {
      if (name.trim().isNotEmpty) {
        await RefineMaterialService.add(name, -1);
      }
    }

    final now = DateTime.now();
    final endTime = now.add(duration);

    await RefineMaterialService.saveRefineState(
      endTime: endTime,
      blueprint: widget.blueprint,
      selectedMaterials: widget.selectedMaterials,
    );

    setState(() {
      _isRefining = true;
      _remainingSeconds = duration.inSeconds;
    });

    // ✅ 通知父组件：炼制开始啦
    widget.onRefineStarted?.call();

    _refineTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (_remainingSeconds <= 1) {
        timer.cancel();
        setState(() {
          _isRefining = false;
          _rotationAngle = 0;
        });

        // ✅ 发放武器
        await WeaponsStorage.createFromBlueprint(widget.blueprint);

        ToastTip.show(context, '🎉 炼制完成！武器已入库！');

        // ✅ 清除状态
        await RefineMaterialService.clearRefineState();

        // ✅ 通知父组件
        widget.onRefineCompleted?.call();
      } else {
        setState(() => _remainingSeconds--);
      }
    });
  }

  void _onWeaponTapped() {
    if (_isRefining || !widget.hasDisciple || widget.isDisabled) return;
    if (widget.selectedMaterials.length != 3 || widget.selectedMaterials.any((m) => m.trim().isEmpty)) {
      ToastTip.show(context, '三种材料都选好才能开始炼器哦！');
      return;
    }
    _startRefining();
  }

  void _selectMaterial(int index) async {
    if (widget.isDisabled || !widget.hasDisciple || _isRefining) return;

    final tempInventory = Map<String, int>.from(ownedMaterials);
    for (final name in widget.selectedMaterials) {
      if (name.trim().isEmpty) continue;
      if (tempInventory.containsKey(name)) {
        tempInventory[name] = tempInventory[name]! - 1;
        if (tempInventory[name]! <= 0) tempInventory.remove(name);
      }
    }

    final usable = widget.blueprint.materials.where((m) => tempInventory.containsKey(m)).toList();
    if (usable.isEmpty) {
      showDialog(
        context: context,
        builder: (_) => Dialog(
          backgroundColor: const Color(0xFFFFF7E5),
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          child: const Padding(
            padding: EdgeInsets.all(16),
            child: Text('你身无分文，一块炼器材料都没有…\n还想炼器？先去搬砖吧。', textAlign: TextAlign.center),
          ),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: const Color(0xFFFFF7E5),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: usable.map((name) {
              final mat = RefineMaterialService.getByName(name);
              final count = tempInventory[name] ?? 0;
              return GestureDetector(
                onTap: () {
                  if (widget.selectedMaterials.asMap().entries.any((e) => e.key != index && e.value == name)) {
                    Navigator.pop(context);
                    ToastTip.show(context, '你已经选过这个材料了，不能重复使用～');
                    return;
                  }
                  Navigator.pop(context);
                  widget.onMaterialSelected(index, name);
                },
                child: SizedBox(
                  width: 72,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(mat?.image ?? '', width: 32, height: 32),
                      const SizedBox(height: 4),
                      Text('$name × $count', textAlign: TextAlign.center, style: const TextStyle(fontSize: 8)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildMaterialIcon(int i) {
    final isValid = i < widget.selectedMaterials.length && widget.selectedMaterials[i].trim().isNotEmpty;
    final name = isValid ? widget.selectedMaterials[i] : null;
    final mat = name != null ? RefineMaterialService.getByName(name) : null;

    return Transform.rotate(
      angle: _isRefining ? _rotationAngle : 0,
      child: mat != null
          ? Image.asset(mat.image, width: 48, height: 48)
          : Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white24,
          border: Border.all(color: widget.isDisabled ? Colors.grey : Colors.white, width: 2),
        ),
        child: const Center(child: Text('＋', style: TextStyle(fontSize: 24, color: Colors.white))),
      ),
    );
  }

  String _formatCountdown(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: stackSize,
      height: stackSize,
      child: Stack(
        children: [
          Align(
            alignment: Alignment.center,
            child: GestureDetector(
              onTap: _onWeaponTapped,
              child: Image.asset(
                'assets/images/${widget.blueprint.iconPath}',
                width: weaponSize,
                height: weaponSize,
              ),
            ),
          ),
          if (widget.hasDisciple)
            ...List.generate(3, (i) => Positioned(
              left: _materialOffsets[i].dx,
              top: _materialOffsets[i].dy,
              child: GestureDetector(
                onTap: () => _selectMaterial(i),
                child: _buildMaterialIcon(i),
              ),
            )),
          if (_isRefining)
            Center(
              child: Text(
                _formatCountdown(_remainingSeconds),
                style: const TextStyle(fontSize: 32, color: Colors.yellow),
              ),
            ),
        ],
      ),
    );
  }
}
