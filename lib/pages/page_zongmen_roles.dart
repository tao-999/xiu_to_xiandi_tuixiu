import 'package:flutter/material.dart';
import 'package:flame/game.dart';

import 'package:xiu_to_xiandi_tuixiu/widgets/components/zongmen_position_map_game.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/back_button_overlay.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/dialogs/appoint_disciple_role_dialog.dart';

class ZongmenRolesPage extends StatefulWidget {
  const ZongmenRolesPage({super.key});

  @override
  State<ZongmenRolesPage> createState() => _ZongmenRolesPageState();
}

class _ZongmenRolesPageState extends State<ZongmenRolesPage> {
  late final ZongmenPositionMapGame mapGame;

  @override
  void initState() {
    super.initState();
    mapGame = ZongmenPositionMapGame(
      onAppointRequested: (id, name, role, realm, onSelected) {
        showDialog(
          context: context,
          builder: (context) => AppointDiscipleRoleDialog(
            discipleName: name,
            currentRole: role,
            currentRealm: realm,
            onAppointed: (newRole) {
              onSelected(newRole);
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0D0C),
      body: Stack(
        children: [
          Positioned.fill(
            child: GameWidget(
              game: mapGame,
              overlayBuilderMap: {
                'position_map': (_, __) => const SizedBox(), // ✅ 占位 Overlay
              },
              initialActiveOverlays: const ['position_map'],
            ),
          ),
          const BackButtonOverlay(),
        ],
      ),
    );
  }
}
