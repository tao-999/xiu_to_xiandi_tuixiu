// lib/native_renderer.dart
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

const _ch = MethodChannel('native_renderer');

class NativeRenderer {
  int? _texId;
  bool _running = false;

  Future<int> createTexture({int width = 1280, int height = 720}) async {
    final id = await _ch.invokeMethod<int>('create', {'w': width, 'h': height});
    _texId = id;
    return id!;
  }

  Future<void> start() async {
    if (_texId == null) throw StateError('createTexture first');
    await _ch.invokeMethod('start', {'id': _texId});
    _running = true;
  }

  Future<void> stop() async {
    if (_texId == null) return;
    await _ch.invokeMethod('stop', {'id': _texId});
    _running = false;
  }

  Future<void> dispose() async {
    if (_texId == null) return;
    await _ch.invokeMethod('dispose', {'id': _texId});
    _texId = null;
  }

  // 把一帧“实例”喂给原生（可选：不传也会渲染测试图）
  // 实例结构： [srcX,srcY,srcW,srcH, dstX,dstY,dstW,dstH] * N（float32）
  Future<void> uploadInstances(Float32List packed) async {
    if (_texId == null) return;
    await _ch.invokeMethod('uploadInstances', {
      'id': _texId,
      'buf': packed.buffer.asUint8List(),
    });
  }

  Widget view() {
    if (_texId == null) throw StateError('createTexture first');
    return Texture(textureId: _texId!);
  }
}
