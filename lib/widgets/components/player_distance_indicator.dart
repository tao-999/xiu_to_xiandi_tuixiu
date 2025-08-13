// 📄 lib/widgets/components/player_distance_indicator.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flame/components.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/floating_island_map_component.dart';
import '../../utils/pixel_ly_format.dart';

class PlayerDistanceIndicator extends StatefulWidget {
  final FloatingIslandMapComponent mapComponent;
  const PlayerDistanceIndicator({super.key, required this.mapComponent});

  @override
  State<PlayerDistanceIndicator> createState() => _PlayerDistanceIndicatorState();
}

class _PlayerDistanceIndicatorState extends State<PlayerDistanceIndicator> {
  String _distanceText = '0 米';
  StreamSubscription<Vector2>? _sub;

  @override
  void initState() {
    super.initState();
    _bind();
  }

  Future<void> _bind() async {
    while (widget.mapComponent.player == null) {
      await Future.delayed(const Duration(milliseconds: 50));
      if (!mounted) return;
    }
    final p = widget.mapComponent.player!;

    // 首次
    _distanceText = formatDistanceFromOriginStrictCN(
      worldBase: widget.mapComponent.worldBase,
      localPos: p.logicalPosition,
      meterDigits: 4, // 米系小数
      lyDigits: 4,    // 光年系小数
    );
    if (mounted) setState(() {});

    // 订阅更新（支持浮动原点）
    _sub = p.onPositionChangedStream.listen((pos) {
      if (!mounted) return;
      final text = formatDistanceFromOriginStrictCN(
        worldBase: widget.mapComponent.worldBase,
        localPos: pos,
        meterDigits: 4,
        lyDigits: 4,
      );
      setState(() => _distanceText = text);
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('距离原点: $_distanceText',
            style: const TextStyle(color: Colors.white, fontSize: 10)),
      ],
    );
  }
}
