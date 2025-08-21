// fbm_terrain_layer.dart
import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

enum Biome { snow, grass, rock, forest, flower, shallow, beach, volcanic }

class FbmTerrainLayer extends PositionComponent {
  final Vector2 Function() getViewSize;
  final double  Function() getViewScale;
  final Vector2 Function() getLogicalOffset;
  final Vector2 Function() getWorldBase;

  double frequency;
  int    octaves;
  double persistence;
  final  int seed;
  bool   animate;

  bool   useLodAdaptive;
  double lodNyquist;

  bool   debugLogUniforms;
  double debugLevel;

  double periodSnow;
  double periodGrass;
  double periodRock;
  double periodForest;
  double periodFlower;
  double periodShallow;
  double periodBeach;
  double periodVolcanic;

  // 纹理路径（为空=纯色）
  final List<String> snowPaths;
  final List<String> grassPaths;
  final List<String> rockPaths;
  final List<String> forestPaths;
  final List<String> flowerPaths;
  final List<String> shallowPaths;
  final List<String> beachPaths;
  final List<String> volcanicPaths;

  static ui.FragmentProgram? _cachedProgram;
  ui.FragmentShader? _shader;

  ui.Image? _perm1, _perm2, _perm3;

  // ===== 单图集（安全热替换）=====
  ui.Image? _atlas;        // 当前在用（shader: uAtlasA，sampler=3）
  ui.Image? _nextAtlas;    // 下帧交换
  final List<ui.Image> _recycleBin = []; // 帧末统一销毁

  ui.Image? _placeholder; // 初始占位（2x2）

  int _atlasCols = 1;
  int _atlasRows = 1;

  final Map<Biome, int> _varOffset = { for (final b in Biome.values) b: 0 };
  final Map<Biome, int> _varCount  = { for (final b in Biome.values) b: 0 };

  double _t = 0.0;
  double _logTimer = 0.0;

  final Paint _paint = Paint();
  final Paint _fallback = Paint()..color = const Color(0xFF0B0B0B);

  FbmTerrainLayer({
    required this.getViewSize,
    required this.getViewScale,
    required this.getLogicalOffset,
    required this.getWorldBase,
    this.frequency   = 0.004,
    this.octaves     = 6,
    this.persistence = 0.6,
    this.seed        = 1337,
    this.animate     = true,
    this.useLodAdaptive = true,
    this.lodNyquist     = 0.5,
    this.debugLogUniforms = false,
    this.debugLevel       = 0.0,
    this.periodSnow     = 125.0,
    this.periodGrass    = 125.0,
    this.periodRock     = 125.0,
    this.periodForest   = 125.0,
    this.periodFlower   = 125.0,
    this.periodShallow  = 125.0,
    this.periodBeach    = 125.0,
    this.periodVolcanic = 125.0,
    this.snowPaths     = const [],
    this.grassPaths    = const [],
    this.rockPaths     = const [],
    this.forestPaths   = const [],
    this.flowerPaths   = const [],
    this.shallowPaths  = const [],
    this.beachPaths    = const [],
    this.volcanicPaths = const [],
    int? priority,
  }) : super(priority: priority ?? -10000);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    try {
      _placeholder = await _makeSolidImage(const Color(0xFF000000));
      _atlas = _placeholder;

      _cachedProgram ??= await ui.FragmentProgram.fromAsset('shaders/fbm_terrain.frag');
      _shader = _cachedProgram!.fragmentShader();

      _perm1 = await _buildPermImage(_makePerm(seed));
      _perm2 = await _buildPermImage(_makePerm(seed + 999));
      _perm3 = await _buildPermImage(_makePerm(seed - 999));

      await _buildAtlas(); // 生成首个图集，结果放到 _nextAtlas，首帧交换
    } catch (e, st) {
      debugPrint('[FbmTerrainLayer] init failed: $e\n$st');
      _shader = null;
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (animate) _t += dt;
    if (debugLogUniforms) _logTimer += dt;
  }

  @override
  void render(Canvas canvas) {
    final screen = getViewSize();
    final scale  = getViewScale();
    final center = getLogicalOffset();
    final base   = getWorldBase();
    final rect = Rect.fromLTWH(0, 0, screen.x, screen.y);

    // ===== 帧首交换（原子替换）=====
    if (_nextAtlas != null) {
      final old = _atlas;
      _atlas = _nextAtlas;
      _nextAtlas = null;
      if (old != null && !identical(old, _atlas)) {
        _recycleBin.add(old); // 帧末销毁
      }
    }

    // 帧内快照
    final s  = _shader;
    final p1 = _perm1;
    final p2 = _perm2;
    final p3 = _perm3;
    final a  = _atlas;

    if (s == null || p1 == null || p2 == null || p3 == null || a == null) {
      canvas.drawRect(rect, _fallback);
      _disposeRecycleBinIfAny();
      return;
    }

    try {
      final worldSize    = screen / scale;
      final worldTopLeft = center - worldSize / 2;

      s.setFloat(0,  screen.x);
      s.setFloat(1,  screen.y);
      s.setFloat(2,  worldTopLeft.x);
      s.setFloat(3,  worldTopLeft.y);
      s.setFloat(4,  scale);
      s.setFloat(5,  frequency);
      s.setFloat(6,  animate ? _t : 0.0);
      s.setFloat(7,  octaves.clamp(1, 8).toDouble());
      s.setFloat(8,  persistence);
      s.setFloat(9,  seed.toDouble());
      s.setFloat(10, debugLevel);
      s.setFloat(11, useLodAdaptive ? 1.0 : 0.0);
      s.setFloat(12, lodNyquist);
      s.setFloat(13, base.x);
      s.setFloat(14, base.y);

      s.setFloat(15, periodSnow);
      s.setFloat(16, periodGrass);
      s.setFloat(17, periodRock);
      s.setFloat(18, periodForest);
      s.setFloat(19, periodFlower);
      s.setFloat(20, periodShallow);
      s.setFloat(21, periodBeach);
      s.setFloat(22, periodVolcanic);

      for (int i = 23; i <= 30; i++) { s.setFloat(i, 0.0); }

      s.setFloat(31, _atlasCols.toDouble());
      s.setFloat(32, _atlasRows.toDouble());
      s.setFloat(33, a.width.toDouble());
      s.setFloat(34, a.height.toDouble());

      s.setFloat(35, _varOffset[Biome.snow]!.toDouble());
      s.setFloat(36, _varOffset[Biome.grass]!.toDouble());
      s.setFloat(37, _varOffset[Biome.rock]!.toDouble());
      s.setFloat(38, _varOffset[Biome.forest]!.toDouble());
      s.setFloat(39, _varOffset[Biome.flower]!.toDouble());
      s.setFloat(40, _varOffset[Biome.shallow]!.toDouble());
      s.setFloat(41, _varOffset[Biome.beach]!.toDouble());
      s.setFloat(42, _varOffset[Biome.volcanic]!.toDouble());

      s.setFloat(43, _varCount[Biome.snow]!.toDouble());
      s.setFloat(44, _varCount[Biome.grass]!.toDouble());
      s.setFloat(45, _varCount[Biome.rock]!.toDouble());
      s.setFloat(46, _varCount[Biome.forest]!.toDouble());
      s.setFloat(47, _varCount[Biome.flower]!.toDouble());
      s.setFloat(48, _varCount[Biome.shallow]!.toDouble());
      s.setFloat(49, _varCount[Biome.beach]!.toDouble());
      s.setFloat(50, _varCount[Biome.volcanic]!.toDouble());

      for (int i = 51; i <= 66; i++) { s.setFloat(i, 0.0); }

      // ===== samplers（注意索引：perm1=0, perm2=1, perm3=2, atlasA=3）=====
      s.setImageSampler(0, p1);
      s.setImageSampler(1, p2);
      s.setImageSampler(2, p3);
      s.setImageSampler(3, a);

      _paint.shader = s;
      canvas.drawRect(rect, _paint);
    } catch (e, st) {
      debugPrint('[FbmTerrainLayer] render failed: $e\n$st');
      canvas.drawRect(rect, _fallback);
    } finally {
      _disposeRecycleBinIfAny();
    }
  }

  void _disposeRecycleBinIfAny() {
    if (_recycleBin.isEmpty) return;
    for (final img in _recycleBin) {
      try { img.dispose(); } catch (_) {}
    }
    _recycleBin.clear();
  }

  @override
  void onRemove() {
    _disposeRecycleBinIfAny();

    _perm1?.dispose(); _perm1 = null;
    _perm2?.dispose(); _perm2 = null;
    _perm3?.dispose(); _perm3 = null;

    _atlas?.dispose(); _atlas = null;
    _nextAtlas?.dispose(); _nextAtlas = null;
    _placeholder?.dispose(); _placeholder = null;

    super.onRemove();
  }

  // ===== util =====
  List<int> _makePerm(int seed) {
    final rnd = math.Random(seed);
    final list = List<int>.generate(256, (i) => i)..shuffle(rnd);
    return list;
  }

  Future<ui.Image> _buildPermImage(List<int> perm) async {
    final recorder = ui.PictureRecorder();
    final c = Canvas(recorder);
    for (int i = 0; i < 256; i++) {
      final v = perm[i].clamp(0, 255);
      c.drawRect(Rect.fromLTWH(i.toDouble(), 0, 1, 1),
          Paint()..color = Color.fromARGB(0xFF, v, 0, 0));
    }
    final pic = recorder.endRecording();
    return pic.toImage(256, 1);
  }

  Future<ui.Image> _loadUiImageFromAsset(String assetPath) async {
    final data = await rootBundle.load(assetPath);
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  Future<ui.Image> _makeSolidImage(Color color, {int size = 2}) async {
    final recorder = ui.PictureRecorder();
    final c = Canvas(recorder);
    c.drawRect(Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble()),
        Paint()..color = color);
    final pic = recorder.endRecording();
    return pic.toImage(size, size);
  }

  Future<void> _buildAtlas() async {
    const int pad = 2; // 每边挤出像素
    try {
      final perBiomePaths = <Biome, List<String>>{
        Biome.snow: snowPaths, Biome.grass: grassPaths, Biome.rock: rockPaths,
        Biome.forest: forestPaths, Biome.flower: flowerPaths, Biome.shallow: shallowPaths,
        Biome.beach: beachPaths, Biome.volcanic: volcanicPaths,
      };
      final perBiomeImages = <Biome, List<ui.Image>>{
        for (final b in Biome.values) b: <ui.Image>[],
      };

      // 载入
      for (final b in Biome.values) {
        for (final p in perBiomePaths[b]!) {
          try { perBiomeImages[b]!.add(await _loadUiImageFromAsset(p)); }
          catch (_) { debugPrint('[FbmTerrainLayer] skip bad asset: $p'); }
        }
      }

      // 选主流尺寸（只示范：你也可以强制只用同尺寸资源）
      final Map<String,(int w,int h,int cnt)> sizeCount = {};
      for (final b in Biome.values) for (final img in perBiomeImages[b]!) {
        final k='${img.width}x${img.height}';
        final v=sizeCount[k]; sizeCount[k]=(img.width,img.height,(v==null?0:v.$3)+1);
      }
      if (sizeCount.isEmpty) { _atlasCols=1; _atlasRows=1; return; }
      final dom = sizeCount.values.reduce((a,b)=>a.$3>=b.$3?a:b);
      final tileW=dom.$1, tileH=dom.$2;

      // 过滤非主流尺寸
      for (final b in Biome.values) {
        perBiomeImages[b] = perBiomeImages[b]!.where((im)=>im.width==tileW && im.height==tileH).toList();
      }

      // 重新计算 offset/count
      int acc=0;
      for (final b in Biome.values) { _varOffset[b]=acc; _varCount[b]=perBiomeImages[b]!.length; acc+=_varCount[b]!; }
      final total = acc;
      if (total<=0){ _atlasCols=1; _atlasRows=1; return; }

      _atlasCols = math.max(1, math.sqrt(total).ceil());
      _atlasRows = ((total + _atlasCols - 1) ~/ _atlasCols);

      // ★ 单元格尺寸= tile + 2*pad（左右上下）
      final cellW = tileW + pad*2;
      final cellH = tileH + pad*2;
      final atlasW = _atlasCols * cellW;
      final atlasH = _atlasRows * cellH;

      final rec = ui.PictureRecorder();
      final canvas = Canvas(rec);
      canvas.drawRect(Rect.fromLTWH(0,0,atlasW.toDouble(),atlasH.toDouble()),
          Paint()..color=const Color(0xFF000000));

      int i=0;
      final p = Paint()..filterQuality=FilterQuality.none;

      for (final b in Biome.values) {
        for (final img in perBiomeImages[b]!) {
          final col=i % _atlasCols, row=i ~/ _atlasCols;
          final originX = col*cellW, originY = row*cellH;

          // 中心
          final dstInner = Rect.fromLTWH((originX+pad).toDouble(), (originY+pad).toDouble(),
              tileW.toDouble(), tileH.toDouble());
          canvas.drawImageRect(img, Rect.fromLTWH(0,0,tileW.toDouble(),tileH.toDouble()), dstInner, p);

          // 上下边条（复制 1px 拉伸到 pad）
          canvas.drawImageRect(img, Rect.fromLTWH(0,0,tileW.toDouble(),1),
              Rect.fromLTWH((originX+pad).toDouble(), originY.toDouble(), tileW.toDouble(), pad.toDouble()), p);
          canvas.drawImageRect(img, Rect.fromLTWH(0,(tileH-1).toDouble(),tileW.toDouble(),1),
              Rect.fromLTWH((originX+pad).toDouble(), (originY+pad+tileH).toDouble(), tileW.toDouble(), pad.toDouble()), p);

          // 左右边条
          canvas.drawImageRect(img, Rect.fromLTWH(0,0,1,tileH.toDouble()),
              Rect.fromLTWH(originX.toDouble(), (originY+pad).toDouble(), pad.toDouble(), tileH.toDouble()), p);
          canvas.drawImageRect(img, Rect.fromLTWH((tileW-1).toDouble(),0,1,tileH.toDouble()),
              Rect.fromLTWH((originX+pad+tileW).toDouble(), (originY+pad).toDouble(), pad.toDouble(), tileH.toDouble()), p);

          // 四角
          canvas.drawImageRect(img, Rect.fromLTWH(0,0,1,1),
              Rect.fromLTWH(originX.toDouble(), originY.toDouble(), pad.toDouble(), pad.toDouble()), p);
          canvas.drawImageRect(img, Rect.fromLTWH((tileW-1).toDouble(),0,1,1),
              Rect.fromLTWH((originX+pad+tileW).toDouble(), originY.toDouble(), pad.toDouble(), pad.toDouble()), p);
          canvas.drawImageRect(img, Rect.fromLTWH(0,(tileH-1).toDouble(),1,1),
              Rect.fromLTWH(originX.toDouble(), (originY+pad+tileH).toDouble(), pad.toDouble(), pad.toDouble()), p);
          canvas.drawImageRect(img, Rect.fromLTWH((tileW-1).toDouble(),(tileH-1).toDouble(),1,1),
              Rect.fromLTWH((originX+pad+tileW).toDouble(), (originY+pad+tileH).toDouble(), pad.toDouble(), pad.toDouble()), p);

          i++;
        }
      }

      final pic = rec.endRecording();
      final newAtlas = await pic.toImage(atlasW, atlasH);
      _nextAtlas = newAtlas; // 帧首交换
    } finally {}
  }

}
