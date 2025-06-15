import 'dart:async';
import 'package:flutter/material.dart';
import 'package:xiu_to_xiandi_tuixiu/services/gift_service.dart';
import '../common/toast_tip.dart';

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
    _lastClaimed = await GiftService.getLastClaimedAt();
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
    final nextClaim = _lastClaimed!.add(GiftService.cooldown);
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
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        title: const Text(
          '🎁 修仙大礼包',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18),
        ),
        content: FutureBuilder<int>(
          future: GiftService.getClaimCount(),
          builder: (context, snapshot) {
            final count = (snapshot.data ?? 0) + 1;
            final amount = 10000 + (count - 1) * 500;

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isFirstTime
                      ? '🧙‍♂️ 欢迎修士踏入仙道，来一份开光大礼包'
                      : '🌅 修炼辛苦，赠你每日修仙资源',
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 12),
                Text(
                  '💰 下品灵石 ×${isFirstTime ? '1${'0' * 48}' : amount}',
                  style: const TextStyle(fontSize: 13),
                ),
                Text(
                  '📜 招募券 ×${isFirstTime ? 50000 : 1}',
                  style: const TextStyle(fontSize: 13),
                ),
                Text(
                  '🧬 资质提升券 ×${isFirstTime ? 1000 : 1}',
                  style: const TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 16),
                const Text(
                  '请点击下方领取，方可继续修行！',
                  style: TextStyle(fontSize: 14, color: Colors.red),
                ),
                const SizedBox(height: 24),
                Center(
                  child: InkWell(
                    onTap: () async {
                      Navigator.of(context).pop();

                      final result = await GiftService.claimReward();
                      widget.onGiftClaimed();

                      if (mounted) {
                        _lastClaimed = DateTime.now();
                        _updateRemaining();
                        _startCountdown();
                        setState(() {});
                      }

                      ToastTip.show(
                        context,
                        result.isFirstTime
                            ? '🎁 首次礼包领取成功！\n下品灵石 +${result.spiritStone}\n招募券 +${result.recruitTicket}\n资质提升券 +${result.fateCharm}'
                            : '🪙 第 ${result.claimCount} 次修仙礼包：\n下品灵石 +${result.spiritStone}\n招募券 +1\n资质提升券 +1',
                      );
                    },
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Text(
                        '立即领取',
                        style: TextStyle(
                          fontSize: 16,
                          fontFamily: 'ZcoolCangEr',
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                )
              ],
            );
          },
        ),
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
