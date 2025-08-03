import 'package:flutter/material.dart';
import 'package:xiu_to_xiandi_tuixiu/models/character.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/cultivation_status_panel.dart';
import 'package:xiu_to_xiandi_tuixiu/utils/cultivation_level.dart';
import 'package:xiu_to_xiandi_tuixiu/services/player_storage.dart';

class CharacterPanel extends StatefulWidget {
  final VoidCallback? onChanged; // 通用回调

  const CharacterPanel({super.key, this.onChanged});

  @override
  State<CharacterPanel> createState() => _CharacterPanelState();
}

class _CharacterPanelState extends State<CharacterPanel> {
  Future<void> _reloadData() async {
    setState(() {});
    widget.onChanged?.call(); // 每次刷新都同步父组件
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: Future.wait([
        PlayerStorage.getPlayer(),
        getDisplayLevelFromPrefs(),
      ]),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.amber),
          );
        }

        final player = snapshot.data![0] as Character;
        final display = snapshot.data![1] as CultivationLevelDisplay;

        return SizedBox(
          width: 150,
          height: 250,
          child: CultivationStatusPanel(
            player: player,
            display: display,
            showAura: false,
            onAuraComplete: () {},
            onChanged: _reloadData,
          ),
        );
      },
    );
  }
}
