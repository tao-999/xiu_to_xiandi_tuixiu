import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/back_button_overlay.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/xianling_chess_game.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/stone_counter.dart';
import 'package:xiu_to_xiandi_tuixiu/services/player_storage.dart';
import 'package:xiu_to_xiandi_tuixiu/services/xianling_chess_storage.dart';
import 'package:xiu_to_xiandi_tuixiu/utils/cultivation_level.dart';

class XianlingQizhenPage extends StatefulWidget {
  const XianlingQizhenPage({super.key});

  @override
  State<XianlingQizhenPage> createState() => _XianlingQizhenPageState();
}

class _XianlingQizhenPageState extends State<XianlingQizhenPage> {
  int? playerStone;

  @override
  void initState() {
    super.initState();
    _loadPlayerStone();
  }

  Future<void> _loadPlayerStone() async {
    final stored = await XianlingChessStorage.getPlayerStone();
    if (stored == null) {
      await Future.delayed(Duration.zero);
      _showStoneSelectDialog();
    } else {
      setState(() {
        playerStone = stored;
      });
    }
  }

  void _showStoneSelectDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      builder: (_) => Dialog(
        backgroundColor: const Color(0xFFF9F5E3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '选择你的棋子颜色',
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 8),
              const Text(
                '此选择将永久保存，无法更改。\n你将永远是先手执棋。',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  GestureDetector(
                    onTap: () => _selectStone(1), // 黑子
                    child: Column(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              center: Alignment.topLeft,
                              radius: 0.8,
                              colors: [Colors.black87, Colors.black],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black38,
                                blurRadius: 6,
                                offset: Offset(2, 2),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '执黑',
                          style: TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _selectStone(2), // 白子
                    child: Column(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              center: Alignment.topLeft,
                              radius: 0.8,
                              colors: [Colors.white, Colors.grey],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 6,
                                offset: Offset(2, 2),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '执白',
                          style: TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectStone(int stone) async {
    await XianlingChessStorage.savePlayerStone(stone);
    setState(() {
      playerStone = stone;
    });
    Navigator.of(context).pop();
  }

  Future<(String, String, int)> _getRealmAndTitleAndLevel() async {
    final player = await PlayerStorage.getPlayer();
    if (player == null) return ('未知境界', '？？？', 0);
    final level = calculateCultivationLevel(player.cultivation);
    final realm = level.realm;
    final title = _getTitleByRealm(realm);
    final aiLevel = _getAILevelByRealm(realm);
    return (realm, title, aiLevel);
  }

  String _getTitleByRealm(String realm) {
    const map = {
      '练气期': '棋童',
      '筑基期': '棋徒',
      '金丹期': '棋士',
      '元婴期': '棋客',
      '化神期': '棋修',
      '炼虚期': '棋灵',
      '合体期': '棋狂',
      '大乘期': '棋尊',
      '渡劫期': '棋圣',
    };
    return map[realm] ?? '？？？';
  }

  int _getAILevelByRealm(String realm) {
    if (realm == '练气期' || realm == '筑基期') return 0;
    if (realm == '金丹期' || realm == '元婴期') return 1;
    if (realm == '化神期' || realm == '炼虚期' || realm == '合体期') return 2;
    if (realm == '大乘期' || realm == '渡劫期') return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    if (playerStone == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final boardSize = 12;
    final cellSize = screenWidth * 0.95 / boardSize;
    final boardPx = cellSize * boardSize;

    return FutureBuilder<(String, String, int)>(
      future: _getRealmAndTitleAndLevel(),
      builder: (context, snapshot) {
        final (realm, title, aiLevel) = snapshot.data ?? ('未知境界', '？？？', 0);
        final isPlayerBlack = playerStone == 1;

        return Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                'assets/images/bg_xianlingqizhen.webp',
                fit: BoxFit.cover,
              ),
            ),
            Align(
              alignment: Alignment.center,
              child: SizedBox(
                width: boardPx,
                height: boardPx,
                child: GameWidget(
                  game: XianlingChessGame(
                    context,
                    boardSize: boardSize,
                    cellSize: cellSize,
                    aiLevel: aiLevel,
                    playerStone: playerStone!, // ✅ 玩家执子颜色
                  ),
                ),
              ),
            ),
            // 顶部左侧：AI 信息
            Positioned(
              top: 16,
              left: 16,
              child: ValueListenableBuilder<Map<String, int>>(
                valueListenable: XianlingChessGame.stoneCounter,
                builder: (context, value, _) {
                  return StoneCounter(
                    playerName: title,
                    realm: realm,
                    label: isPlayerBlack ? '白子' : '黑子',
                    color: isPlayerBlack ? Colors.white : Colors.black,
                    count: isPlayerBlack ? value['white']! : value['black']!,
                  );
                },
              ),
            ),
            // 底部右侧：玩家信息
            Positioned(
              bottom: 16,
              right: 16,
              child: ValueListenableBuilder<Map<String, int>>(
                valueListenable: XianlingChessGame.stoneCounter,
                builder: (context, value, _) {
                  return FutureBuilder(
                    future: PlayerStorage.getPlayer(),
                    builder: (context, snapshot) {
                      final playerName = snapshot.data?.name ?? '你';
                      return StoneCounter(
                        playerName: playerName,
                        realm: realm,
                        label: isPlayerBlack ? '黑子' : '白子',
                        color: isPlayerBlack ? Colors.black : Colors.white,
                        count: isPlayerBlack ? value['black']! : value['white']!,
                      );
                    },
                  );
                },
              ),
            ),
            const BackButtonOverlay(),
          ],
        );
      },
    );
  }
}
