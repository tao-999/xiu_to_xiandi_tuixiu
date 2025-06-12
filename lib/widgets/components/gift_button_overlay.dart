import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xiu_to_xiandi_tuixiu/services/player_storage.dart';
import '../../services/resources_storage.dart';
import '../common/toast_tip.dart';

// 🎁 奖励冷却时间
const Duration giftCooldown = Duration(hours: 24);
// const Duration giftCooldown = Duration(seconds: 10);

// 🎁 奖励配置（支持 BigInt，但不能 const）
final BigInt firstTimeSpiritStone = BigInt.parse('1' + '0' * 48);
final int firstTimeTicket = 50000;
final int firstTimeFateCharm = 1000; // ✅ 新增：首次资质提升券

final BigInt dailySpiritStone = BigInt.from(8640);

class GiftButtonOverlay extends StatefulWidget {
  final VoidCallback onGiftClaimed;

  const GiftButtonOverlay({super.key, required this.onGiftClaimed});

  @override
  State<GiftButtonOverlay> createState() => _GiftButtonOverlayState();
}

class _GiftButtonOverlayState extends State<GiftButtonOverlay> {
  DateTime? _lastClaimed;
  Timer? _countdownTimer;
  Duration _remaining = Duration.zero;
  bool _checking = true;

  @override
  void initState() {
    super.initState();
    _loadGiftTime();
  }

  Future<void> _loadGiftTime() async {
    final prefs = await SharedPreferences.getInstance();
    final ms = prefs.getInt('lastClaimedGiftAt');
    if (ms != null) {
      _lastClaimed = DateTime.fromMillisecondsSinceEpoch(ms);
    }
    _updateRemaining();
    _checking = false;
    _startCountdown();
    setState(() {});
  }

  void _updateRemaining() {
    if (_lastClaimed == null) {
      _remaining = Duration.zero;
      return;
    }
    final nextClaim = _lastClaimed!.add(giftCooldown);
    final now = DateTime.now();
    _remaining = nextClaim.isAfter(now) ? nextClaim.difference(now) : Duration.zero;
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateRemaining();
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  bool get _canClaim => _remaining == Duration.zero;

  Future<void> _showGiftDialog() async {
    final isFirstTime = _lastClaimed == null;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _GiftPopup(
        isFirstTime: isFirstTime,
        onClaimed: () async {
          // ✅ 添加奖励：使用 ResourcesStorage 封装方法
          if (isFirstTime) {
            await ResourcesStorage.add('spiritStoneLow', firstTimeSpiritStone);
            await ResourcesStorage.add('recruitTicket', BigInt.from(firstTimeTicket));
            await ResourcesStorage.add('fateRecruitCharm', BigInt.from(firstTimeFateCharm));
          } else {
            await ResourcesStorage.add('spiritStoneLow', dailySpiritStone);
            await ResourcesStorage.add('recruitTicket', BigInt.one);
            await ResourcesStorage.add('fateRecruitCharm', BigInt.one);
          }

          // ✅ 存储领取时间
          final prefs = await SharedPreferences.getInstance();
          await prefs.setInt('lastClaimedGiftAt', DateTime.now().millisecondsSinceEpoch);

          widget.onGiftClaimed();

          if (mounted) {
            _lastClaimed = DateTime.now();
            _updateRemaining();
            _startCountdown();
            setState(() {});
          }

          // ✅ 奖励提示
          ToastTip.show(
            context,
            isFirstTime
                ? '🎁 首次礼包领取成功！\n下品灵石 +$firstTimeSpiritStone\n招募券 +$firstTimeTicket\n资质提升券 +$firstTimeFateCharm'
                : '🪙 每日修仙奖励：\n下品灵石 +$dailySpiritStone\n招募券 +1\n资质提升券 +1',
            duration: const Duration(seconds: 3),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) return const SizedBox.shrink();

    if (!_canClaim) {
      final h = _remaining.inHours;
      final m = _remaining.inMinutes % 60;
      final s = _remaining.inSeconds % 60;

      return Positioned(
        top: 30,
        right: 20,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
          child: Text(
            '下次领取：${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}',
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ),
      );
    }

    return Positioned(
      top: 30,
      right: 20,
      child: GestureDetector(
        onTap: _showGiftDialog,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.amber.withOpacity(0.9),
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
          ),
          child: const Row(
            children: [
              Icon(Icons.card_giftcard, color: Colors.white, size: 20),
              SizedBox(width: 6),
              Text('修仙大礼包', style: TextStyle(color: Colors.white, fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }
}

class _GiftPopup extends StatelessWidget {
  final VoidCallback onClaimed;
  final bool isFirstTime;

  const _GiftPopup({
    required this.onClaimed,
    required this.isFirstTime,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('🎁 修仙大礼包', textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(isFirstTime
                ? '🧙‍♂️ 欢迎修士踏入仙道，来一份开光大礼包：'
                : '🌅 修炼辛苦，赠你每日修仙资源：'),
            const SizedBox(height: 12),
            Text('💰 下品灵石 ×${isFirstTime ? firstTimeSpiritStone : dailySpiritStone}'),
            Text('📜 招募券 ×${isFirstTime ? firstTimeTicket : 1}'),
            Text('🧬 资质提升券 ×${isFirstTime ? firstTimeFateCharm : 1}'),
            const SizedBox(height: 16),
            const Text('请点击下方领取，方可继续修行！', style: TextStyle(color: Colors.red)),
            const SizedBox(height: 24),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Future.delayed(Duration.zero, onClaimed);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.withOpacity(0.5),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('立即领取', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
