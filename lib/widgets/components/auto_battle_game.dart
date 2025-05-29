import 'package:flutter/material.dart'; // 必须要这个！🔥
import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/game.dart';

class AutoBattleGame extends FlameGame {
  final String playerEmojiOrIconPath;
  final bool isAssetImage;
  int currentMapStage;

  AutoBattleGame({
    required this.playerEmojiOrIconPath,
    this.isAssetImage = false,
    this.currentMapStage = 1,
  });

  late PositionComponent player;
  final List<TextComponent> enemies = [];
  final List<TextComponent> enemiesToRemove = [];
  final Random rng = Random();
  late Timer spawnTimer;
  late Timer attackTimer;
  SpriteComponent? bg;
  RectangleComponent? mask;

  @override
  Future<void> onLoad() async {
    await _loadMap(currentMapStage);

    // 加载角色
    if (isAssetImage) {
      player = SpriteComponent()
        ..sprite = await Sprite.load(
          playerEmojiOrIconPath.replaceFirst('assets/images/', ''),
        )
        ..size = Vector2.all(128)
        ..anchor = Anchor.center
        ..position = size / 2;
    } else {
      player = TextComponent(
        text: playerEmojiOrIconPath,
        textRenderer: TextPaint(style: const TextStyle(fontSize: 48)),
      )
        ..anchor = Anchor.center
        ..position = size / 2;
    }

    add(player);

    spawnTimer = Timer(1.5, repeat: true, onTick: () {
      for (int i = 0; i < 2; i++) {
        _spawnEnemy();
      }
    })..start();

    attackTimer = Timer(1.0, repeat: true, onTick: _fireProjectile)..start();
  }

  double getEffectDuration(double base) => base / currentMapStage.clamp(1, 9);

  Future<void> _loadMap(int stage) async {
    bg?.removeFromParent();
    mask?.removeFromParent();

    bg = SpriteComponent()
      ..sprite = await Sprite.load('hell_background_compressed.jpg')
      ..size = size
      ..position = Vector2.zero()
      ..anchor = Anchor.topLeft
      ..priority = -1;
    add(bg!);

    mask = RectangleComponent(
      size: size,
      position: Vector2.zero(),
      paint: Paint()..color = const Color(0xFFDFCCAA).withOpacity(0.5),
    )
      ..anchor = Anchor.topLeft
      ..priority = 0;
    add(mask!);
  }

  void switchMap(int newStage) async {
    currentMapStage = newStage;
    await _loadMap(newStage);
  }

  List<String> _getMonsterEmojisByStage(int stage) {
    if (stage <= 3) {
      return ['🦙', '🐛', '🐍', '🐢', '🐸'];
    } else if (stage <= 6) {
      return ['💀', '👺', '🧌', '🦂', '🧟‍♂️'];
    } else {
      return ['🐲', '🐉', '🧟‍♀️', '🦠', '🐙'];
    }
  }

  void _spawnEnemy() {
    final emojiList = _getMonsterEmojisByStage(currentMapStage);
    final emoji = emojiList[rng.nextInt(emojiList.length)];

    final enemy = TextComponent(
      text: emoji,
      textRenderer: TextPaint(style: const TextStyle(fontSize: 36)),
    )
      ..anchor = Anchor.center
      ..position = _randomSpawnOutside();

    add(enemy);
    enemies.add(enemy);
  }

  Vector2 _randomSpawnOutside() {
    final edge = rng.nextInt(4);
    double x, y;

    switch (edge) {
      case 0:
        x = rng.nextDouble() * size.x;
        y = -30;
        break;
      case 1:
        x = rng.nextDouble() * size.x;
        y = size.y + 30;
        break;
      case 2:
        x = -30;
        y = rng.nextDouble() * size.y;
        break;
      default:
        x = size.x + 30;
        y = rng.nextDouble() * size.y;
        break;
    }

    return Vector2(x, y);
  }

  void _fireProjectile() {
    if (enemies.isEmpty) return;
    final target = enemies.first;

    final effects = [
      _buildFlyingSword,
      _buildSpinningBlade,
      _buildFireball,
      _buildIceArrow,
      _buildTornadoWave,
      _buildQiBlast,
      _buildMeteorStrike,
    ];

    final effectBuilder = effects[rng.nextInt(effects.length)];
    final projectile = effectBuilder(target);
    add(projectile);
  }

  TextComponent _buildFlyingSword(PositionComponent target) {
    final comp = TextComponent(
      text: '🗡️',
      textRenderer: TextPaint(style: const TextStyle(fontSize: 24)),
      anchor: Anchor.center,
      position: player.position.clone(),
    );

    comp.add(MoveEffect.to(
      target.position,
      EffectController(duration: getEffectDuration(0.4)),
      onComplete: () => _applyHit(comp, target),
    ));
    return comp;
  }

  TextComponent _buildSpinningBlade(PositionComponent target) {
    final comp = TextComponent(
      text: '🌀',
      textRenderer: TextPaint(style: const TextStyle(fontSize: 24)),
      anchor: Anchor.center,
      position: player.position.clone(),
    );

    comp.add(RotateEffect.by(3.14 * 4, EffectController(duration: getEffectDuration(0.4))));
    comp.add(MoveEffect.to(
      target.position,
      EffectController(duration: getEffectDuration(0.4)),
      onComplete: () => _applyHit(comp, target),
    ));
    return comp;
  }

  TextComponent _buildFireball(PositionComponent target) {
    final comp = TextComponent(
      text: '🔥',
      textRenderer: TextPaint(style: const TextStyle(fontSize: 26)),
      anchor: Anchor.center,
      position: player.position.clone(),
    );

    comp.add(ScaleEffect.to(Vector2.all(1.5), EffectController(duration: 0.2)));
    comp.add(MoveEffect.to(
      target.position,
      EffectController(duration: getEffectDuration(0.4), curve: Curves.easeIn),
      onComplete: () => _applyHit(comp, target),
    ));
    return comp;
  }

  TextComponent _buildIceArrow(PositionComponent target) {
    final comp = TextComponent(
      text: '❄️',
      textRenderer: TextPaint(style: const TextStyle(fontSize: 22)),
      anchor: Anchor.center,
      position: player.position.clone(),
    );

    comp.add(MoveEffect.to(
      target.position,
      EffectController(duration: getEffectDuration(0.8)),
      onComplete: () => _applyHit(comp, target),
    ));
    return comp;
  }

  TextComponent _buildTornadoWave(PositionComponent target) {
    final comp = TextComponent(
      text: '🌪️',
      textRenderer: TextPaint(style: const TextStyle(fontSize: 24)),
      anchor: Anchor.center,
      position: player.position.clone(),
    );

    comp.add(ScaleEffect.to(Vector2.all(2.0), EffectController(duration: 0.4)));
    comp.add(MoveEffect.to(
      target.position,
      EffectController(duration: getEffectDuration(0.4)),
      onComplete: () => _applyHit(comp, target),
    ));
    return comp;
  }

  TextComponent _buildQiBlast(PositionComponent target) {
    final comp = TextComponent(
      text: '💥',
      textRenderer: TextPaint(style: const TextStyle(fontSize: 26)),
      anchor: Anchor.center,
      position: player.position.clone(),
    );

    comp.add(ScaleEffect.by(Vector2.all(1.3), EffectController(duration: 0.2)));
    comp.add(MoveEffect.to(
      target.position,
      EffectController(duration: getEffectDuration(0.3)),
      onComplete: () => _applyHit(comp, target),
    ));
    return comp;
  }

  TextComponent _buildMeteorStrike(PositionComponent target) {
    final comp = TextComponent(
      text: '☄️',
      textRenderer: TextPaint(style: const TextStyle(fontSize: 28)),
      anchor: Anchor.center,
      position: Vector2(target.position.x, -50),
    );

    comp.add(MoveEffect.to(
      target.position,
      EffectController(duration: getEffectDuration(0.5), curve: Curves.easeOut),
      onComplete: () => _applyHit(comp, target),
    ));
    return comp;
  }

  void _applyHit(PositionComponent projectile, PositionComponent target) {
    if (children.contains(target)) {
      _showDamageText(target.position, damage: 999);
      enemiesToRemove.add(target as TextComponent);
    }
    projectile.removeFromParent();
  }

  void _showDamageText(Vector2 pos, {required int damage, String? text}) {
    final textComp = TextComponent(
      text: text ?? '-$damage',
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

  void _explodeEnemy(TextComponent enemy) {
    if (children.contains(enemy)) {
      _showDamageText(enemy.position, damage: 0, text: '💥');
      if (!enemiesToRemove.contains(enemy)) {
        enemiesToRemove.add(enemy);
      }
    }
  }

  void updateBattleSpeed(int stage) {
    currentMapStage = stage;

    final multiplier = stage.toDouble();
    final attackInterval = 1.0 / multiplier;
    final spawnInterval = 1.5 / multiplier;

    attackTimer.stop();
    attackTimer = Timer(attackInterval, repeat: true, onTick: _fireProjectile)..start();

    spawnTimer.stop();
    spawnTimer = Timer(spawnInterval, repeat: true, onTick: () {
      for (int i = 0; i < 2; i++) {
        _spawnEnemy();
      }
    })..start();

    debugPrint("⚔️ 攻速间隔: ${attackInterval.toStringAsFixed(2)}s, 👹 刷怪间隔: ${spawnInterval.toStringAsFixed(2)}s");
  }

  @override
  void update(double dt) {
    super.update(dt);
    spawnTimer.update(dt);
    attackTimer.update(dt);

    for (final enemy in List<TextComponent>.from(enemies)) {
      final dir = (player.position - enemy.position).normalized();
      enemy.position += dir * 40 * dt;

      final distance = player.position.distanceTo(enemy.position);
      if (distance < 30) {
        _explodeEnemy(enemy);
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
