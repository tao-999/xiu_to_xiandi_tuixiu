import 'dart:async';
import 'package:flutter/material.dart';
import 'package:xiu_to_xiandi_tuixiu/models/character.dart';
import 'package:xiu_to_xiandi_tuixiu/services/player_storage.dart';
import 'package:xiu_to_xiandi_tuixiu/services/resources_storage.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/common/toast_tip.dart';

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
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 0, vertical: 0),
        child: Icon(
          Icons.add_circle_outline, // ✅ 图标替代文字
          size: 12,
          color: Colors.black,
        ),
      ),
    );
  }

  @override
  State<AptitudeUpgradeDialog> createState() => _AptitudeUpgradeDialogState();
}

class _AptitudeUpgradeDialogState extends State<AptitudeUpgradeDialog> {
  late int currentAptitude;
  int tempUsed = 0;
  int fateCharmCount = 0;
  Timer? _addTimer;
  Timer? _subTimer;

  @override
  void initState() {
    super.initState();
    currentAptitude = widget.player.aptitude;
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

    return AlertDialog(
      backgroundColor: const Color(0xFFF9F5E3),
      insetPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '✨ 当前资质：${currentAptitude + tempUsed}',
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(
            '使用资质券：$tempUsed / $fateCharmCount',
            style: const TextStyle(color: Colors.orange, fontSize: 14),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: _subAptitude,
                onTapDown: (_) => _startSubTimer(),
                onTapUp: (_) => _stopSubTimer(),
                onTapCancel: _stopSubTimer,
                child: const Text(
                  '-',
                  style: TextStyle(
                    fontSize: 24,
                    fontFamily: 'ZcoolCangEr',
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  '$tempUsed',
                  style: const TextStyle(fontSize: 18),
                ),
              ),
              GestureDetector(
                onTap: _addAptitude,
                onTapDown: (_) => _startAddTimer(),
                onTapUp: (_) => _stopAddTimer(),
                onTapCancel: _stopAddTimer,
                child: const Text(
                  '+',
                  style: TextStyle(
                    fontSize: 24,
                    fontFamily: 'ZcoolCangEr',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Center(
            child: InkWell(
              onTap: tempUsed == 0
                  ? null
                  : () async {
                final addedAptitude = tempUsed;
                await ResourcesStorage.subtract('fateRecruitCharm', BigInt.from(tempUsed));

                // ✅ 保存 aptitude
                widget.player.aptitude += addedAptitude;

                // ✅ 增加对应的 extra
                final double gain = addedAptitude * 0.01;
                widget.player.extraHp += gain;
                widget.player.extraAtk += gain;
                widget.player.extraDef += gain;

                await PlayerStorage.updateFields({
                  'aptitude': widget.player.aptitude,
                  'extraHp': widget.player.extraHp,
                  'extraAtk': widget.player.extraAtk,
                  'extraDef': widget.player.extraDef,
                });

                if (context.mounted) Navigator.of(context).pop();
                widget.onUpdated?.call();
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Text(
                  '☯️ 提升资质',
                  style: TextStyle(
                    fontSize: 14,
                    fontFamily: 'ZcoolCangEr',
                    color: tempUsed == 0 ? Colors.black38 : Colors.orange,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _addAptitude() {
    final remaining = fateCharmCount - tempUsed;
    if (remaining <= 0) {
      ToastTip.show(context, '资质券不够啦！');
      return;
    }
    setState(() {
      tempUsed++;
    });
  }

  void _subAptitude() {
    if (tempUsed <= 0) return;
    setState(() {
      tempUsed--;
    });
  }

  void _startAddTimer() {
    _addTimer?.cancel();
    _addTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (!mounted) return;
      _addAptitude();
    });
  }

  void _stopAddTimer() {
    _addTimer?.cancel();
    _addTimer = null;
  }

  void _startSubTimer() {
    _subTimer?.cancel();
    _subTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (!mounted) return;
      _subAptitude();
    });
  }

  void _stopSubTimer() {
    _subTimer?.cancel();
    _subTimer = null;
  }
}
