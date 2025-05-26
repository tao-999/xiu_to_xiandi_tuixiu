import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flame/game.dart'; // ✅ 必须有这个！
import 'package:shared_preferences/shared_preferences.dart';

import 'page_character.dart';
import 'page_youli.dart';
import 'page_zongmen.dart';
import 'page_zhaomu.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/auto_battle_game.dart';

class XiudiRoot extends StatefulWidget {
  const XiudiRoot({super.key});

  @override
  State<XiudiRoot> createState() => _XiudiRootState();
}

class _XiudiRootState extends State<XiudiRoot> {
  String gender = 'male'; // 默认值，后续从 SharedPreferences 加载

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
    _loadGender(); // 初始化时加载性别
  }

  Future<void> _loadGender() async {
    final prefs = await SharedPreferences.getInstance();
    final playerStr = prefs.getString('playerData');
    if (playerStr == null) return;

    final player = jsonDecode(playerStr);
    final g = player['gender'];
    debugPrint('🐉 获取到角色性别：$g');

    setState(() {
      gender = g;
      _iconPaths[0] = (gender == 'female')
          ? 'assets/images/icon_dazuo_female.png'
          : 'assets/images/icon_dazuo_male.png';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Flame 战斗背景层
          Positioned.fill(
            child: GameWidget(game: AutoBattleGame()),
          ),

          // 背景栏（贴到底部，承托 icon）
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

          // 图标 + 文字（完全独立悬浮）
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
    );
  }
}
