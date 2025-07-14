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
  final double mapWidth;
  final double mapHeight;
  final double sectImageSize;
  final double sectCircleRadius;

  final List<SectComponent> _sects = [];
  final Map<int, ui.Image> _sectImageCache = {};

  SectManagerComponent({
    required this.grid,
    required this.getLogicalOffset,
    required this.getViewSize,
    required this.mapWidth,
    required this.mapHeight,
    this.sectImageSize = 192.0,
    this.sectCircleRadius = 512.0,
  });

  @override
  Future<void> onLoad() async {
    // 🌟加载宗门贴图
    for (var info in SectInfo.allSects) {
      _sectImageCache[info.id] =
      await Flame.images.load('zongmen/${info.id}.png');
    }

    // 🌟加载持久化数据
    final data = await ZongmenDiplomacyService.load();
    final savedSects = data['sects'] as List<Map<String, dynamic>>;
    final playerPosition = data['player'] as Vector2;

    final random = Random();
    final List<Map<String, dynamic>> sectDataToSave = [];

    final bool isFirstInit = savedSects.isEmpty;

    if (isFirstInit) {
      debugPrint('✅ 首次初始化宗门');

      for (var info in SectInfo.allSects) {
        // 随机坐标
        final pos = Vector2(
          sectCircleRadius +
              random.nextDouble() * (mapWidth - 2 * sectCircleRadius),
          sectCircleRadius +
              random.nextDouble() * (mapHeight - 2 * sectCircleRadius),
        );

        // 初始化1级宗门
        final sectInfo = SectInfo.generateInitial(info.id);

        sectDataToSave.add({
          'id': sectInfo.id,
          'level': sectInfo.level,
          'masterPowerAtLevel1': sectInfo.masterPowerAtLevel1,
          'x': pos.x,
          'y': pos.y,
        });

        final img = _sectImageCache[sectInfo.id];
        if (img == null) continue;

        final sect = SectComponent(
          info: sectInfo,
          image: img,
          imageSize: sectImageSize,
          worldPosition: pos,
          circleRadius: sectCircleRadius,
        );

        _sects.add(sect);
        grid.add(sect);
      }

      await ZongmenDiplomacyService.save(
        sectData: sectDataToSave,
        playerPosition: Vector2(mapWidth / 2, mapHeight / 2),
      );
      debugPrint('✅ 宗门数据已持久化');
    } else {
      debugPrint('✅ 加载已有宗门数据');

      for (final saved in savedSects) {
        debugPrint('🟢 saved = $saved');
        final id = saved['id'] as int;
        final level = saved['level'] as int;
        final masterPowerAtLevel1 = saved['masterPowerAtLevel1'] as int;
        final x = saved['x'] as double;
        final y = saved['y'] as double;

        // 🌟用withLevel生成
        final sectInfo = SectInfo.withLevel(
          id: id,
          level: level,
          masterPowerAtLevel1: masterPowerAtLevel1,
        );

        final img = _sectImageCache[id];
        if (img == null) continue;

        final sect = SectComponent(
          info: sectInfo,
          image: img,
          imageSize: sectImageSize,
          worldPosition: Vector2(x, y),
          circleRadius: sectCircleRadius,
        );

        _sects.add(sect);
        grid.add(sect);
      }
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    final offset = getLogicalOffset();

    for (final s in _sects) {
      s.updatePhysics(_sects, dt, max(mapWidth, mapHeight));

      final pos = s.worldPosition;

      final clampedX =
      pos.x.clamp(s.circleRadius, mapWidth - s.circleRadius);
      final clampedY =
      pos.y.clamp(s.circleRadius, mapHeight - s.circleRadius);

      if (pos.x != clampedX || pos.y != clampedY) {
        s.worldPosition = Vector2(clampedX, clampedY);
      }

      s.updateVisualPosition(offset);
    }
  }
}
