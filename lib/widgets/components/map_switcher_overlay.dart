import 'dart:math';
import 'package:flutter/material.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/map_button_component.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/dialogs/map_switch_dialog.dart';
import 'package:xiu_to_xiandi_tuixiu/services/player_storage.dart';

import '../constants/aptitude_table.dart';

class MapSwitcherOverlay extends StatelessWidget {
  final int currentStage;
  final void Function(int newStage) onStageChanged;

  const MapSwitcherOverlay({
    super.key,
    required this.currentStage,
    required this.onStageChanged,
  });

  /// 动态读取独立文件中的 aptitudeTable，获取境界名称
  String _getStageName(int stage) {
    final realmNames = aptitudeTable.map((e) => e.realmName).toList();
    return (stage >= 1 && stage <= realmNames.length)
        ? realmNames[stage - 1]
        : '$stage';
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
        text: '${_getStageName(currentStage)}地图',
        onPressed: () => _handleMapSwitch(context),
      ),
    );
  }
}
