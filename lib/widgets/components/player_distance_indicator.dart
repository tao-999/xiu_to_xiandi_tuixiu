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

    // ✅ 这里用 logicalPosition，别用 position！
    final initialLogicalPos = widget.mapComponent.player!.logicalPosition;
    setState(() {
      _distance = initialLogicalPos.length;
    });

    // 后续监听也没问题，本来就推送 logicalPosition
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
