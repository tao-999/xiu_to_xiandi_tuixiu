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

    final initialLogicalPos = widget.mapComponent.player!.logicalPosition;
    setState(() {
      _distance = initialLogicalPos.length;
    });

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

  void _showMapInfoDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFFF9F5E3),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
        ),
        title: const Text(
          '🌍 无限地图',
          style: TextStyle(fontSize: 16, fontFamily: 'ZcoolCangEr'),
        ),
        content: const Text(
          '这里是无尽的浮空仙岛，四面八方都是探索的方向。\n\n'
              '不论你朝哪个方向走，地图都会自动生长，延伸出无穷的领域。\n\n'
              '据说有位修士已经飘到百万光年之外，仍未到尽头——他可能还在飘。\n\n'
              '去吧！用脚步丈量这片浩瀚疆域，前方有神秘机缘等着你！',
          style: TextStyle(fontSize: 14, fontFamily: 'ZcoolCangEr'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '距离原点: ${formatAnyNumber(_distance)} 米',
            style: const TextStyle(color: Colors.black, fontSize: 10),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: _showMapInfoDialog,
            child: const Icon(
              Icons.info_outline,
              size: 14,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}
