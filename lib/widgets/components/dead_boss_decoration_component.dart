import 'package:flame/components.dart';
import 'package:flutter/cupertino.dart';
import '../../services/dead_boss_storage.dart';
import 'floating_island_static_decoration_component.dart';

/// ☠️ 死亡 Boss 尸体渲染组件
/// - 自动读取死亡记录
/// - 按视野范围 *1.5 渲染尸体贴图
/// - 超出范围自动移除
class DeadBossDecorationComponent extends Component with HasGameReference {
  final Component parentLayer;
  final Vector2 Function() getViewCenter;
  final Vector2 Function() getViewSize;

  final Map<String, SpriteComponent> _activeBodies = {};
  bool _printedLog = false;

  DeadBossDecorationComponent({
    required this.parentLayer,
    required this.getViewCenter,
    required this.getViewSize,
  });

  @override
  void update(double dt) {
    super.update(dt);

    final center = getViewCenter();
    final viewSize = getViewSize();
    final halfSize = viewSize.clone()..multiply(Vector2.all(1.5));
    final min = center - halfSize;
    final max = center + halfSize;

    final neededKeys = <String>{};

    // ✅ 异步处理
    Future.microtask(() async {
      final allDead = await DeadBossStorage.getAllDeathEntries();
      if (!_printedLog) {
        debugPrint('🧟‍♂️ [DeadBoss] 共 ${allDead.length} 个死亡记录，开始渲染判断...');
      }

      for (final entry in allDead.entries) {
        final pos = entry.value;
        final key = '${pos.x}_${pos.y}';

        if (pos.x >= min.x && pos.x <= max.x && pos.y >= min.y && pos.y <= max.y) {
          neededKeys.add(key);

          if (!_activeBodies.containsKey(key)) {
            if (!_printedLog) {
              final type = await DeadBossStorage.getBossTypeByPosition(pos);
              final size = await DeadBossStorage.getBossSizeByPosition(pos);
              debugPrint('💀 渲染尸体: pos=$key, type=$type, size=$size');
            }

            await _spawnBody(pos, key);
          }
        }
      }

      if (!_printedLog) {
        _printedLog = true;
      }

      // 🧹 移除不在视野范围内的尸体
      final toRemove = _activeBodies.keys.where((key) => !neededKeys.contains(key)).toList();
      for (final key in toRemove) {
        final comp = _activeBodies.remove(key);
        comp?.removeFromParent();
      }
    });
  }

  Future<void> _spawnBody(Vector2 pos, String key) async {
    final type = await DeadBossStorage.getBossTypeByPosition(pos);
    if (type == null) return;

    final spritePath = _getSpritePath(type);
    final sprite = await Sprite.load(spritePath);
    final size = await DeadBossStorage.getBossSizeByPosition(pos) ?? Vector2.all(64);

    final body = FloatingIslandStaticDecorationComponent(
      sprite: sprite,
      size: size,
      worldPosition: pos,
      logicalOffset: getViewCenter() - getViewSize() / 2,
      spritePath: spritePath,
      type: type,
      anchor: Anchor.bottomCenter,
    );

    _activeBodies[key] = body;
    parentLayer.add(body);
  }

  String _getSpritePath(String type) {
    switch (type) {
      case 'boss_1':
        return 'floating_island/beach_boss_1_dead.png';
      default:
        return 'floating_island/beach_boss_1_dead.png';
    }
  }
}
