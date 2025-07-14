import 'dart:async';
import 'package:flutter/material.dart';
import 'package:xiu_to_xiandi_tuixiu/models/character.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/back_button_overlay.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/cultivator_info_card.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/resource_bar.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/cultivation_status_panel.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/dialogs/cultivation_boost_dialog.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/dialogs/aptitude_upgrade_dialog.dart';
import 'package:xiu_to_xiandi_tuixiu/utils/cultivation_level.dart';
import 'package:xiu_to_xiandi_tuixiu/services/player_storage.dart';

import '../widgets/components/pill_consumer.dart';

class CharacterPage extends StatefulWidget {
  const CharacterPage({super.key});

  @override
  State<CharacterPage> createState() => _CharacterPageState();
}

class _CharacterPageState extends State<CharacterPage> {
  late Character player;
  late CultivationLevelDisplay display;
  bool showAura = false;

  Timer? _refreshTimer;

  /// 🌟 GlobalKey 用于控制 ResourceBar 刷新
  final GlobalKey<ResourceBarState> _resourceBarKey = GlobalKey<ResourceBarState>();

  @override
  void initState() {
    super.initState();
    _startRefreshLoop();
  }

  void _startRefreshLoop() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 1), (_) => _reloadData());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _reloadData() async {
    final updated = await PlayerStorage.getPlayer();
    if (mounted && updated != null) {
      setState(() {
        player = updated;
      });
      // 🌟刷新资源条
      _resourceBarKey.currentState?.refresh();
    }
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
          return const Scaffold(
            backgroundColor: Colors.black,
            body: Center(child: CircularProgressIndicator(color: Colors.amber)),
          );
        }

        player = snapshot.data![0] as Character;
        display = snapshot.data![1] as CultivationLevelDisplay;

        return Scaffold(
          body: Stack(
            children: [
              // 🌄 背景图
              Positioned.fill(
                child: Image.asset(
                  'assets/images/bg_xiuxian_mountain.webp',
                  fit: BoxFit.cover,
                ),
              ),

              // 💠 顶部资源栏 (去掉const，挂上key)
              ResourceBar(key: _resourceBarKey),

              // 🧘‍♂️ 打坐动画 + 修为进度
              Align(
                alignment: const Alignment(0, 0.4),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CultivationStatusPanel(
                      player: player,
                      display: display,
                      showAura: showAura,
                      onAuraComplete: () => setState(() => showAura = false),
                    ),
                    CultivatorInfoCard(profile: player),
                  ],
                ),
              ),

              // 🔙 返回
              const BackButtonOverlay(),

              // 📍右上角按钮：升修为 + 升资质
              Positioned(
                top: 100,
                right: 30,
                child: Column(
                  children: [
                    CultivationBoostDialog.buildButton(
                      context: context,
                      onUpdated: _reloadData,
                    ),
                    const SizedBox(height: 12),
                    AptitudeUpgradeDialog.buildButton(
                      context: context,
                      player: player,
                      onUpdated: _reloadData,
                    ),
                  ],
                ),
              ),

              // 🥄 左上角按钮：吞丹入口
              Positioned(
                top: 100,
                left: 30,
                child: PillConsumer(
                  onConsumed: _reloadData,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
