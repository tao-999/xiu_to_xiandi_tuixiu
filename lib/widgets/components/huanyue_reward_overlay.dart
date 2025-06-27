import 'dart:async';
import 'package:flutter/material.dart';
import 'package:xiu_to_xiandi_tuixiu/services/huanyue_storage.dart';

import '../../utils/number_format.dart';

class RewardCounterOverlay extends StatefulWidget {
  const RewardCounterOverlay({super.key});

  @override
  State<RewardCounterOverlay> createState() => _RewardCounterOverlayState();
}

class _RewardCounterOverlayState extends State<RewardCounterOverlay> {
  int spiritStoneCount = 0;
  int recruitTicketCount = 0;
  int aptitudeTicketCount = 0;

  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadCounts();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _loadCounts();
    });
  }

  Future<void> _loadCounts() async {
    final spirit = await HuanyueStorage.getTotalReward(RewardType.spiritStone);
    final recruit = await HuanyueStorage.getTotalReward(RewardType.recruitTicket);
    final aptitude = await HuanyueStorage.getTotalReward(RewardType.fateRecruitCharm);

    setState(() {
      spiritStoneCount = spirit;
      recruitTicketCount = recruit;
      aptitudeTicketCount = aptitude;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildItem('下品灵石: ${formatAnyNumber(spiritStoneCount)}'),
          _buildItem('招募券: ${formatAnyNumber(recruitTicketCount)}'),
          _buildItem('资质券: ${formatAnyNumber(aptitudeTicketCount)}'),
        ],
      ),
    );
  }

  Widget _buildItem(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 10,
        shadows: [Shadow(blurRadius: 2, color: Colors.black)],
        decoration: TextDecoration.none,
      ),
    );
  }
}
