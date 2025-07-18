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
  /// GlobalKey 用于刷新资源条
  final GlobalKey<ResourceBarState> _resourceBarKey = GlobalKey<ResourceBarState>();

  /// 手动触发刷新用
  Future<void> _reloadData() async {
    setState(() {}); // ✅ 重新触发 FutureBuilder
    _resourceBarKey.currentState?.refresh();
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

        final player = snapshot.data![0] as Character;
        final display = snapshot.data![1] as CultivationLevelDisplay;

        return Scaffold(
          body: Stack(
            children: [
              Positioned.fill(
                child: Image.asset(
                  'assets/images/bg_xiuxian_mountain.webp',
                  fit: BoxFit.cover,
                ),
              ),

              /// 顶部资源条
              ResourceBar(key: _resourceBarKey),

              /// 中央修为进度 + 角色信息
              Align(
                alignment: const Alignment(0, 0.4),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CultivationStatusPanel(
                      player: player,
                      display: display,
                      showAura: false,
                      onAuraComplete: () {},
                      onChanged: _reloadData, // ✅ 核心绑定：装备改变时刷新
                    ),
                    CultivatorInfoCard(profile: player),
                  ],
                ),
              ),

              /// 返回按钮
              const BackButtonOverlay(),

              /// 右上角：升修为、升资质
              Positioned(
                top: 100,
                right: 30,
                child: Column(
                  children: [
                    if (display.max != BigInt.zero)
                      CultivationBoostDialog.buildButton(
                        context: context,
                        onUpdated: _reloadData,
                      ),
                    if (display.max != BigInt.zero)
                      const SizedBox(height: 12),
                    AptitudeUpgradeDialog.buildButton(
                      context: context,
                      player: player,
                      onUpdated: _reloadData,
                    ),
                  ],
                ),
              ),

              /// 左上角：吞丹
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
