import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'page_character.dart';
import 'page_youli.dart';
import 'page_zongmen.dart';
import 'page_zhaomu.dart';
import 'page_create_role.dart';
import 'page_beibao.dart';

import 'package:xiu_to_xiandi_tuixiu/widgets/components/auto_battle_game.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/map_button_component.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/dialogs/map_switch_dialog.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/reset_player_button.dart';
import 'package:xiu_to_xiandi_tuixiu/models/character.dart';
import 'package:xiu_to_xiandi_tuixiu/services/cultivation_tracker.dart';
import 'package:xiu_to_xiandi_tuixiu/services/player_storage.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/gift_button_overlay.dart';

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

  final List<String> _labels = ['角色', '背包', '游历', '宗门', '招募'];
  final List<String> _iconPaths = [
    'assets/images/icon_dazuo_male.png',
    'assets/images/icon_beibao.png',
    'assets/images/icon_youli_male.png',
    'assets/images/icon_zongmen.png',
    'assets/images/icon_zhaomu.png',
  ];

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

      _iconPaths[0] = (newGender == 'female')
          ? 'assets/images/icon_dazuo_female.png'
          : 'assets/images/icon_dazuo_male.png';

      _iconPaths[2] = (newGender == 'female')
          ? 'assets/images/icon_youli_female.png'
          : 'assets/images/icon_youli_male.png';

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

    Widget page;
    switch (index) {
      case 0:
        page = const CharacterPage();
        break;
      case 1:
        page = const BeibaoPage();
        break;
      case 2:
        page = const YouliPage();
        break;
      case 3:
        page = const ZongmenPage();
        break;
      case 4:
        page = const ZhaomuPage();
        break;
      default:
        return;
    }

    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  void _showMapDialog() {
    if (player == null) return;

    showDialog(
      context: context,
      builder: (ctx) => MapSwitchDialog(
        currentStage: currentStage,
          onSelected: (stage) async {
            setState(() => currentStage = stage);

            // 切地图 & 改战斗速度
            game?.switchMap(stage);
            game?.updateBattleSpeed(stage);

            // 计算新的挂机效率
            final efficiency = pow(2, stage - 1).toDouble();

            // ✅ 只更新 playerData 中的字段，避免全量覆盖
            await PlayerStorage.updateField('currentMapStage', stage);
            await PlayerStorage.updateField('cultivationEfficiency', efficiency);
            print("✅ 写入切换地图的效率 stage=$stage / efficiency=$efficiency");

            // ✅ 重启修炼逻辑，内部会读取最新 playerData
            CultivationTracker.stopTick();
            CultivationTracker.startTickWithPlayer(onUpdate: () {
              if (mounted) setState(() {});
            });
          }
      ),
    );
  }

  String _getStageName(int stage) {
    const names = ['一', '二', '三', '四', '五', '六', '七', '八', '九'];
    return stage >= 1 && stage <= 9 ? names[stage - 1] : '$stage';
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
          Positioned(
            left: 20,
            bottom: 120,
            child: MapButtonComponent(
              text: '${_getStageName(currentStage)}阶地图',
              onPressed: _showMapDialog,
            ),
          ),
          Positioned(
            bottom: 8,
            left: 0,
            right: 0,
            child: SafeArea(
              top: false,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(_labels.length, (index) {
                  return GestureDetector(
                    onTap: () => _navigateToPage(index),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Image.asset(_iconPaths[index], fit: BoxFit.cover),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _labels[index],
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),
          ),
          // ✅ 新增：大礼包按钮
          if (!hasClaimedGift)
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
