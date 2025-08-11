import 'package:flame/components.dart';
import 'package:flutter/foundation.dart' show debugPrint;

/// 控制“玩家贴图切换/朝向/缓存”的纯逻辑，不依赖你的游戏状态。
/// 用法：
///   final ctl = PlayerSpriteController(host: this, basePath: 'icon_youli_male.png');
///   await ctl.init(fixedWidth: 32);        // 首次加载并定宽
///   ctl.faceLeft(true);                    // 切换成左朝向（自动 _left.png）
///   ctl.setBasePath('icon_youli_female.png'); // 性别换装
class PlayerSpriteController {
  final SpriteComponent host;
  String basePath;               // 基础贴图（朝右）
  bool _facingLeft = false;
  final Map<String, Sprite> _cache = {};

  PlayerSpriteController({
    required this.host,
    required this.basePath,
  });

  bool get facingLeft => _facingLeft;

  /// 首次应用贴图；可指定固定宽度（默认 32）
  Future<void> init({bool keepSize = false, double fixedWidth = 32.0}) async {
    await _applySprite(
      left: false,
      keepSize: keepSize,
      fixedWidth: fixedWidth,
    );
  }

  /// 切换左右朝向；keepSize=true 表示不改 host.size（只换贴图）
  Future<void> faceLeft(bool left, {bool keepSize = true}) async {
    if (_facingLeft == left) return;
    await _applySprite(left: left, keepSize: keepSize);
  }

  /// 更换基础贴图（例如换性别/换皮），会按当前朝向重载
  Future<void> setBasePath(String newBase,
      {bool keepSize = true, double? fixedWidth}) async {
    if (newBase == basePath) return;
    basePath = newBase;
    await _applySprite(
      left: _facingLeft,
      keepSize: keepSize,
      fixedWidth: fixedWidth,
    );
  }

  // ===== 内部 =====

  Future<void> _applySprite({
    required bool left,
    required bool keepSize,
    double? fixedWidth,
  }) async {
    _facingLeft = left;
    final path = left ? _withLeftSuffix(basePath) : basePath;

    Sprite? sp = await _loadCached(path);
    // 左图可能不存在：回退到基础图
    sp ??= await _loadCached(basePath);
    if (sp == null) return;

    host.sprite = sp;

    if (!keepSize) {
      final src = sp.srcSize;
      final w = fixedWidth ?? 32.0;
      host.size = Vector2(w, src.y * (w / src.x));
    }
  }

  Future<Sprite?> _loadCached(String path) async {
    if (_cache.containsKey(path)) return _cache[path];
    try {
      final sp = await Sprite.load(path);
      _cache[path] = sp;
      return sp;
    } catch (e) {
      debugPrint('⚠️ Sprite 加载失败: $path -> $e');
      return null;
    }
  }

  String _withLeftSuffix(String base) {
    if (base.endsWith('.png')) {
      final i = base.lastIndexOf('.png');
      return '${base.substring(0, i)}_left.png';
    }
    return '${base}_left';
  }
}
