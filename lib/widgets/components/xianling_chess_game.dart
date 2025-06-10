// 🗒️ 文件：lib/widgets/components/xianling_chess_game.dart
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/effects.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/glow_effect_component.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/game/gomoku_ai.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/drag_map.dart';
import 'package:xiu_to_xiandi_tuixiu/services/xianling_chess_storage.dart';

class ChessStone extends PositionComponent {
  final int player;

  ChessStone({
    required this.player,
    required Vector2 position,
    required double size,
  }) : super(
    position: position,
    size: Vector2.all(size),
    priority: 1, // ✅ 保证棋子在棋盘线之上
  );

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final paint = Paint()..color = player == 1 ? Colors.black : Colors.white;
    canvas.drawCircle(Offset(size.x / 2, size.y / 2), size.x * 0.4, paint);
  }
}

class XianlingChessGame extends FlameGame {
  final BuildContext context;
  final int boardSize;
  final double cellSize;
  final int aiLevel;
  final int playerStone; // ✅ 恢复执子参数（黑子为1，白子为2）

  late List<List<int>> board;
  int currentPlayer = 1;

  static const int maxStonesPerPlayer = 144;
  static final stoneCounter = ValueNotifier({'black': maxStonesPerPlayer, 'white': maxStonesPerPlayer});

  late GomokuAI ai;
  final ValueNotifier<bool> isLocked = ValueNotifier(false);

  XianlingChessGame(
      this.context, {
        this.boardSize = 12,
        required this.cellSize,
        required this.aiLevel,
        required this.playerStone,
      }) {
    ai = GomokuAI(level: aiLevel);
  }

  @override
  Color backgroundColor() => const Color(0x00000000);

  @override
  Future<void> onLoad() async {
    final saved = await XianlingChessStorage.loadBoard();

    if (saved != null) {
      board = saved.$1;
      currentPlayer = saved.$2;
      _rebuildBoardFromData();
    } else {
      board = List.generate(boardSize, (_) => List.filled(boardSize, 0));
      currentPlayer = playerStone; // ✅ 玩家永远先手
    }

    final grid = BoardGrid(
      boardSize: boardSize,
      cellSize: cellSize,
    )..add(OpacityEffect.to(
      0.3,
      EffectController(duration: 0.01),
    ));
    add(grid);

    add(DragMap(
      onDragged: (_) {},
      onTap: _handleTap,
      isTapLocked: isLocked,
    ));

    _updateStoneCount();

    debugPrint('[XianlingChess] 当前回合：${currentPlayer == 1 ? "黑子" : "白子"}（${currentPlayer == playerStone ? "你" : "AI"}）');

    if (currentPlayer != playerStone) {
      tryAIMove();
    } else {
      isLocked.value = false;
    }
  }

  void _handleTap(Vector2 pos) {
    if (isLocked.value || currentPlayer != playerStone) return;

    final col = (pos.x / cellSize).floor();
    final row = (pos.y / cellSize).floor();

    if (row < 0 || row >= boardSize || col < 0 || col >= boardSize || board[row][col] != 0) {
      return;
    }

    isLocked.value = true;
    _placeStone(row, col, playerStone);
    currentPlayer = 3 - playerStone;
    XianlingChessStorage.saveBoard(board, currentPlayer);

    if (ai.checkWin(board, playerStone)) {
      _showWinDialog(playerStone);
      return;
    }

    if (_isBoardFull()) {
      _showDrawDialog();
      return;
    }

    Future.delayed(const Duration(milliseconds: 300), tryAIMove);
  }

  void tryAIMove() {
    if (currentPlayer == playerStone) return;
    isLocked.value = true;

    Future.delayed(const Duration(milliseconds: 300), () {
      final aiMove = ai.getMove(board, 3 - playerStone);
      if (aiMove.isNotEmpty) {
        _placeStone(aiMove[0], aiMove[1], 3 - playerStone);
        currentPlayer = playerStone;
        XianlingChessStorage.saveBoard(board, currentPlayer);

        if (ai.checkWin(board, 3 - playerStone)) {
          _showWinDialog(3 - playerStone);
          return;
        }

        if (_isBoardFull()) {
          _showDrawDialog();
          return;
        }
      }

      Future.delayed(const Duration(milliseconds: 100), () {
        isLocked.value = false;
      });
    });
  }

  void _placeStone(int row, int col, int player, {bool save = true}) {
    board[row][col] = player;
    final pos = Vector2(col * cellSize, row * cellSize);

    add(ChessStone(
      player: player,
      position: pos,
      size: cellSize,
    ));

    add(GlowEffectComponent(
      position: pos + Vector2.all(cellSize / 2),
      size: cellSize,
      glowColor: player == 1 ? Colors.black : Colors.white,
    ));

    _updateStoneCount();

    if (save) {
      XianlingChessStorage.saveBoard(board, currentPlayer);
    }
  }

  void _rebuildBoardFromData() {
    for (int row = 0; row < boardSize; row++) {
      for (int col = 0; col < boardSize; col++) {
        final value = board[row][col];
        if (value != 0) {
          _placeStone(row, col, value, save: false);
        }
      }
    }
  }

  void _updateStoneCount() {
    int blackUsed = 0;
    int whiteUsed = 0;

    for (final row in board) {
      for (final cell in row) {
        if (cell == 1) blackUsed++;
        if (cell == 2) whiteUsed++;
      }
    }

    stoneCounter.value = {
      'black': maxStonesPerPlayer - blackUsed,
      'white': maxStonesPerPlayer - whiteUsed,
    };
  }

  void _showWinDialog(int player) {
    final color = player == 1 ? '黑子' : '白子';

    // ❌ 不要提前 resetBoard！

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return GestureDetector(
          onTap: () => Navigator.of(context).pop(), // 点了就 pop
          child: Dialog(
            backgroundColor: const Color(0xFFF9F5E3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    '🎉 胜利！',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '$color 获胜！',
                    style: const TextStyle(fontSize: 16, color: Colors.red),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '点击任意位置继续',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ).then((_) {
      // ✅ 弹窗关闭后再重置，确保动画和组件 add 完成
      _resetBoard();
    });
  }

  void _showDrawDialog() {
    // ❌ 不要在这里 resetBoard！

    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.3),
      builder: (BuildContext context) {
        return GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          behavior: HitTestBehavior.translucent,
          child: Dialog(
            backgroundColor: const Color(0xFFF9F5E3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text(
                    '平局',
                    style: TextStyle(fontSize: 16),
                  ),
                  SizedBox(height: 12),
                  Text('棋盘已下满，未分胜负！'),
                  SizedBox(height: 8),
                  Text(
                    '点击任意位置继续',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ).then((_) {
      _resetBoard(); // ✅ 等弹窗关闭后再清
    });
  }

  bool _isBoardFull() {
    for (final row in board) {
      for (final cell in row) {
        if (cell == 0) return false;
      }
    }
    return true;
  }

  void _resetBoard() {
    board = List.generate(boardSize, (_) => List.filled(boardSize, 0));
    currentPlayer = playerStone; // ✅ 玩家永远是先手

    // 清除棋子和特效
    children.whereType<ChessStone>().forEach((e) => e.removeFromParent());
    children.whereType<GlowEffectComponent>().forEach((e) => e.removeFromParent());

    _updateStoneCount();
    isLocked.value = false;

    // 清空存档并保存新状态
    XianlingChessStorage.clearBoard();
    XianlingChessStorage.saveBoard(board, currentPlayer);

    // ✅ 极端情况容错：如果currentPlayer被篡改，手动触发AI落子
    if (currentPlayer != playerStone) {
      tryAIMove();
    }
  }
}

class BoardGrid extends PositionComponent with HasPaint {
  final int boardSize;
  final double cellSize;

  BoardGrid({
    required this.boardSize,
    required this.cellSize,
  }) : super(
    size: Vector2.all(boardSize * cellSize),
    position: Vector2.zero(),
    priority: 0, // ✅ 最底层
  ) {
    paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 1.0;
  }

  @override
  void render(Canvas canvas) {
    for (int i = 0; i < boardSize; i++) {
      final offset = i * cellSize + cellSize / 2;
      canvas.drawLine(Offset(cellSize / 2, offset), Offset(size.x - cellSize / 2, offset), paint);
      canvas.drawLine(Offset(offset, cellSize / 2), Offset(offset, size.y - cellSize / 2), paint);
    }
  }
}

extension GomokuAIExtension on GomokuAI {
  bool checkWin(List<List<int>> board, int player) {
    return _checkWinInternal(board, player);
  }

  bool _checkWinInternal(List<List<int>> board, int player) {
    for (int r = 0; r < board.length; r++) {
      for (int c = 0; c < board[r].length; c++) {
        if (board[r][c] == player) {
          if (_checkDir(board, r, c, 1, 0, player) ||
              _checkDir(board, r, c, 0, 1, player) ||
              _checkDir(board, r, c, 1, 1, player) ||
              _checkDir(board, r, c, 1, -1, player)) {
            return true;
          }
        }
      }
    }
    return false;
  }

  bool _checkDir(List<List<int>> board, int r, int c, int dr, int dc, int player) {
    for (int i = 0; i < 5; i++) {
      int nr = r + dr * i, nc = c + dc * i;
      if (nr < 0 || nc < 0 || nr >= board.length || nc >= board.length || board[nr][nc] != player) return false;
    }
    return true;
  }
}
