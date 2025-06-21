import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/player_storage.dart';
import '../services/weapons_storage.dart';
import '../utils/route_observer.dart';
import 'page_character.dart';
import 'page_youli.dart';
import 'page_zongmen.dart';
import 'page_zhaomu.dart';
import 'page_beibao.dart';

import 'package:xiu_to_xiandi_tuixiu/widgets/components/auto_battle_game.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/gift_button_overlay.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/xiuxian_era_label.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/root_bottom_menu.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/map_switcher_overlay.dart';

import 'package:xiu_to_xiandi_tuixiu/models/character.dart';
import 'package:xiu_to_xiandi_tuixiu/utils/cultivation_level.dart'; // ✅ 引入修为逻辑

class XiudiRoot extends StatefulWidget {
  const XiudiRoot({super.key});

  @override
  State<XiudiRoot> createState() => _XiudiRootState();
}

class _XiudiRootState extends State<XiudiRoot> with RouteAware {
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)! as PageRoute);
  }

  @override
  void didPopNext() {
    debugPrint('📍 [RouteAware] 返回到 Root，刷新角色+装备');
    _loadPlayerData();
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  Future<void> _recordLoginTime() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now().millisecondsSinceEpoch;
    await prefs.setInt('lastOnlineTimestamp', now);
  }

  Future<void> _loadPlayerData() async {
    final loadedPlayer = await PlayerStorage.getPlayer();
    if (loadedPlayer == null) return;

    final newGender = loadedPlayer.gender;

    // ✅ 获取装备
    final equipped = await WeaponsStorage.loadWeaponsEquippedBy(loadedPlayer.id);
    final hasWeapon = equipped.any((w) => w.type == 'weapon');
    final hasArmor = equipped.any((w) => w.type == 'armor');

    // ✅ 贴图后缀拼接
    String suffix = '';
    if (hasWeapon && hasArmor) {
      suffix = '_weapon_armor';
    } else if (hasWeapon) {
      suffix = '_weapon';
    } else if (hasArmor) {
      suffix = '_armor';
    }

    final baseName = newGender == 'female' ? 'dazuo_female' : 'dazuo_male';
    final imagePath = 'assets/images/${baseName}${suffix}.png';

    // ✅ 更新角色数据
    setState(() {
      player = loadedPlayer;
      gender = newGender;
    });

    // ✅ 不动地图，只更新角色贴图
    game?.updatePlayerImage(imagePath);
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

  Future<String> getMeditationImagePath(Character player) async {
    final isFemale = player.gender == 'female';
    final baseName = isFemale ? 'dazuo_female' : 'dazuo_male';

    final equipped = await WeaponsStorage.loadWeaponsEquippedBy(player.id);
    final hasWeapon = equipped.any((w) => w.type == 'weapon');
    final hasArmor = equipped.any((w) => w.type == 'armor');

    String suffix = '';
    if (hasWeapon && hasArmor) {
      suffix = '_weapon_armor';
    } else if (hasWeapon) {
      suffix = '_weapon';
    } else if (hasArmor) {
      suffix = '_armor';
    }

    return 'assets/images/${baseName}${suffix}.png';
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
          Stack(
            children: [
              Positioned.fill(child: GameWidget(game: game!)),

              // ✅ 中间插入：打坐图贴图（装备动态变图）
              FutureBuilder<String>(
                future: getMeditationImagePath(player!),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const SizedBox();
                  return Align(
                    alignment: Alignment.center,
                    child: Image.asset(
                      snapshot.data!,
                      width: 160,
                      height: 160,
                    ),
                  );
                },
              ),
            ],
          ),

          // 🏷️ 修仙纪元
          const Positioned(
            left: 20,
            top: 36,
            child: XiuxianEraLabel(),
          ),

          // ⛩️ 地图切换按钮（含弹窗）
          MapSwitcherOverlay(
            currentStage: currentStage,
            onStageChanged: (newStage) async {
              final latestPlayer = await PlayerStorage.getPlayer();
              if (latestPlayer == null) return;

              final levelInfo = calculateCultivationLevel(latestPlayer.cultivation);
              final totalLayer = levelInfo.totalLayer;
              final requiredMinLayer = (newStage - 1) * CultivationConfig.levelsPerRealm + 1;

              if (totalLayer < requiredMinLayer) {
                return; // 🚫 地图未解锁，退出
              }

              setState(() {
                player = latestPlayer;
                currentStage = newStage;
              });

              game?.switchMap(newStage);
              game?.updateBattleSpeed(newStage);
            },
          ),

          // 📦 底部菜单
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
    );
  }
}
