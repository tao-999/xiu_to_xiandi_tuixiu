import 'dart:async';
import 'package:flutter/material.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/floating_island_map_component.dart';

import '../../utils/number_format.dart';

class PlayerDistanceIndicator extends StatefulWidget {
  final FloatingIslandMapComponent mapComponent;

  const PlayerDistanceIndicator({super.key, required this.mapComponent});

  @override
  State<PlayerDistanceIndicator> createState() => _PlayerDistanceIndicatorState();
}

class _PlayerDistanceIndicatorState extends State<PlayerDistanceIndicator> {
  double _distance = 0;
  StreamSubscription? _positionSub;

  @override
  void initState() {
    super.initState();
    _waitForPlayerAndSubscribe();
  }

  Future<void> _waitForPlayerAndSubscribe() async {
    while (widget.mapComponent.player == null) {
      await Future.delayed(const Duration(milliseconds: 50));
      if (!mounted) return;
    }

    // 先同步设置一次距离，避免第一帧丢失
    final initialPos = widget.mapComponent.player!.position;
    setState(() {
      _distance = initialPos.length;
    });

    // 再开始监听后续更新
    _positionSub = widget.mapComponent.player!.onPositionChangedStream.listen((pos) {
      final dist = pos.length;
      if (mounted) {
        setState(() {
          _distance = dist;
        });
      }
    });
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      child: Text(
        '距离原点: ${formatAnyNumber(_distance)}米',
        style: const TextStyle(color: Colors.black, fontSize: 10),
      ),
    );
  }
}
