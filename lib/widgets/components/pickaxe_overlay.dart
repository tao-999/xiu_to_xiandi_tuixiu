import 'dart:async';
import 'package:flutter/material.dart';
import 'package:xiu_to_xiandi_tuixiu/services/chiyangu_storage.dart';

class PickaxeOverlay extends StatefulWidget {
  const PickaxeOverlay({super.key});

  @override
  State<PickaxeOverlay> createState() => _PickaxeOverlayState();
}

class _PickaxeOverlayState extends State<PickaxeOverlay> {
  int pickaxeCount = 0;
  Duration timeLeft = Duration.zero;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
    _loadData();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _loadData());
  }

  Future<void> _loadData() async {
    final now = DateTime.now();
    final lastRefill = await ChiyanguStorage.getLastPickaxeRefillTime();

    // ✅ 检测时间倒退 —— 直接停机！
    if (now.isBefore(lastRefill)) {
      print('❌ 本地时间被篡改，锄头恢复系统暂停');
      _timer?.cancel(); // 🔥 直接停掉定时器！
      return;
    }

    final storedCount = await ChiyanguStorage.getPickaxeCount();
    int currentCount = storedCount;
    Duration passed = now.difference(lastRefill);

    if (currentCount < ChiyanguStorage.maxPickaxe) {
      int refillAmount = passed.inMinutes ~/ 5;
      if (refillAmount > 0) {
        currentCount = (currentCount + refillAmount).clamp(0, ChiyanguStorage.maxPickaxe);
        await ChiyanguStorage.setPickaxeCount(currentCount);
        final newTime = lastRefill.add(ChiyanguStorage.refillCooldown * refillAmount);
        await ChiyanguStorage.setLastPickaxeRefillTime(newTime);
        passed = now.difference(newTime);
      }
    }

    final remaining = ChiyanguStorage.refillCooldown - passed;

    setState(() {
      pickaxeCount = currentCount;
      timeLeft = currentCount >= ChiyanguStorage.maxPickaxe ? Duration.zero : remaining;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final refillText = timeLeft == Duration.zero
        ? '已恢复'
        : '${timeLeft.inMinutes.remainder(60).toString().padLeft(2, '0')}:${(timeLeft.inSeconds % 60).toString().padLeft(2, '0')}';

    return Positioned(
      top: 16,
      left: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '⛏️ $pickaxeCount / ${ChiyanguStorage.maxPickaxe}',
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
            Text(
              '$refillText 后+1',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
