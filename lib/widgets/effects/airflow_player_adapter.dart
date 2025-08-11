// 📂 lib/widgets/effects/airflow_player_adapter.dart
import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import 'vfx_airflow.dart';
import 'package:xiu_to_xiandi_tuixiu/services/player_storage.dart';
import 'package:xiu_to_xiandi_tuixiu/services/gongfa_equip_storage.dart';
import 'package:xiu_to_xiandi_tuixiu/data/movement_gongfa_data.dart';
import 'package:xiu_to_xiandi_tuixiu/models/gongfa.dart';

class PlayerAirflowAdapter extends Component {
  final SpriteComponent host;
  final Vector2 Function() getLogicalPosition;

  AirFlowEffect? _fx;

  // ✅ 复用向量，避免每帧分配
  final Vector2 _lastPos = Vector2.zero();
  final Vector2 _vel     = Vector2.zero();

  // ✅ 装备状态缓存 & 轮询
  String? _playerId;
  String? _equippedName; // 当前已应用到特效的功法名
  double _pollTimer = 0.0;
  final double _pollInterval = 0.75; // 秒：减少存取频率

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
    // 首次尝试创建（若未装备速度功法，将不会创建 _fx）
    await _ensureEffectCreatedOrUpdated();
    // 拷贝初始位置，避免第一帧速度尖峰
    _lastPos.setFrom(getLogicalPosition());
  }

  @override
  void update(double dt) {
    super.update(dt);

    // —— 定期轮询：装备切换后自动更新特效 —— //
    _pollTimer += dt;
    if (_pollTimer >= _pollInterval) {
      _pollTimer = 0;
      // 异步，不阻塞本帧
      _ensureEffectCreatedOrUpdated();
    }

    final fx = _fx;
    if (fx == null) {
      // 未装备速度功法 → 不渲染特效，直接溜了
      return;
    }

    // —— 速度计算（零分配）—— //
    if (dt <= 0) return;
    if (dt > 0.1) { // >100ms 直接重对齐，避免速度尖峰
      _lastPos.setFrom(getLogicalPosition());
      fx.enabled = true;
      _vel.setZero();
      fx.moveVector = _vel;
      return;
    }

    final cur = getLogicalPosition();
    _vel
      ..setFrom(cur)
      ..sub(_lastPos)
      ..scale(1.0 / dt);

    fx.enabled = true;
    fx.moveVector = _vel;

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
    // 拉玩家与当前已装备的“速度功法”
    _playerId ??= (await PlayerStorage.getPlayer())?.id;
    final pid = _playerId;
    if (pid == null) return;

    final Gongfa? equipped = await GongfaEquipStorage.loadEquippedMovementBy(pid);

    if (equipped == null) {
      // 没有装备速度功法：如果之前有特效，则移除；否则静默
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

    // 若名称没变且已有特效，保持不动（避免反复销毁重建）
    if (_fx != null && _equippedName == equipped.name) {
      return;
    }

    // 名称改变或首次创建 → 重建特效（AirFlowEffect 构造参数多，直接替换最稳妥）
    _fx?.removeFromParent();
    _fx = AirFlowEffect(
      getWorldCenter: () => host.absolutePosition,
      getHostSize: () => host.size,
      palette: palette,                 // 🎨 使用功法模板的颜色序列
      mixMode: ColorMixMode.hsv,
      baseRate: 170,
      ringRadius: 12,
      centerYFactor: 0.50,
      radiusFactor: 0.46,
      pad: 1.8,
      arcHalfAngle: pi / 12,
      biasLeftX: 0.0,
      biasRightX: 0.0,
      // 发布版建议关掉这些 debug 项
      debugArcColor: const Color(0xFFFF00FF),
      debugArcWidth: 1.5,
      debugArcSamples: 48,
    );
    (host.parent ?? parent)?.add(_fx!);
    _equippedName = equipped.name;
  }
}
