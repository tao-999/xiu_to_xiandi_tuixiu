import 'dart:async';
import 'package:flutter/material.dart';
import 'package:xiu_to_xiandi_tuixiu/models/character.dart';
import 'package:xiu_to_xiandi_tuixiu/services/player_storage.dart';
import 'package:xiu_to_xiandi_tuixiu/services/resources_storage.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/common/toast_tip.dart';
import '../constants/aptitude_table.dart';

class AptitudeUpgradeDialog extends StatefulWidget {
  final Character player;
  final VoidCallback? onUpdated;

  const AptitudeUpgradeDialog({
    super.key,
    required this.player,
    this.onUpdated,
  });

  static Widget buildButton({
    required BuildContext context,
    required Character player,
    VoidCallback? onUpdated,
  }) {
    return InkWell(
      onTap: () async {
        await showDialog(
          context: context,
          builder: (_) => AptitudeUpgradeDialog(
            player: player,
            onUpdated: onUpdated,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Text(
          "升资质",
          style: const TextStyle(
            fontSize: 15,
            fontFamily: 'ZcoolCangEr',
            color: Colors.black,
          ),
        ),
      ),
    );
  }

  @override
  State<AptitudeUpgradeDialog> createState() => _AptitudeUpgradeDialogState();
}

class _AptitudeUpgradeDialogState extends State<AptitudeUpgradeDialog> {
  late Map<String, int> tempElements;
  int tempUsed = 0;
  int fateCharmCount = 0; // ✅ 独立存储的资质券数量
  Timer? _addTimer;
  Timer? _subTimer;

  final Map<String, String> elementLabels = {
    'gold': '金',
    'wood': '木',
    'water': '水',
    'fire': '火',
    'earth': '土',
  };

  int getMaxAptitudeLimit() => aptitudeTable.last.minAptitude;

  @override
  void initState() {
    super.initState();
    tempElements = Map<String, int>.from(widget.player.elements);
    _loadFateCharmCount();
  }

  Future<void> _loadFateCharmCount() async {
    final val = await ResourcesStorage.getValue('fateRecruitCharm');
    if (mounted) {
      setState(() {
        fateCharmCount = val.toInt();
      });
    }
  }

  @override
  void dispose() {
    _addTimer?.cancel();
    _subTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final remaining = fateCharmCount - tempUsed;
    final totalAptitude = tempElements.values.fold<int>(0, (sum, v) => sum + v);
    final maxAptitudeLimit = getMaxAptitudeLimit();

    return AlertDialog(
      backgroundColor: const Color(0xFFF9F5E3),
      insetPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('✨ 资质：$totalAptitude / $maxAptitudeLimit', style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 4),
          Text('资质券：$remaining', style: const TextStyle(color: Colors.orange, fontSize: 14)),
          const SizedBox(height: 12),
          ...tempElements.keys.map(_buildAptitudeRow).toList(),
          const SizedBox(height: 12),
          Center(
            child: GestureDetector(
              onTap: tempUsed == 0
                  ? null
                  : () async {
                await ResourcesStorage.subtract('fateRecruitCharm', BigInt.from(tempUsed));
                widget.player.elements = tempElements;
                PlayerStorage.calculateBaseAttributes(widget.player);

                await PlayerStorage.updateFields({
                  'elements': widget.player.elements,
                  'baseHp': widget.player.baseHp,
                  'baseAtk': widget.player.baseAtk,
                  'baseDef': widget.player.baseDef,
                });

                if (context.mounted) Navigator.of(context).pop();
                widget.onUpdated?.call();
              },
              child: InkWell(
                onTap: tempUsed == 0 ? null : () {
                  // 执行确认提升逻辑
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Text(
                    '☯️ 确认提升',
                    style: TextStyle(
                      fontSize: 14,
                      fontFamily: 'ZcoolCangEr',
                      color: tempUsed == 0 ? Colors.black38 : Colors.orange,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAptitudeRow(String key) {
    final label = elementLabels[key] ?? key;
    final baseValue = widget.player.elements[key] ?? 0;
    final currentValue = tempElements[key] ?? 0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('$label：', style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 4),
          Text('$currentValue', style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 48),
          Visibility(
            visible: currentValue > baseValue,
            maintainSize: true,
            maintainAnimation: true,
            maintainState: true,
            child: GestureDetector(
              onTap: () => _subAptitude(key, baseValue),
              onTapDown: (_) => _startSubTimer(key, baseValue),
              onTapUp: (_) => _stopSubTimer(),
              onTapCancel: () => _stopSubTimer(),
              child: const Icon(Icons.remove_circle, size: 20, color: Colors.red),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => _addAptitude(key),
            onTapDown: (_) => _startAddTimer(key),
            onTapUp: (_) => _stopAddTimer(),
            onTapCancel: () => _stopAddTimer(),
            child: const Icon(Icons.add_circle, size: 20, color: Colors.green),
          ),
        ],
      ),
    );

  }

  void _addAptitude(String key) {
    final remaining = fateCharmCount - tempUsed;
    final totalAptitude = tempElements.values.fold<int>(0, (sum, v) => sum + v);
    final maxLimit = getMaxAptitudeLimit();

    if (remaining <= 0) {
      ToastTip.show(context, '资质券不够啦！');
      return;
    }

    if (totalAptitude >= maxLimit) {
      ToastTip.show(context, '⚠️ 已达到资质上限，无法继续提升！');
      return;
    }

    setState(() {
      tempElements[key] = (tempElements[key] ?? 0) + 1;
      tempUsed++;
    });
  }

  void _subAptitude(String key, int baseValue) {
    final current = tempElements[key] ?? 0;
    if (current <= baseValue) return;

    setState(() {
      tempElements[key] = current - 1;
      tempUsed--;
    });
  }

  void _startAddTimer(String key) {
    _addTimer?.cancel();
    _addTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (!mounted) return;
      _addAptitude(key);
    });
  }

  void _stopAddTimer() {
    _addTimer?.cancel();
    _addTimer = null;
  }

  void _startSubTimer(String key, int baseValue) {
    _subTimer?.cancel();
    _subTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (!mounted) return;
      _subAptitude(key, baseValue);
    });
  }

  void _stopSubTimer() {
    _subTimer?.cancel();
    _subTimer = null;
  }
}
