// 📦 文件：gomoku_ai_pro.dart（修复版）
import 'dart:math';

class GomokuAI {
  final int level;
  GomokuAI({required this.level});

  List<int> getMove(List<List<int>> board, int aiPlayer) {
    final enemy = aiPlayer == 1 ? 2 : 1;
    final depth = min(4, level + 1);
    final candidates = _generateCandidateMoves(board);

    // ✅ Step 0：AI 自己能赢 → 立刻取胜
    for (final move in candidates) {
      board[move[0]][move[1]] = aiPlayer;
      if (_checkWin(board, aiPlayer)) {
        board[move[0]][move[1]] = 0;
        return move;
      }
      board[move[0]][move[1]] = 0;
    }

    // ✅ Step 1：玩家下一步能赢 → 马上封锁
    for (final move in candidates) {
      board[move[0]][move[1]] = enemy;
      if (_checkWin(board, enemy)) {
        board[move[0]][move[1]] = 0;
        return move;
      }
      board[move[0]][move[1]] = 0;
    }

    // ✅ Step 2：封锁强势形势
    for (final move in candidates) {
      board[move[0]][move[1]] = enemy;
      final danger = _evaluate(board, enemy);
      board[move[0]][move[1]] = 0;
      if (danger >= 8000) {
        return move;
      }
    }

    // ✅ Step 3：正式搜索
    return _minimaxMove(board, aiPlayer, depth: depth);
  }

  List<int> _minimaxMove(List<List<int>> board, int aiPlayer, {int depth = 4}) {
    final enemy = aiPlayer == 1 ? 2 : 1;
    final transpositionTable = <String, int>{};
    List<int>? bestMove;
    int bestScore = -1000000;
    final candidates = _generateCandidateMoves(board);

    for (final move in candidates) {
      final r = move[0], c = move[1];
      board[r][c] = aiPlayer;
      final hash = _boardHash(board, depth, true, aiPlayer, enemy);
      final score = _minimax(
        board,
        depth - 1,
        false,
        aiPlayer,
        enemy,
        -999999,
        999999,
        transpositionTable,
        hash,
      );
      board[r][c] = 0;

      if (score > bestScore) {
        bestScore = score;
        bestMove = [r, c];
      }
    }
    return bestMove ?? _randomBestFallback(board, aiPlayer);
  }

  int _minimax(
      List<List<int>> board,
      int depth,
      bool isMax,
      int aiPlayer,
      int enemy,
      int alpha,
      int beta,
      Map<String, int> cache,
      String hash,
      ) {
    if (cache.containsKey(hash)) return cache[hash]!;
    if (_checkWin(board, aiPlayer)) return 99999 - (4 - depth);
    if (_checkWin(board, enemy)) return -99999 + (4 - depth);
    if (depth == 0) return _evaluate(board, aiPlayer);

    final moves = _generateCandidateMoves(board);
    int best = isMax ? -999999 : 999999;

    for (final move in moves) {
      final r = move[0], c = move[1];
      board[r][c] = isMax ? aiPlayer : enemy;
      final childHash = _boardHash(board, depth, !isMax, aiPlayer, enemy);
      final val = _minimax(board, depth - 1, !isMax, aiPlayer, enemy, alpha, beta, cache, childHash);
      board[r][c] = 0;

      if (isMax) {
        best = max(best, val);
        alpha = max(alpha, best);
      } else {
        best = min(best, val);
        beta = min(beta, best);
      }

      if (beta <= alpha) break;
    }
    cache[hash] = best;
    return best;
  }

  List<List<int>> _generateCandidateMoves(List<List<int>> board) {
    final result = <List<int>>[];
    final n = board.length;
    final exists = <String>{};
    for (int r = 0; r < n; r++) {
      for (int c = 0; c < n; c++) {
        if (board[r][c] != 0) {
          for (int dr = -2; dr <= 2; dr++) {
            for (int dc = -2; dc <= 2; dc++) {
              if (dr == 0 && dc == 0) continue;
              int nr = r + dr, nc = c + dc;
              if (nr >= 0 && nc >= 0 && nr < n && nc < n && board[nr][nc] == 0) {
                final key = '$nr-$nc';
                if (!exists.contains(key)) {
                  exists.add(key);
                  result.add([nr, nc]);
                }
              }
            }
          }
        }
      }
    }
    return result.isEmpty ? [[n ~/ 2, n ~/ 2]] : result;
  }

  int _evaluate(List<List<int>> board, int player) {
    int score = 0;
    final patterns = {
      [1, 1, 1, 1, 1]: 100000,
      [0, 1, 1, 1, 1, 0]: 10000,
      [0, 1, 1, 1, 1]: 8000,
      [1, 1, 1, 1, 0]: 8000,
      [0, 1, 1, 1, 0]: 2000,
      [0, 1, 1, 0]: 500,
    };
    for (final entry in patterns.entries) {
      score += _matchPattern(board, player, entry.key) * entry.value;
    }
    return score;
  }

  int _matchPattern(List<List<int>> board, int player, List<int> pattern) {
    int count = 0;
    final size = board.length;
    final dirs = [[1, 0], [0, 1], [1, 1], [1, -1]];
    for (int r = 0; r < size; r++) {
      for (int c = 0; c < size; c++) {
        for (var dir in dirs) {
          int dr = dir[0], dc = dir[1];
          List<int> line = [];
          for (int i = 0; i < pattern.length; i++) {
            int nr = r + dr * i, nc = c + dc * i;
            if (nr >= 0 && nc >= 0 && nr < size && nc < size) {
              line.add(board[nr][nc] == player ? 1 : (board[nr][nc] == 0 ? 0 : 2));
            } else {
              line.add(2);
            }
          }
          if (_listEquals(line, pattern)) count++;
        }
      }
    }
    return count;
  }

  bool _checkWin(List<List<int>> board, int player) {
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

  bool _listEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  String _boardHash(List<List<int>> board, int depth, bool isMax, int aiPlayer, int enemy) {
    return '${board.map((row) => row.join()).join()}_${depth}_${(isMax ? 1 : 0)}_${aiPlayer}${enemy}';
  }

  List<int> _randomBestFallback(List<List<int>> board, int aiPlayer) {
    final empty = <List<int>>[];
    for (int r = 0; r < board.length; r++) {
      for (int c = 0; c < board[r].length; c++) {
        if (board[r][c] == 0) empty.add([r, c]);
      }
    }
    empty.shuffle();
    return empty.first;
  }
}
