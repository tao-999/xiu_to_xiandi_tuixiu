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
}
