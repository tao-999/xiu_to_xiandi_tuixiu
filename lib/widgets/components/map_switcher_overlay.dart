import 'dart:math';
import 'package:flutter/material.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/map_button_component.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/dialogs/map_switch_dialog.dart';
import 'package:xiu_to_xiandi_tuixiu/services/player_storage.dart';
import 'package:xiu_to_xiandi_tuixiu/services/cultivation_tracker.dart';

class MapSwitcherOverlay extends StatelessWidget {
  final int currentStage;
  final void Function(int newStage) onStageChanged;

  const MapSwitcherOverlay({
    super.key,
    required this.currentStage,
    required this.onStageChanged,
  });

  String _getStageName(int stage) {
    const names = ['一', '二', '三', '四', '五', '六', '七', '八', '九'];
    return stage >= 1 && stage <= 9 ? names[stage - 1] : '$stage';
  }

  void _handleMapSwitch(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => MapSwitchDialog(
        currentStage: currentStage,
        onSelected: (stage) async {
          await PlayerStorage.updateField('currentMapStage', stage);
          final efficiency = pow(2, stage - 1).toDouble();
          await PlayerStorage.updateField('cultivationEfficiency', efficiency);
          print("✅ 切换地图 $stage 阶, 挂机效率=$efficiency");

          // ✅ 重启修为增长 tick（使用最新玩家数据）
          CultivationTracker.stopTick();
          final player = await PlayerStorage.getPlayer();
          if (player != null) {
            CultivationTracker.startGlobalTick();
          }

          onStageChanged(stage);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 20,
      bottom: 120,
      child: MapButtonComponent(
        text: '${_getStageName(currentStage)}阶地图',
        onPressed: () => _handleMapSwitch(context),
      ),
    );
  }
}
