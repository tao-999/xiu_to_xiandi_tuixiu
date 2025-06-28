import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:xiu_to_xiandi_tuixiu/services/chiyangu_storage.dart';

class PickaxeOverlay extends StatefulWidget {
  const PickaxeOverlay({super.key});

  @override
  State<PickaxeOverlay> createState() => _PickaxeOverlayState();
}

class _PickaxeOverlayState extends State<PickaxeOverlay> with WidgetsBindingObserver {
  int pickaxeCount = 0;
  Duration timeLeft = Duration.zero;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startTimer();
    _loadData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadData();
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _loadData());
  }

  Future<void> _loadData() async {
    final now = DateTime.now();
    final lastRefill = await ChiyanguStorage.getLastPickaxeRefillTime();

    if (now.isBefore(lastRefill)) {
      print('❌ 本地时间被篡改，锄头恢复系统暂停');
      _timer?.cancel();
      return;
    }

    final storedCount = await ChiyanguStorage.getPickaxeCount();
    int currentCount = storedCount;
    Duration passed = now.difference(lastRefill);

    if (currentCount < ChiyanguStorage.maxPickaxe) {
      int refillAmount = passed.inMinutes;
      if (refillAmount > 0) {
        currentCount = (currentCount + refillAmount).clamp(0, ChiyanguStorage.maxPickaxe);
        final newTime = lastRefill.add(ChiyanguStorage.refillCooldown * refillAmount);
        await ChiyanguStorage.setPickaxeCount(currentCount);
        await ChiyanguStorage.setLastPickaxeRefillTime(newTime);
        passed = now.difference(newTime);
      }
    }

    final remaining = ChiyanguStorage.refillCooldown - passed;

    if (mounted) {
      setState(() {
        pickaxeCount = currentCount;
        timeLeft = currentCount >= ChiyanguStorage.maxPickaxe ? Duration.zero : remaining;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final refillText = timeLeft == Duration.zero
        ? '已恢复'
        : '${timeLeft.inMinutes.remainder(60).toString().padLeft(2, '0')}:${(timeLeft.inSeconds % 60).toString().padLeft(2, '0')}';

    return Positioned(
      top: 24,
      right: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.end, // ✅ 右对齐
            children: [
              Text(
                '⛏️ $pickaxeCount / ${ChiyanguStorage.maxPickaxe}',
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (_) => Dialog(
                      backgroundColor: const Color(0xFFF9F5E3), // ✅ 米黄色背景
                      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero), // ✅ 直角边框
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              '💎 灵石掉落概率说明',
                              style: TextStyle(fontSize: 16, color: Colors.black),
                            ),
                            SizedBox(height: 12),
                            Text(
                              '每次爆石头，只能爆出「一种灵石」，爆率如下：\n\n'
                                  '❤️ 极品灵石：0.05%\n'
                                  '💙 上品灵石：0.2%\n'
                                  '💚 中品灵石：2%\n'
                                  '💛 下品灵石：其余概率保底\n\n'
                                  '📈 爆出的灵石数量 = 当前深度层数\n'
                                  '⛏️ 挖得越深，爆得越多，手越爽！',
                              style: TextStyle(fontSize: 14, color: Colors.black87),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
                child: const Icon(Icons.info_outline, size: 16, color: Colors.white70),
              ),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.end, // ✅ 右对齐
            children: [
              Text(
                '$refillText +1',
                style: const TextStyle(color: Colors.white70, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
