import 'dart:math';
import 'package:flutter/material.dart';
import 'package:xiu_to_xiandi_tuixiu/utils/cultivation_level.dart';
import 'package:xiu_to_xiandi_tuixiu/services/player_storage.dart';

class MapSwitchDialog extends StatefulWidget {
  final int currentStage;
  final void Function(int stage) onSelected;

  const MapSwitchDialog({
    super.key,
    required this.currentStage,
    required this.onSelected,
  });

  @override
  State<MapSwitchDialog> createState() => _MapSwitchDialogState();
}

class _MapSwitchDialogState extends State<MapSwitchDialog> {
  int maxStage = 1;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadMaxStage();
  }

  Future<void> _loadMaxStage() async {
    final player = await PlayerStorage.getPlayer();
    if (player == null) return;

    final exp = player.cultivation;
    final level = calculateCultivationLevel(exp);

    final unlockedStage = ((level.totalLayer - 1) ~/ CultivationConfig.levelsPerRealm + 1)
        .clamp(1, CultivationConfig.realms.length);

    print('📍 当前层数: ${level.totalLayer}（${level.realm} 第${level.rank}重） → 解锁到第 $unlockedStage 阶地图');

    setState(() {
      maxStage = unlockedStage;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToSelectedStageSilently();
    });
  }

  void _scrollToSelectedStageSilently() {
    final itemHeight = 56.0;
    final viewHeight = 400.0;
    final offsetCorrection = viewHeight / 2 - itemHeight / 2;

    final rawOffset = (widget.currentStage - 1) * itemHeight;
    final targetOffset = max(rawOffset - offsetCorrection, 0);

    if (_scrollController.hasClients) {
      _scrollController.jumpTo(targetOffset.toDouble());
    } else {
      Future.delayed(const Duration(milliseconds: 50), () {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(targetOffset.toDouble());
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final realmNames = CultivationConfig.realms;
    final itemCount = realmNames.length;

    return AlertDialog(
      backgroundColor: const Color(0xFFF9F5E3),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      title: const Text(
        "修仙地图",
        style: TextStyle(fontSize: 16),
      ),
      content: SizedBox(
        width: 300,
        height: 400,
        child: ListView.builder(
          controller: _scrollController,
          itemCount: itemCount,
          itemBuilder: (context, index) {
            final stage = index + 1;
            final isSelected = stage == widget.currentStage;
            final isDisabled = stage > maxStage;
            final name = realmNames[index];

            return GestureDetector(
              onTap: isDisabled
                  ? null
                  : () {
                Navigator.of(context).pop();
                widget.onSelected(stage);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '$name地图',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDisabled ? Colors.grey : Colors.black,
                        ),
                      ),
                    ),
                    if (isSelected)
                      const Icon(Icons.check, color: Colors.green),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
