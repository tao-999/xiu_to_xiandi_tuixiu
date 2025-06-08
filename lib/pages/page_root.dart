import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'page_character.dart';
import 'page_youli.dart';
import 'page_zongmen.dart';
import 'page_zhaomu.dart';
import 'page_beibao.dart';

import 'package:xiu_to_xiandi_tuixiu/widgets/components/auto_battle_game.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/reset_player_button.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/gift_button_overlay.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/xiuxian_era_label.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/root_bottom_menu.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/map_switcher_overlay.dart';

import 'package:xiu_to_xiandi_tuixiu/models/character.dart';
import 'package:xiu_to_xiandi_tuixiu/services/cultivation_tracker.dart';

class XiudiRoot extends StatefulWidget {
  const XiudiRoot({super.key});

  @override
  State<XiudiRoot> createState() => _XiudiRootState();
}

class _XiudiRootState extends State<XiudiRoot> {
  Character? player;
  String gender = 'male';
  int currentStage = 1;
  AutoBattleGame? game;
  bool hasClaimedGift = false;

  @override
  void initState() {
    super.initState();
    _recordLoginTime();
    _loadPlayerData();
    _checkGiftClaimed();
  }

  Future<void> _recordLoginTime() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now().millisecondsSinceEpoch;
    await prefs.setInt('lastOnlineTimestamp', now);
  }

  Future<void> _loadPlayerData() async {
    final prefs = await SharedPreferences.getInstance();
    final playerStr = prefs.getString('playerData');
    if (playerStr == null) return;

    final data = jsonDecode(playerStr);
    final loadedPlayer = Character.fromJson(data);

    final savedStage = prefs.getInt('currentMapStage') ?? 1;
    final newGender = loadedPlayer.gender;

    setState(() {
      player = loadedPlayer;
      gender = newGender;
      currentStage = savedStage;

      game = AutoBattleGame(
        playerEmojiOrIconPath: newGender == 'female'
            ? 'icon_dazuo_female_256.png'
            : 'icon_dazuo_male_256.png',
        isAssetImage: true,
        currentMapStage: savedStage,
      );
    });

    CultivationTracker.startTickWithPlayer(onUpdate: () {
      setState(() {});
    });
  }

  void _navigateToPage(int index) {
    if (player == null) return;

    final pages = [
      const CharacterPage(),
      const BeibaoPage(),
      const YouliPage(),
      const ZongmenPage(),
      const ZhaomuPage(),
    ];

    if (index >= 0 && index < pages.length) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => pages[index]));
    }
  }

  Future<void> _checkGiftClaimed() async {
    final prefs = await SharedPreferences.getInstance();
    final claimed = prefs.getBool('hasClaimedGift') ?? false;
    setState(() {
      hasClaimedGift = claimed;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (player == null || game == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(child: GameWidget(game: game!)),

          // 🏷️ 纪元显示
          const Positioned(
            left: 20,
            top: 36,
            child: XiuxianEraLabel(),
          ),

          // ⛩️ 地图按钮（含弹窗）
          MapSwitcherOverlay(
            currentStage: currentStage,
            onStageChanged: (newStage) {
              setState(() => currentStage = newStage);
              game?.switchMap(newStage);
              game?.updateBattleSpeed(newStage);
            },
          ),

          // 📦 底部功能菜单
          Positioned(
            bottom: 8,
            left: 0,
            right: 0,
            child: RootBottomMenu(
              gender: gender,
              onTap: _navigateToPage,
            ),
          ),

          // 🎁 修仙大礼包按钮
          GiftButtonOverlay(
            onGiftClaimed: () {
              setState(() {
                hasClaimedGift = true;
              });
            },
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: const ResetPlayerButton(),
    );
  }
}
