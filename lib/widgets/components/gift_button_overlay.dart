// 📦 widgets/components/gift_button_overlay.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xiu_to_xiandi_tuixiu/services/player_storage.dart';

/// ⏱️ 调试用：礼包冷却时间 Duration(seconds: 10)
/// 上线前改回：Duration(hours: 24)
const Duration giftCooldown = Duration(hours: 24);

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
          final player = await PlayerStorage.getPlayer();
          if (player == null) return;

          if (isFirstTime) {
            player.resources.add('spiritStoneLow', 10000);
            player.resources.add('humanRecruitTicket', 100);
          } else {
            player.resources.add('spiritStoneLow', 8640);
          }

          await PlayerStorage.savePlayer(player);

          final prefs = await SharedPreferences.getInstance();
          await prefs.setInt('lastClaimedGiftAt', DateTime.now().millisecondsSinceEpoch);

          widget.onGiftClaimed();

          if (mounted) {
            _lastClaimed = DateTime.now();
            _updateRemaining();
            _startCountdown();
            setState(() {});
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(isFirstTime
                ? '🎁 首次礼包领取成功！下品灵石+10000，招募券+100'
                : '🪙 每日修仙奖励：下品灵石 +8640')),
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
          decoration: BoxDecoration(
            color: Colors.grey.shade800.withOpacity(0.85),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '下次可领取：${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}',
            style: const TextStyle(color: Colors.white),
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
              Text('修仙大礼包', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
            Text('💰 下品灵石 ×${isFirstTime ? 10000 : 8640}'),
            if (isFirstTime) const Text('📜 人界招募券 ×100'),
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
                  backgroundColor: Colors.orange,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('立即领取', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
