import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:xiu_to_xiandi_tuixiu/services/hell_service.dart';

class MonsterWaveInfo extends PositionComponent {
  int currentWave = 0;
  int totalWaves = 0;
  int currentTotal = 101; // ✅ 直接写死总数
  int currentAlive = 0;
  int spiritStoneReward = 0; // ✅ 新增字段

  late TextComponent _text;

  MonsterWaveInfo({
    this.currentWave = 0,
    this.totalWaves = 0,
    this.currentAlive = 0,
  }) : super(
    anchor: Anchor.topLeft,
    position: Vector2(8, 36),
    priority: 1000,
  );

  @override
  Future<void> onLoad() async {
    spiritStoneReward = await HellService.loadSpiritStoneReward();

    _text = TextComponent(
      text: _buildText(),
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

    add(_text);
  }

  String _buildText() {
    return '第 $currentWave / $totalWaves 波\n'
        '怪物：$currentAlive / $currentTotal\n'
        '累计：$spiritStoneReward 个中品灵石';
  }

  /// ✅ 每次刷新波次或怪物数时调用
  Future<void> updateInfo({
    required int waveIndex,
    required int waveTotal,
    required int alive,
  }) async {
    currentWave = waveIndex;
    totalWaves = waveTotal;
    currentAlive = alive;
    currentTotal = 101; // ✅ 强写死

    spiritStoneReward = await HellService.loadSpiritStoneReward();
    _text.text = _buildText();
  }
}
