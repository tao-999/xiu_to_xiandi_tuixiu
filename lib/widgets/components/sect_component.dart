import 'dart:math';
import 'dart:ui' as ui;
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/flame.dart';
import 'package:flutter/material.dart';
import 'sect_info.dart';
import '../../services/zongmen_diplomacy_service.dart';
import '../../services/zongmen_storage.dart';
import '../../services/resources_storage.dart';
import '../../models/disciple.dart';

class SectComponent extends PositionComponent
    with HasGameReference<FlameGame>, CollisionCallbacks {
  SectInfo info;
  final ui.Image image;
  final double imageSize;
  Vector2 worldPosition;
  final double circleRadius;

  Vector2 velocity = Vector2.zero();
  double _directionTimer = 0;

  bool isBeingAttacked = false;
  ui.Image? dispatchedDiscipleImage;
  String? dispatchedDiscipleId;

  Vector2 dispatchedDisciplePos = Vector2.zero();
  Vector2 dispatchedVelocity = Vector2.zero();

  final List<int> waveTimestamps = [];

  int? expeditionEndTime;

  SectComponent({
    required this.info,
    required this.image,
    required this.imageSize,
    required this.worldPosition,
    required this.circleRadius,
  }) : super(
    size: Vector2.all(circleRadius * 2),
    anchor: Anchor.center,
  ) {
    _assignRandomVelocity();
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(
      CircleHitbox(
        radius: circleRadius,
        anchor: Anchor.topLeft,
        collisionType: CollisionType.passive,
      ),
    );
    await refreshExpedition();
  }

  Future<void> refreshExpedition() async {
    final expeditions = await ZongmenDiplomacyService.getAllExpeditions();
    final record = expeditions[info.id];
    if (record != null) {
      isBeingAttacked = true;

      final discipleId = record['discipleId'] as String;
      dispatchedDiscipleId = discipleId;

      final startTime = record['time'] as int;
      expeditionEndTime = startTime + 5 * 60 * 1000;

      // 🌟 如果已经过期，立即触发奖励
      final now = DateTime.now().millisecondsSinceEpoch;
      if (now >= expeditionEndTime!) {
        _triggerLevelUpAndReward();
        return;
      }

      final allDisciples = await ZongmenStorage.loadDisciples();
      Disciple? disciple;
      final found = allDisciples.where((d) => d.id == discipleId);
      if (found.isNotEmpty) {
        disciple = found.first;
      }

      if (disciple != null) {
        final path = disciple.imagePath;
        final normalizedPath = path.startsWith('assets/images/')
            ? path.substring('assets/images/'.length)
            : path;

        dispatchedDiscipleImage = await Flame.images.load(normalizedPath);

        dispatchedDisciplePos = Vector2(circleRadius * 1.2, 0);
        dispatchedVelocity = (-dispatchedDisciplePos).normalized() * 500;
      }
    } else {
      isBeingAttacked = false;
      dispatchedDiscipleImage = null;
      dispatchedDiscipleId = null;
      expeditionEndTime = null;
    }
  }

  void _assignRandomVelocity() {
    final random = Random();
    final angle = random.nextDouble() * pi * 2;
    final speed = 20.0 + random.nextDouble() * 2.0;
    velocity = Vector2(cos(angle), sin(angle)) * speed;
    _directionTimer = 3.0 + random.nextDouble() * 3.0;
  }

  void stopMovement() {
    velocity = Vector2.zero();
  }

  void _triggerLevelUpAndReward() {
    // 🟢先同步标记为已结束，防止重复触发
    isBeingAttacked = false;
    expeditionEndTime = null;

    Future(() async {
      debugPrint('[Diplomacy] 宗门 ${info.name} 讨伐结束，发放奖励...');

      // 🌟发放奖励
      await ResourcesStorage.add('spiritStoneLow', info.spiritStoneLow);

      // 🌟清除讨伐记录
      await ZongmenDiplomacyService.clearSectExpedition(info.id);

      // 🌟升级：用固定的masterPowerAtLevel1递增
      final newLevel = info.level + 1;
      info = SectInfo.withLevel(
        id: info.id,
        level: newLevel,
        masterPowerAtLevel1: info.masterPowerAtLevel1,
      );

      debugPrint('[Diplomacy] 宗门${info.name}等级提升到${info.level}');

      // 🌟持久化新等级
      await ZongmenDiplomacyService.updateSectLevel(
        sectId: info.id,
        newLevel: newLevel,
      );

      // 🌟移除弟子派遣房
      if (dispatchedDiscipleId != null) {
        await ZongmenStorage.removeDiscipleFromRoom(
          dispatchedDiscipleId!,
          'expedition',
        );
        debugPrint('[Diplomacy] 已移除弟子 $dispatchedDiscipleId 的外交派遣房间');
      }

      dispatchedDiscipleId = null;
      dispatchedDiscipleImage = null;
    });
  }

  void updatePhysics(List<SectComponent> allSects, double dt, double mapMaxSize) {
    _directionTimer -= dt;
    if (_directionTimer <= 0) {
      _assignRandomVelocity();
    }

    worldPosition += velocity * dt;

    for (final other in allSects) {
      if (identical(this, other)) continue;
      final delta = worldPosition - other.worldPosition;
      final dist = delta.length;
      final minDist = circleRadius * 2.0;
      if (dist < minDist && dist > 0.01) {
        final push = (minDist - dist) * 0.5;
        final dir = delta.normalized();
        worldPosition += dir * push;
      }
    }

    if (worldPosition.x < -mapMaxSize + circleRadius) {
      worldPosition.x = -mapMaxSize + circleRadius;
      velocity.x *= -1;
    }
    if (worldPosition.x > mapMaxSize - circleRadius) {
      worldPosition.x = mapMaxSize - circleRadius;
      velocity.x *= -1;
    }
    if (worldPosition.y < -mapMaxSize + circleRadius) {
      worldPosition.y = -mapMaxSize + circleRadius;
      velocity.y *= -1;
    }
    if (worldPosition.y > mapMaxSize - circleRadius) {
      worldPosition.y = mapMaxSize - circleRadius;
      velocity.y *= -1;
    }

    if (isBeingAttacked && dispatchedDiscipleImage != null) {
      dispatchedDisciplePos += dispatchedVelocity * dt;

      if (dispatchedDisciplePos.length < 6) {
        waveTimestamps.add(DateTime.now().millisecondsSinceEpoch);
        final randomAngle = Random().nextDouble() * pi * 2;
        dispatchedVelocity = Vector2(cos(randomAngle), sin(randomAngle)) * 250;
      }
      if (dispatchedDisciplePos.length > circleRadius * 1.0) {
        dispatchedVelocity = (-dispatchedDisciplePos).normalized() * 250;
      }
    }

    if (isBeingAttacked && expeditionEndTime != null) {
      final now = DateTime.now().millisecondsSinceEpoch;
      if (now >= expeditionEndTime!) {
        _triggerLevelUpAndReward();
      }
    }
  }

  void updateVisualPosition(Vector2 cameraOffset) {
    position = worldPosition - cameraOffset;
  }

  @override
  void render(ui.Canvas canvas) {
    super.render(canvas);

    final glowPaint = ui.Paint()
      ..color = const ui.Color(0x88FFFFFF)
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 8.0
      ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.outer, 12);
    canvas.drawCircle(
      ui.Offset(size.x / 2, size.y / 2),
      circleRadius,
      glowPaint,
    );

    final linePaint = ui.Paint()
      ..color = const ui.Color(0xFFFFFFFF)
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(
      ui.Offset(size.x / 2, size.y / 2),
      circleRadius,
      linePaint,
    );

    final src = ui.Rect.fromLTWH(
      0,
      0,
      image.width.toDouble(),
      image.height.toDouble(),
    );
    final dst = ui.Rect.fromCenter(
      center: ui.Offset(size.x / 2, size.y / 2),
      width: imageSize,
      height: imageSize,
    );
    canvas.drawImageRect(image, src, dst, ui.Paint());

    // 🌟第一行：宗门名
    final titleText = TextPainter(
      text: TextSpan(
        text: '${info.level}级·${info.name}',
        style: const TextStyle(
          color: Color(0xFFFFFFFF),
          fontSize: 14,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    titleText.paint(
      canvas,
      ui.Offset(
        (size.x - titleText.width) / 2,
        dst.top - 8,
      ),
    );

// 🌟第二行：讨伐中倒计时
    if (isBeingAttacked && expeditionEndTime != null) {
      final left = ((expeditionEndTime! - DateTime.now().millisecondsSinceEpoch) / 1000).ceil();
      final attackText = TextPainter(
        text: TextSpan(
          text: '讨伐中：${left}s',
          style: const TextStyle(
            color: Colors.red,
            fontSize: 12,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      attackText.paint(
        canvas,
        ui.Offset(
          (size.x - attackText.width) / 2,
          dst.top - 24, // 比宗门名字更上面
        ),
      );
    }

    if (isBeingAttacked && dispatchedDiscipleImage != null) {
      final dispatchedDst = ui.Rect.fromCenter(
        center: ui.Offset(
          size.x / 2 + dispatchedDisciplePos.x,
          size.y / 2 + dispatchedDisciplePos.y,
        ),
        width: dispatchedDiscipleImage!.width * 0.05,
        height: dispatchedDiscipleImage!.height * 0.05,
      );
      canvas.drawImageRect(
        dispatchedDiscipleImage!,
        ui.Rect.fromLTWH(
          0,
          0,
          dispatchedDiscipleImage!.width.toDouble(),
          dispatchedDiscipleImage!.height.toDouble(),
        ),
        dispatchedDst,
        ui.Paint(),
      );

      final now = DateTime.now().millisecondsSinceEpoch;
      waveTimestamps.removeWhere((t) => now - t > 1000);
      for (final t in waveTimestamps) {
        final age = (now - t) / 1000.0;
        final radius = age * (circleRadius + 10);
        final alpha = (1 - age).clamp(0.0, 1.0);
        final wavePaint = ui.Paint()
          ..color = ui.Color.fromARGB(
            (100 * alpha).toInt(),
            255,
            255,
            255,
          )
          ..style = ui.PaintingStyle.stroke
          ..strokeWidth = 2;
        canvas.drawCircle(
          ui.Offset(size.x / 2, size.y / 2),
          radius,
          wavePaint,
        );
      }
    }
  }
}
