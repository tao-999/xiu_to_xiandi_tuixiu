import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:xiu_to_xiandi_tuixiu/services/hell_service.dart';

class MonsterWaveInfo extends PositionComponent {
  final FlameGame gameRef;
  final int currentTotal; // 怪物总数
  int killedCount = 0;    // 只由外部 updateInfo 控制
  int spiritStoneReward = 0;
  late TextComponent _mainText;

  MonsterWaveInfo({
    required this.gameRef,
    required this.currentTotal,
  }) : super(
    anchor: Anchor.topLeft,
    position: Vector2(8, 36),
    priority: 1000,
  );

  @override
  Future<void> onLoad() async {
    // 这里不赋 killedCount！只展示UI！
    spiritStoneReward = await HellService.loadSpiritStoneReward();
    _mainText = TextComponent(
      text: _buildMainText(),
      anchor: Anchor.topLeft,
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 10,
          color: Colors.white,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(color: Colors.black, offset: Offset(1, 1), blurRadius: 2),
          ],
        ),
      ),
    );
    add(_mainText);
    await _mainText.onLoad();
    _mainText.text = _buildMainText();
  }

  String _buildMainText() {
    return '怪物：$killedCount / $currentTotal\n'
        '累计：$spiritStoneReward 个中品灵石';
  }

  /// 只由 Manager 调用，不自增，只赋值和刷UI
  Future<void> updateInfo(int killed, {int? rewardOverride}) async {
    killedCount = killed;
    if (rewardOverride != null) {
      spiritStoneReward = rewardOverride;
    } else {
      spiritStoneReward = await HellService.loadSpiritStoneReward();
    }

    if (_mainText.isMounted) {
      _mainText.text = _buildMainText();
    }
  }

  /// 新关卡/重置，归零并清空本地存储
  Future<void> resetKillCount() async {
    killedCount = 0;
    await HellService.saveState(killed: 0, bossSpawned: false, spawned: 0);
    if (_mainText.isMounted) {
      _mainText.text = _buildMainText();
    }
  }
}
