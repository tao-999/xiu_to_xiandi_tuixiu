import 'dart:math';
import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'package:flutter/cupertino.dart';
import '../../services/zongmen_diplomacy_service.dart';
import 'sect_component.dart';
import 'sect_info.dart';

class SectManagerComponent extends Component {
  final Component grid;
  final Vector2 Function() getLogicalOffset;
  final Vector2 Function() getViewSize;
  final double mapMaxSize;
  final double sectImageSize;
  final int sectCount;
  final double sectCircleRadius;

  final List<SectComponent> _sects = [];
  final Map<int, ui.Image> _sectImageCache = {};

  SectManagerComponent({
    required this.grid,
    required this.getLogicalOffset,
    required this.getViewSize,
    this.mapMaxSize = 2500.0,
    this.sectImageSize = 192.0,
    this.sectCount = 30,
    this.sectCircleRadius = 512.0,
  });

  @override
  Future<void> onLoad() async {
    // 🌟加载所有宗门图片
    for (var info in SectInfo.allSects) {
      _sectImageCache[info.id] =
      await Flame.images.load('zongmen/${info.id}.png');
    }

    // 🌟加载持久化坐标
    final data = await ZongmenDiplomacyService.load();
    final savedPositions = data['sects'] as List<MapEntry<int, Vector2>>;
    final savedPositionMap = { for (var e in savedPositions) e.key : e.value };

    // 🌟初始化宗门位置
    final random = Random();
    final List<Vector2> positions = [];

    // 最小距离(0,0)
    final double minDistanceFromCenter = 800.0;

    for (var info in SectInfo.allSects) {
      Vector2 pos;

      if (savedPositionMap.containsKey(info.id)) {
        pos = savedPositionMap[info.id]!;
      } else {
        do {
          final x = random.nextDouble() * (mapMaxSize * 2) - mapMaxSize;
          final y = random.nextDouble() * (mapMaxSize * 2) - mapMaxSize;
          pos = Vector2(x, y);
        } while (pos.length < minDistanceFromCenter);
      }

      positions.add(pos);

      final img = _sectImageCache[info.id];
      if (img == null) continue;

      final sect = SectComponent(
        info: info,
        image: img,
        imageSize: sectImageSize,
        worldPosition: pos,
        circleRadius: sectCircleRadius,
      );

      _sects.add(sect);
      grid.add(sect);
    }

    // 🌟打印所有坐标
    final coords = positions
        .map((v) => '(${v.x.toStringAsFixed(2)},${v.y.toStringAsFixed(2)})')
        .join(',');
    debugPrint('🎯 初始化宗门坐标: [$coords]');
  }

  @override
  void update(double dt) {
    super.update(dt);

    final offset = getLogicalOffset();

    for (final s in _sects) {
      s.updatePhysics(_sects, dt, mapMaxSize);
      s.updateVisualPosition(offset);
    }
  }
}
