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

import 'package:xiu_to_xiandi_tuixiu/widgets/components/auto_battle_game.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/map_button_component.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/dialogs/map_switch_dialog.dart';

import 'package:xiu_to_xiandi_tuixiu/models/character.dart';
import 'package:xiu_to_xiandi_tuixiu/services/cultivation_tracker.dart';
import 'package:xiu_to_xiandi_tuixiu/services/player_storage.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/dialogs/gift_popup.dart';

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

  final List<String> _labels = ['角色', '游历', '宗门', '招募'];
  final List<String> _iconPaths = [
    'assets/images/icon_dazuo_male.png',
    'assets/images/icon_youli.png',
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
        page = const YouliPage();
        break;
      case 2:
        page = const ZongmenPage();
        break;
      case 3:
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
          Positioned(
            top: 30,
            right: 20,
            child: GestureDetector(
              onTap: () {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) => GiftPopup(
                      onClaimed: () async {
                        final player = await PlayerStorage.getPlayer();
                        if (player == null) return;

                        // ✅ 修改资源
                        player.resources.add('spiritStoneLow', 10000);
                        player.resources.add('humanRecruitTicket', 100);

                        // ✅ 存回去
                        await PlayerStorage.savePlayer(player);

                        if (mounted) {
                          setState(() {
                            hasClaimedGift = true;
                          });
                        }
                      }
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                ),
                child: const Row(
                  children: [
                    Icon(Icons.card_giftcard, color: Colors.white, size: 20),
                    SizedBox(width: 6),
                    Text('修仙大礼包', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 120),
        child: FloatingActionButton(
          backgroundColor: Colors.redAccent,
          tooltip: '清空角色数据',
          child: const Icon(Icons.delete_forever),
          onPressed: () async {
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('确定要重置角色吗？'),
                content: const Text('该操作将清空所有修为、信息和存档，无法恢复！'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('取消'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('确定'),
                  ),
                ],
              ),
            );

            if (confirmed == true) {
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              player = null;
              CultivationTracker.stopTick();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const CreateRolePage()),
                    (route) => false,
              );
            }
          },
        ),
      ),
    );
  }
}
