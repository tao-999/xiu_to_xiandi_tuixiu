// 📂 lib/widgets/effects/airflow_player_adapter.dart
import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:flame/game.dart';                // 可见区域
import 'package:flutter/material.dart';

import 'vfx_airflow.dart';
import 'package:xiu_to_xiandi_tuixiu/services/player_storage.dart';
import 'package:xiu_to_xiandi_tuixiu/services/gongfa_equip_storage.dart';
import 'package:xiu_to_xiandi_tuixiu/data/movement_gongfa_data.dart';
import 'package:xiu_to_xiandi_tuixiu/models/gongfa.dart';

class PlayerAirflowAdapter extends Component with HasGameReference {
  final SpriteComponent host;
  final Vector2 Function() getLogicalPosition;

  AirFlowEffect? _fx;

  // —— 性能参数（按需微调）——
  static const double _speedOffThreshold = 22.0;   // 低于此速度完全熄火（px/s）
  static const double _epsVelUpdate      = 6.0;    // 速度变化小于此值时跳过更新
  static const double _offscreenPad      = 96.0;   // 离屏裁剪的可视缓冲
  static const double _pollInterval      = 0.75;   // 轮询装备间隔
  static const double _bigDtReset        = 0.12;   // 大卡顿直接对齐，避免尖峰

  // —— 复用向量，避免分配 —— //
  final Vector2 _lastPos = Vector2.zero();
  final Vector2 _vel     = Vector2.zero();
  final Vector2 _lastFed = Vector2.zero();         // 最近一次喂给 FX 的速度

  // —— 装备状态缓存 & 轮询 —— //
  String? _playerId;
  String? _equippedName; // 当前已应用到特效的功法名
  double _pollTimer = 0.0;
  bool   _pollBusy  = false; // 防并发

  PlayerAirflowAdapter._({
    required this.host,
    required this.getLogicalPosition,
  });

  static PlayerAirflowAdapter attach({
    required SpriteComponent host,
    required Vector2 Function() logicalPosition,
  }) {
    final a = PlayerAirflowAdapter._(host: host, getLogicalPosition: logicalPosition);
    (host.parent ?? host).add(a);
    return a;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    await _ensureEffectCreatedOrUpdated();
    _lastPos.setFrom(getLogicalPosition()); // 避免第1帧速度尖峰
  }

  @override
  void update(double dt) {
    super.update(dt);

    // —— 定期轮询装备（防并发）—— //
    _pollTimer += dt;
    if (_pollTimer >= _pollInterval) {
      _pollTimer = 0;
      _ensureEffectCreatedOrUpdated(); // 内部自己有 busy 锁
    }

    final fx = _fx;
    if (fx == null) return; // 未装备速度功法

    // —— 大卡顿：对齐位置并熄火，防止速度尖峰 —— //
    if (dt <= 0) return;
    if (dt > _bigDtReset) {
      _lastPos.setFrom(getLogicalPosition());
      fx.enabled = false;
      _vel.setZero();
      _lastFed.setZero();
      return;
    }

    // —— 计算当前速度 —— //
    final cur = getLogicalPosition();
    _vel
      ..setFrom(cur)
      ..sub(_lastPos)
      ..scale(1.0 / dt);

    // —— 离屏裁剪（不在相机可见范围就不画）—— //
    if (game is FlameGame) {
      final camRect = (game as FlameGame).camera.visibleWorldRect.inflate(_offscreenPad);
      final worldPos = host.absoluteCenter; // 比 absolutePosition 更贴近中心
      if (!camRect.containsPoint(worldPos)) {
        fx.enabled = false;
        _lastPos.setFrom(cur);
        return;
      }
    }

    // —— 静止/慢速：熄火直接返回 —— //
    final speed = _vel.length;
    if (speed < _speedOffThreshold) {
      fx.enabled = false;
      _lastPos.setFrom(cur);
      return;
    }

    // —— 速度变化很小：跳过一次喂值，减少无用更新 —— //
    final deltaVel = (_vel - _lastFed).length;
    if (deltaVel < _epsVelUpdate) {
      // 仍保持点亮，但不重复喂
      fx.enabled = true;
      _lastPos.setFrom(cur);
      return;
    }

    // —— 正常点亮并更新向量 —— //
    fx.enabled = true;
    fx.moveVector = _vel;
    _lastFed.setFrom(_vel);
    _lastPos.setFrom(cur);
  }

  @override
  void onRemove() {
    _fx?.removeFromParent();
    _fx = null;
    super.onRemove();
  }

  // ========================
  // 内部：装备检测 / 特效创建
  // ========================

  Future<void> _ensureEffectCreatedOrUpdated() async {
    if (_pollBusy) return;         // 🔒 防并发
    _pollBusy = true;
    try {
      _playerId ??= (await PlayerStorage.getPlayer())?.id;
      final pid = _playerId;
      if (pid == null) return;

      final Gongfa? equipped = await GongfaEquipStorage.loadEquippedMovementBy(pid);

      if (equipped == null) {
        if (_fx != null) {
          _fx!.removeFromParent();
          _fx = null;
          _equippedName = null;
        }
        return;
      }

      // 找模板 → palette
      final tpl = MovementGongfaData.byName(equipped.name);
      final palette = tpl?.palette ?? const [Colors.white];

      // 名称没变且已有特效：直接复用
      if (_fx != null && _equippedName == equipped.name) return;

      // 重建特效（Release 关闭 debug 绘制）
      _fx?.removeFromParent();
      _fx = AirFlowEffect(
        getWorldCenter: () => host.absoluteCenter,
        getHostSize: () => host.size,
        palette: palette,
        mixMode: ColorMixMode.hsv,
        baseRate: 160,
        ringRadius: 12,
        centerYFactor: 0.50,
        radiusFactor: 0.46,
        pad: 1.8,
        arcHalfAngle: pi / 12,
        biasLeftX: 0.0,
        biasRightX: 0.0,
        // 🚫 Release 关闭/降级 Debug 项（它们每帧都有绘制开销）
        debugArcColor: Colors.transparent,
        debugArcWidth: 0.0,
        debugArcSamples: 24,
      );
      (host.parent ?? parent)?.add(_fx!);
      _equippedName = equipped.name;
    } finally {
      _pollBusy = false;
    }
  }
}
