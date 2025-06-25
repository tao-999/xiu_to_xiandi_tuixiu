import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class MonsterWaveInfo extends PositionComponent {
  int currentWave = 0;
  int totalWaves = 0;
  int currentTotal = 0;
  int currentAlive = 0;

  late TextComponent _text;

  MonsterWaveInfo({
    this.currentWave = 0,
    this.totalWaves = 0,
    this.currentTotal = 0,
    this.currentAlive = 0,
  }) : super(
    anchor: Anchor.topLeft,
    position: Vector2(8, 8),
    priority: 1000,
  );

  @override
  Future<void> onLoad() async {
    _text = TextComponent(
      text: _buildText(),
      anchor: Anchor.topLeft,
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 12,
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
    return '第 ${currentWave + 1} / $totalWaves 波\n'
        '怪物：$currentAlive / $currentTotal';
  }

  /// ✅ 每次刷新波次或怪物数时调用
  void updateInfo({
    required int waveIndex,
    required int waveTotal,
    required int alive,
    required int total,
  }) {
    currentWave = waveIndex;
    totalWaves = waveTotal;
    currentAlive = alive;
    currentTotal = total;

    _text.text = _buildText();
  }
}
