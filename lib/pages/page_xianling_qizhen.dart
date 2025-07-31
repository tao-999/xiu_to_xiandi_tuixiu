import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/back_button_overlay.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/xianling_chess_game.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/stone_counter.dart';
import 'package:xiu_to_xiandi_tuixiu/services/player_storage.dart';
import 'package:xiu_to_xiandi_tuixiu/services/xianling_chess_storage.dart';
import 'package:xiu_to_xiandi_tuixiu/utils/cultivation_level.dart';

import '../widgets/dialogs/chess_poem_dialog.dart';
import '../widgets/dialogs/chess_stone_select_dialog.dart';

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
      builder: (_) => ChessStoneSelectDialog(
        onStoneSelected: (stone) async {
          await XianlingChessStorage.savePlayerStone(stone);
          setState(() {
            playerStone = stone;
          });
          Navigator.of(context).pop();
        },
      ),
    );
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
      '练气': '棋童',
      '筑基': '棋徒',
      '金丹': '棋士',
      '元婴': '棋客',
      '化神': '棋修',
      '炼虚': '棋灵',
      '合体': '棋狂',
      '大乘': '棋尊',
      '渡劫': '棋圣',
    };
    return map[realm] ?? '棋帝';
  }

  int _getAILevelByRealm(String realm) {
    if (realm == '练气' || realm == '筑基') return 0;
    if (realm == '金丹' || realm == '元婴') return 1;
    if (realm == '化神' || realm == '炼虚' || realm == '合体') return 2;
    // 其他情况都归为高级 AI
    return 3;
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
    final cellSize = screenWidth * 0.5 / boardSize;
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

                      return FutureBuilder(
                        future: XianlingChessStorage.getWinStats(),
                        builder: (context, statSnap) {
                          final (wins, total, rate) = statSnap.data ?? (0, 0, 0.0);

                          final statColor = isPlayerBlack ? Colors.black : Colors.white;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '胜率 ${(rate * 100).toStringAsFixed(1)}%（共 $total 局）',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: statColor,
                                  decoration: TextDecoration.none, // ✅ 不要下划线
                                ),
                              ),
                              const SizedBox(height: 4),

                              // ✅ 保留原始玩家信息组件
                              StoneCounter(
                                playerName: playerName,
                                realm: realm,
                                label: isPlayerBlack ? '黑子' : '白子',
                                color: isPlayerBlack ? Colors.black : Colors.white,
                                count: isPlayerBlack ? value['black']! : value['white']!,
                              ),
                            ],
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
            const ChessPoemDialog(),
            const BackButtonOverlay(),
          ],
        );
      },
    );
  }
}
