import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/game.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/lightning_effect_component.dart';

import '../../utils/number_format.dart';

class AutoBattleGame extends FlameGame {
  String playerEmojiOrIconPath;
  bool isAssetImage;
  int currentMapStage;

  AutoBattleGame({
    required this.playerEmojiOrIconPath,
    this.isAssetImage = false,
    this.currentMapStage = 1,
  });

  late PositionComponent player;
  final List<PositionComponent> enemies = [];
  final List<PositionComponent> enemiesToRemove = [];
  final Map<String, Sprite> _enemySpriteCache = {};
  final Random rng = Random();
  late Timer spawnTimer;
  late Timer attackTimer;
  late Timer clearWaveTimer;
  SpriteComponent? bg;

  @override
  Future<void> onLoad() async {
    add(
      FpsTextComponent()
        ..anchor = Anchor.topLeft
        ..position = Vector2(10, 10),
    );

    await _loadMap(currentMapStage);

    await _preloadEnemySprites();

    player = await _loadPlayer();
    add(player);

    spawnTimer = Timer(1.5, repeat: true, onTick: () async {
      if (currentMapStage < 22) {
        for (int i = 0; i < 2; i++) {
          await _spawnEnemy();
        }
      }
    })..start();

    attackTimer = Timer(1.0, repeat: true, onTick: _fireProjectile)..start();
    clearWaveTimer = Timer(30.0, repeat: true, onTick: _clearAllEnemies)..start();
  }

  Future<void> _preloadEnemySprites() async {
    final stages = [1, 4, 7];
    for (var stage in stages) {
      for (var i = 1; i <= 5; i++) {
        final path = 'assets/images/enemies/enemy_stage${stage}_$i.png';
        if (!_enemySpriteCache.containsKey(path)) {
          final img = await images.load(path.replaceFirst('assets/images/', ''));
          _enemySpriteCache[path] = Sprite(img);
        }
      }
    }
  }

  void updatePlayerImage(String newPath, {bool assetImage = true}) async {
    player.removeFromParent();
    playerEmojiOrIconPath = newPath;
    isAssetImage = assetImage;

    final newPlayer = await _loadPlayer();
    player = newPlayer;
    add(player);
  }

  Future<PositionComponent> _loadPlayer() async {
    if (isAssetImage) {
      final imagePath = playerEmojiOrIconPath.replaceFirst('assets/images/', '');
      final image = await images.load(imagePath);
      final sprite = Sprite(image);
      const double targetWidth = 64;
      final double aspectRatio = image.height / image.width;
      final double targetHeight = targetWidth * aspectRatio;

      return SpriteComponent()
        ..sprite = sprite
        ..size = Vector2(targetWidth, targetHeight)
        ..anchor = Anchor.center
        ..position = size / 2;
    } else {
      return TextComponent(
        text: playerEmojiOrIconPath,
        textRenderer: TextPaint(style: const TextStyle(fontSize: 48)),
      )
        ..anchor = Anchor.center
        ..position = size / 2;
    }
  }

  Future<void> _loadMap(int stage) async {
    bg?.removeFromParent();

    String bgPath;
    if (stage >= 1 && stage <= 22) {
      bgPath = 'assets/images/hell_stage_$stage.webp';
    } else {
      bgPath = 'assets/images/hell_stage_default.webp';
    }

    final sprite = await Sprite.load(bgPath.replaceFirst('assets/images/', ''));
    final spriteSize = sprite.srcSize;

    final scaleX = size.x / spriteSize.x;
    final scaleY = size.y / spriteSize.y;
    final scale = scaleX > scaleY ? scaleX : scaleY;

    bg = SpriteComponent()
      ..sprite = sprite
      ..size = spriteSize * scale
      ..position = Vector2.zero()
      ..anchor = Anchor.topLeft
      ..priority = -1;

    add(bg!);
  }

  Future<void> _spawnEnemy() async {
    if (currentMapStage >= 22) return;

    final imagePath = _getEnemyImagePathByStage(currentMapStage);
    final sprite = await _loadEnemySprite(imagePath);

    final enemy = SpriteComponent()
      ..sprite = sprite
      ..size = Vector2.all(48)
      ..anchor = Anchor.center
      ..position = _randomSpawnAroundPlayer();

    add(enemy);
    enemies.add(enemy);
  }

  Vector2 _randomSpawnAroundPlayer() {
    final edge = rng.nextInt(4);
    double x, y;

    const double buffer = 30.0;
    final playerYLimit = player.position.y - 20;

    switch (edge) {
      case 0:
        x = -buffer;
        y = rng.nextDouble() * (size.y - playerYLimit) + playerYLimit;
        break;
      case 1:
        x = size.x + buffer;
        y = rng.nextDouble() * (size.y - playerYLimit) + playerYLimit;
        break;
      case 2:
        x = rng.nextDouble() * (size.x / 3);
        y = size.y + buffer;
        break;
      case 3:
        x = rng.nextDouble() * (size.x / 3) + (2 * size.x / 3);
        y = size.y + buffer;
        break;
      default:
        x = size.x / 2;
        y = size.y + buffer;
    }

    return Vector2(x, y);
  }

  String _getEnemyImagePathByStage(int stage) {
    final random = Random();
    if (stage <= 3) {
      return 'assets/images/enemies/enemy_stage1_${random.nextInt(5) + 1}.png';
    } else if (stage <= 6) {
      return 'assets/images/enemies/enemy_stage4_${random.nextInt(5) + 1}.png';
    } else {
      return 'assets/images/enemies/enemy_stage7_${random.nextInt(5) + 1}.png';
    }
  }

  Future<Sprite> _loadEnemySprite(String path) async {
    if (_enemySpriteCache.containsKey(path)) return _enemySpriteCache[path]!;
    final img = await images.load(path.replaceFirst('assets/images/', ''));
    final sprite = Sprite(img);
    _enemySpriteCache[path] = sprite;
    return sprite;
  }

  void _fireProjectile() {
    if (enemies.isEmpty) return;

    final count = currentMapStage.clamp(1, 5);

    final visibleEnemies = enemies.where((e) {
      final pos = e.position;
      return pos.x >= 0 && pos.x <= size.x && pos.y >= 0 && pos.y <= size.y - 60;
    }).toList();

    visibleEnemies.sort((a, b) =>
        player.position.distanceToSquared(a.position)
            .compareTo(player.position.distanceToSquared(b.position)));

    for (final target in visibleEnemies.take(count)) {
      final lightning = LightningEffectComponent(
        source: player.position.clone(),
        target: target.position.clone(),
        lifespan: 0.45,
        segments: 10,
        deviation: 15.0,
        color: Colors.white,
      );
      add(lightning);
      _applyHit(target);
    }
  }

  void _applyHit(PositionComponent target) {
    if (children.contains(target)) {
      final damageValue = BigInt.from(9) * BigInt.from(10).pow(currentMapStage - 1);
      _showDamageText(target.position, damage: damageValue);
      enemiesToRemove.add(target);
    }
  }

  void switchMap(int newStage) async {
    currentMapStage = newStage;
    for (final e in enemies) {
      e.removeFromParent();
    }
    enemies.clear();
    enemiesToRemove.clear();
    await _loadMap(newStage);
  }

  void _showDamageText(Vector2 pos, {BigInt? damage, String? text}) {
    final displayText = text ?? '-${formatAnyNumber(damage ?? BigInt.zero)}';

    final textComp = TextComponent(
      text: displayText,
      textRenderer: TextPaint(
        style: const TextStyle(fontSize: 16, color: Colors.white),
      ),
      position: pos.clone(),
      anchor: Anchor.center,
    );
    add(textComp);

    textComp.add(MoveByEffect(
      Vector2(0, -20),
      EffectController(duration: 0.6),
    ));

    Future.delayed(const Duration(milliseconds: 600), () {
      if (textComp.parent == this) {
        textComp.removeFromParent();
      }
    });
  }

  void _clearAllEnemies() {
    for (final enemy in List<PositionComponent>.from(enemies)) {
      if (children.contains(enemy)) {
        _showDamageText(enemy.position, text: '⚡');
        enemy.removeFromParent();
      }
    }
    enemies.clear();
  }

  void updateBattleSpeed(int stage) {
    currentMapStage = stage;
    final multiplier = stage.toDouble();
    final attackInterval = 1.0 / multiplier;
    final spawnInterval = 1.5 / multiplier;

    attackTimer.stop();
    attackTimer = Timer(attackInterval, repeat: true, onTick: _fireProjectile)..start();

    spawnTimer.stop();
    spawnTimer = Timer(spawnInterval, repeat: true, onTick: () async {
      if (currentMapStage < 22) {
        for (int i = 0; i < 2; i++) {
          await _spawnEnemy();
        }
      }
    })..start();
  }

  @override
  void update(double dt) {
    super.update(dt);
    spawnTimer.update(dt);
    attackTimer.update(dt);
    clearWaveTimer.update(dt);

    for (int i = 0; i < enemies.length; i++) {
      final enemy = enemies[i];
      final dir = (player.position - enemy.position).normalized();
      enemy.position += dir * 40 * dt;

      final distSquared = player.position.distanceToSquared(enemy.position);
      if (distSquared < 900) {
        _showDamageText(enemy.position, text: '💥');
        enemiesToRemove.add(enemy);
      }
    }

    for (final enemy in enemiesToRemove) {
      if (children.contains(enemy)) {
        enemy.removeFromParent();
      }
      enemies.remove(enemy);
    }
    enemiesToRemove.clear();
  }
}
