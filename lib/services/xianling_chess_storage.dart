import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class XianlingChessStorage {
  static const _keyBoard = 'chess_board';
  static const _keyCurrentPlayer = 'chess_current_player';

  static Future<void> saveBoard(List<List<int>> board, int currentPlayer) async {
    final prefs = await SharedPreferences.getInstance();
    final boardJson = jsonEncode(board);
    await prefs.setString(_keyBoard, boardJson);
    await prefs.setInt(_keyCurrentPlayer, currentPlayer);
  }

  static Future<(List<List<int>>, int)?> loadBoard() async {
    final prefs = await SharedPreferences.getInstance();
    final boardJson = prefs.getString(_keyBoard);
    final currentPlayer = prefs.getInt(_keyCurrentPlayer);

    if (boardJson == null || currentPlayer == null) return null;

    final decoded = (jsonDecode(boardJson) as List)
        .map((row) => List<int>.from(row))
        .toList();

    return (decoded, currentPlayer);
  }

  static Future<void> clearBoard() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyBoard);
    await prefs.remove(_keyCurrentPlayer);
  }

  static const _playerKey = 'player_stone';

  static Future<void> savePlayerStone(int stone) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_playerKey, stone);
  }

  static Future<int?> getPlayerStone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_playerKey); // null = 未选择
  }

  static const _keyTotalGames = 'chess_total_games';
  static const _keyWins = 'chess_wins';
  static const _keyDraws = 'chess_draws';

  /// 🏆 玩家胜利
  static Future<void> incrementWin() async {
    final prefs = await SharedPreferences.getInstance();
    final wins = prefs.getInt(_keyWins) ?? 0;
    await prefs.setInt(_keyWins, wins + 1);

    final total = prefs.getInt(_keyTotalGames) ?? 0;
    await prefs.setInt(_keyTotalGames, total + 1);
  }

  /// 😐 平局
  static Future<void> incrementDraw() async {
    final prefs = await SharedPreferences.getInstance();
    final draws = prefs.getInt(_keyDraws) ?? 0;
    await prefs.setInt(_keyDraws, draws + 1);

    final total = prefs.getInt(_keyTotalGames) ?? 0;
    await prefs.setInt(_keyTotalGames, total + 1);
  }

  /// 💥 玩家失败（只增加对局数）
  static Future<void> incrementLoss() async {
    final prefs = await SharedPreferences.getInstance();
    final total = prefs.getInt(_keyTotalGames) ?? 0;
    await prefs.setInt(_keyTotalGames, total + 1);
  }

  /// 📊 获取战绩：胜场、总局数、胜率（0~1）
  static Future<(int wins, int total, double winRate)> getWinStats() async {
    final prefs = await SharedPreferences.getInstance();
    final wins = prefs.getInt(_keyWins) ?? 0;
    final total = prefs.getInt(_keyTotalGames) ?? 0;
    final rate = (total == 0) ? 0.0 : (wins / total);
    return (wins, total, rate);
  }
}
