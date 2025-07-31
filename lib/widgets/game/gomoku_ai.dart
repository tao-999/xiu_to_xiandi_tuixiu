import 'dart:math';

class GomokuAI {
  final int level;
  GomokuAI({required this.level});

  List<int> getMove(List<List<int>> board, int aiPlayer) {
    final enemy = aiPlayer == 1 ? 2 : 1;
    final size = board.length;
    final depth = size <= 9 ? 4 : (size <= 12 ? 3 : 2);
    final candidates = _generateCandidateMoves(board, aiPlayer);

    // ✅ Step 0：AI 直接赢
    for (final move in candidates) {
      board[move[0]][move[1]] = aiPlayer;
      if (_checkWin(board, aiPlayer)) {
        board[move[0]][move[1]] = 0;
        return move;
      }
      board[move[0]][move[1]] = 0;
    }

    // ✅ Step 1：封锁玩家五连
    for (final move in candidates) {
      board[move[0]][move[1]] = enemy;
      if (_checkWin(board, enemy)) {
        board[move[0]][move[1]] = 0;
        return move;
      }
      board[move[0]][move[1]] = 0;
    }

    // ✅ Step 1.5：封锁三4连（改为寻找威胁点）
    final threats = _findThreatLines(board, enemy);
    if (threats.isNotEmpty) {
      return threats.first;
    }

    // ✅ Step 2：搜索最优
    return _minimaxMove(board, aiPlayer, depth: depth);
  }

  List<List<int>> _findThreatLines(List<List<int>> board, int player) {
    final result = <List<int>>[];
    final size = board.length;
    final dirs = [[1, 0], [0, 1], [1, 1], [1, -1]];

    for (int r = 0; r < size; r++) {
      for (int c = 0; c < size; c++) {
        for (var dir in dirs) {
          final line = <int>[];

          for (int i = -1; i <= 5; i++) {
            int nr = r + dir[0] * i;
            int nc = c + dir[1] * i;
            if (nr >= 0 && nr < size && nc >= 0 && nc < size) {
              line.add(board[nr][nc]);
            } else {
              line.add(-1);
            }
          }

          for (int i = 0; i <= 2; i++) {
            final sub = line.sublist(i, i + 6);
            final str = sub.toString();

            if (str == '[0, $player, $player, $player, $player, 0]') {
              int b1r = r + dir[0] * (i - 1);
              int b1c = c + dir[1] * (i - 1);
              int b2r = r + dir[0] * (i + 5);
              int b2c = c + dir[1] * (i + 5);

              if (_inBounds(board, b1r, b1c) && board[b1r][b1c] == 0) {
                result.add([b1r, b1c]);
              }
              if (_inBounds(board, b2r, b2c) && board[b2r][b2c] == 0) {
                result.add([b2r, b2c]);
              }
            }
          }
        }
      }
    }

    return result;
  }

  List<int> _minimaxMove(List<List<int>> board, int aiPlayer, {int depth = 4}) {
    final enemy = aiPlayer == 1 ? 2 : 1;
    List<int>? bestMove;
    int bestScore = -1000000;
    final transpositionTable = <int, int>{};
    final candidates = _generateCandidateMoves(board, aiPlayer).take(10).toList();

    for (final move in candidates) {
      final r = move[0], c = move[1];
      board[r][c] = aiPlayer;
      final hash = _boardHash(board, depth, true, aiPlayer, enemy);
      final score = _minimax(board, depth - 1, false, aiPlayer, enemy, -999999, 999999, transpositionTable, hash);
      board[r][c] = 0;

      if (score > bestScore) {
        bestScore = score;
        bestMove = [r, c];
      }
    }

    return bestMove ?? _randomBestFallback(board);
  }

  int _minimax(
      List<List<int>> board,
      int depth,
      bool isMax,
      int aiPlayer,
      int enemy,
      int alpha,
      int beta,
      Map<int, int> cache,
      int hash,
      ) {
    if (cache.containsKey(hash)) return cache[hash]!;
    if (_checkWin(board, aiPlayer)) return 99999 - (4 - depth);
    if (_checkWin(board, enemy)) return -99999 + (4 - depth);
    if (depth == 0) return _evaluate(board, aiPlayer);

    final moves = _generateCandidateMoves(board, aiPlayer).take(10);
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

  List<List<int>> _generateCandidateMoves(List<List<int>> board, int player) {
    final result = <List<int>>[];
    final n = board.length;
    final exists = <String>{};

    for (int r = 0; r < n; r++) {
      for (int c = 0; c < n; c++) {
        if (board[r][c] != 0) {
          for (int dr = -2; dr <= 2; dr++) {
            for (int dc = -2; dc <= 2; dc++) {
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

    result.sort((a, b) =>
        _evaluateMove(board, b[0], b[1], player).compareTo(_evaluateMove(board, a[0], a[1], player)));
    return result.isEmpty ? [[n ~/ 2, n ~/ 2]] : result;
  }

  int _evaluate(List<List<int>> board, int player) {
    int score = 0;
    score += _countConnected(board, player, 5) * 100000;
    score += _countConnected(board, player, 4) * 10000;
    score += _countConnected(board, player, 3) * 500;
    score += _countConnected(board, player, 2) * 100;
    return score;
  }

  int _evaluateMove(List<List<int>> board, int r, int c, int player) {
    int score = 0;
    final dirs = [[1, 0], [0, 1], [1, 1], [1, -1]];

    for (var dir in dirs) {
      int cnt = 1;
      for (int i = 1; i <= 2; i++) {
        int nr = r + dir[0] * i, nc = c + dir[1] * i;
        if (_inBounds(board, nr, nc) && board[nr][nc] == player) cnt++;
      }
      for (int i = 1; i <= 2; i++) {
        int nr = r - dir[0] * i, nc = c - dir[1] * i;
        if (_inBounds(board, nr, nc) && board[nr][nc] == player) cnt++;
      }
      score += pow(cnt, 2).toInt();
    }

    return score;
  }

  int _countConnected(List<List<int>> board, int player, int length) {
    int count = 0;
    final dirs = [[1, 0], [0, 1], [1, 1], [1, -1]];
    final size = board.length;

    for (int r = 0; r < size; r++) {
      for (int c = 0; c < size; c++) {
        for (var dir in dirs) {
          bool ok = true;
          for (int i = 0; i < length; i++) {
            int nr = r + dir[0] * i, nc = c + dir[1] * i;
            if (!_inBounds(board, nr, nc) || board[nr][nc] != player) {
              ok = false;
              break;
            }
          }
          if (ok) count++;
        }
      }
    }

    return count;
  }

  bool _checkWin(List<List<int>> board, int player) {
    return _countConnected(board, player, 5) > 0;
  }

  bool _inBounds(List<List<int>> board, int r, int c) {
    return r >= 0 && c >= 0 && r < board.length && c < board.length;
  }

  int _boardHash(List<List<int>> board, int depth, bool isMax, int aiPlayer, int enemy) {
    final flat = board.expand((e) => e).toList();
    return Object.hashAll([...flat, depth, isMax, aiPlayer, enemy]);
  }

  List<int> _randomBestFallback(List<List<int>> board) {
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
