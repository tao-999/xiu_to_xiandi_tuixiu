// 📦 文件路径建议：widgets/components/gift_button_overlay.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xiu_to_xiandi_tuixiu/services/player_storage.dart';

class GiftButtonOverlay extends StatefulWidget {
  final VoidCallback onGiftClaimed;

  const GiftButtonOverlay({super.key, required this.onGiftClaimed});

  @override
  State<GiftButtonOverlay> createState() => _GiftButtonOverlayState();
}

class _GiftButtonOverlayState extends State<GiftButtonOverlay> {
  bool _checking = true;
  bool _hasClaimed = false;

  @override
  void initState() {
    super.initState();
    _checkGiftStatus();
  }

  Future<void> _checkGiftStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final claimed = prefs.getBool('hasClaimedGift') ?? false;
    setState(() {
      _hasClaimed = claimed;
      _checking = false;
    });
  }

  Future<void> _showGiftDialog() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _GiftPopup(onClaimed: () async {
        final player = await PlayerStorage.getPlayer();
        if (player == null) return;

        player.resources.add('spiritStoneLow', 10000);
        player.resources.add('humanRecruitTicket', 100);
        await PlayerStorage.savePlayer(player);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('hasClaimedGift', true);

        widget.onGiftClaimed();
        if (mounted) {
          setState(() => _hasClaimed = true);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('🎁 修仙大礼包已领取！灵石+10000，招募券+100')),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_checking || _hasClaimed) return const SizedBox.shrink();

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

  const _GiftPopup({required this.onClaimed});

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('🎁 新人修仙大礼包', textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🧙‍♂️ 欢迎修士踏入仙道，先来一份开光大礼包：'),
            const SizedBox(height: 12),
            const Text('💰 下品灵石 ×10000'),
            const Text('📜 人界招募券 ×100'),
            const SizedBox(height: 16),
            const Text('请点击下方领取，方可开启修仙之旅！', style: TextStyle(color: Colors.red)),
            const SizedBox(height: 24),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  onClaimed();
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
