import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:xiu_to_xiandi_tuixiu/services/hell_service.dart';
import 'package:xiu_to_xiandi_tuixiu/services/player_storage.dart';
import 'hell_monster_component.dart';

class MonsterWaveInfo extends PositionComponent {
  final FlameGame gameRef;
  final Map<int, List<HellMonsterComponent>> waves;

  int currentWave = 0;
  int totalWaves = 0;
  int currentTotal = 0;
  int currentAlive = 0;
  int spiritStoneReward = 0;

  late TextComponent _mainText;
  late TextComponent _powerText;

  MonsterWaveInfo({
    required this.gameRef,
    required this.waves,
    this.currentWave = 0,
    this.totalWaves = 0,
    this.currentAlive = 0,
    this.currentTotal = 0,
  }) : super(
    anchor: Anchor.topLeft,
    position: Vector2(8, 36),
    priority: 1000,
  );

  @override
  Future<void> onLoad() async {
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

    _powerText = TextComponent(
      text: '推荐战力：加载中...',
      anchor: Anchor.topLeft,
      position: Vector2(0, _mainText.size.y + 2),
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 10,
          color: Colors.grey,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(color: Colors.black, offset: Offset(1, 1), blurRadius: 2),
          ],
        ),
      ),
    );

    add(_powerText);

    await _refreshPowerText();
  }

  String _buildMainText() {
    return '第 $currentWave / $totalWaves 波\n'
        '怪物：$currentAlive / ${currentTotal + 1}\n'
        '累计：$spiritStoneReward 个中品灵石';
  }

  int _getRecommendedPower() {
    final waveMonsters = waves[currentWave]?.where((m) => !m.isBoss);
    if (waveMonsters == null || waveMonsters.isEmpty) return -1;
    return waveMonsters.first.power;
  }

  Future<void> _refreshPowerText() async {
    final recommendedPower = _getRecommendedPower();

    final player = await PlayerStorage.getPlayer();
    print('💡 推荐战力: $recommendedPower');
    print('💡 玩家: $player');

    if (recommendedPower <= 0) {
      _powerText.text = '推荐战力：未知';
      _powerText.textRenderer = TextPaint(
        style: const TextStyle(
          fontSize: 10,
          color: Colors.grey,
          fontWeight: FontWeight.bold,
        ),
      );
      return;
    }

    if (player == null) {
      _powerText.text = '推荐战力：$recommendedPower';
      _powerText.textRenderer = TextPaint(
        style: const TextStyle(
          fontSize: 10,
          color: Colors.grey,
          fontWeight: FontWeight.bold,
        ),
      );
      return;
    }

    final playerPower = PlayerStorage.getPower(player);
    print('💡 玩家战力: $playerPower');

    final isHigher = playerPower > recommendedPower;
    final color = isHigher ? Colors.green : Colors.red;

    _powerText.text = '推荐战力：$recommendedPower';
    _powerText.textRenderer = TextPaint(
      style: TextStyle(
        fontSize: 10,
        color: color,
        fontWeight: FontWeight.bold,
        shadows: const [
          Shadow(color: Colors.black, offset: Offset(1, 1), blurRadius: 2),
        ],
      ),
    );
  }

  Future<void> updateInfo({
    required int waveIndex,
    required int waveTotal,
    required int alive,
    required int total,
  }) async {
    currentWave = waveIndex;
    totalWaves = waveTotal;
    currentAlive = alive;
    currentTotal = total;

    spiritStoneReward = await HellService.loadSpiritStoneReward();

    if (!_mainText.isMounted) return;

    _mainText.text = _buildMainText();

    if (_powerText.isMounted) {
      await _refreshPowerText();
      _powerText.position = Vector2(0, _mainText.size.y + 2);
    }
  }
}
