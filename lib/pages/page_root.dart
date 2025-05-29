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

class XiudiRoot extends StatefulWidget {
  const XiudiRoot({super.key});

  @override
  State<XiudiRoot> createState() => _XiudiRootState();
}

class _XiudiRootState extends State<XiudiRoot> {
  String gender = 'male';
  int currentStage = 1;
  late AutoBattleGame game;
  late Character player;

  final List<String> _labels = ['角色', '游历', '宗门', '招募'];

  List<String> _iconPaths = [
    'assets/images/icon_dazuo_male.png',
    'assets/images/icon_youli.png',
    'assets/images/icon_zongmen.png',
    'assets/images/icon_zhaomu.png',
  ];

  @override
  void initState() {
    super.initState();
    game = AutoBattleGame(
      playerEmojiOrIconPath: 'icon_dazuo_male_256.png',
      isAssetImage: true,
      currentMapStage: 1,
    );
    _loadPlayerData();
    _recordLoginTime();
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
    player = Character.fromJson(data);

    setState(() {
      gender = player.gender;
      currentStage = player.cultivationEfficiency.toInt();
      _iconPaths[0] = (gender == 'female')
          ? 'assets/images/icon_dazuo_female.png'
          : 'assets/images/icon_dazuo_male.png';

      game = AutoBattleGame(
        playerEmojiOrIconPath: gender == 'female'
            ? 'icon_dazuo_female_256.png'
            : 'icon_dazuo_male_256.png',
        isAssetImage: true,
        currentMapStage: currentStage,
      );

      CultivationTracker.startTickWithPlayer(player, onUpdate: () {
        setState(() {});
      });
    });
  }

  void _navigateToPage(int index) {
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

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => page),
    );
  }

  void _showMapDialog() {
    showDialog(
      context: context,
      builder: (ctx) => MapSwitchDialog(
        currentStage: currentStage,
        onSelected: (stage) async {
          setState(() => currentStage = stage);
          game.switchMap(stage);
          game.updateBattleSpeed(stage);

          player.cultivationEfficiency = pow(2, stage - 1).toDouble();
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('playerData', jsonEncode(player.toJson()));

          CultivationTracker.stopTick();
          CultivationTracker.startTickWithPlayer(player, onUpdate: () {
            setState(() {});
          });

          await CultivationTracker.savePlayerCultivation(player.cultivation);
        },
      ),
    );
  }

  String _getStageName(int stage) {
    const names = ['一', '二', '三', '四', '五', '六', '七', '八', '九'];
    return stage >= 1 && stage <= 9 ? names[stage - 1] : '$stage';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: game == null ? const SizedBox() : GameWidget(game: game),
          ),
          Positioned(
            left: 20,
            bottom: 120,
            child: MapButtonComponent(
              text: '${_getStageName(currentStage)}阶地图',
              onPressed: _showMapDialog,
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 60,
            child: Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/menu_background_final.webp'),
                  fit: BoxFit.cover,
                  alignment: Alignment.bottomCenter,
                ),
              ),
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
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Image.asset(
                            _iconPaths[index],
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _labels[index],
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF333333),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
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
              player = Character.empty();
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
