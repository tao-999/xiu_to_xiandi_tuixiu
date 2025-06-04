import 'dart:collection';
import 'dart:math';

/// 📦 地图格子占用管理器
/// 用于记录哪些 tile 已被占用，防止生成内容重叠
class TileManager {
  final Set<Point<int>> _occupied = HashSet(); // 已占格子

  /// 检查某块区域是否被占
  bool isOccupied(int x, int y, int w, int h) {
    for (int dx = 0; dx < w; dx++) {
      for (int dy = 0; dy < h; dy++) {
        final p = Point(x + dx, y + dy);
        if (_occupied.contains(p)) return true;
      }
    }
    return false;
  }

  /// 占用一块区域
  void occupy(int x, int y, int w, int h) {
    for (int dx = 0; dx < w; dx++) {
      for (int dy = 0; dy < h; dy++) {
        _occupied.add(Point(x + dx, y + dy));
      }
    }
  }

  /// 是否某格子已占用
  bool isTileOccupied(int x, int y) => _occupied.contains(Point(x, y));

  /// 占用单个格子
  void occupyTile(int x, int y) => _occupied.add(Point(x, y));

  /// 批量排除已有坐标
  void occupyMany(Iterable<Point<int>> tiles) => _occupied.addAll(tiles);

  /// 读取所有已占用格子
  Set<Point<int>> get occupiedTiles => _occupied;

  /// 清空记录（如果你想重建地图）
  void clear() => _occupied.clear();
}
