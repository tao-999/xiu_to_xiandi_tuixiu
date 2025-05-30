import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GiftPopup extends StatefulWidget {
  final VoidCallback? onClaimed;

  const GiftPopup({super.key, this.onClaimed});

  @override
  State<GiftPopup> createState() => _GiftPopupState();
}

class _GiftPopupState extends State<GiftPopup> {
  bool hasClaimed = false;

  @override
  void initState() {
    super.initState();
    _checkClaimed();
  }

  Future<void> _checkClaimed() async {
    final prefs = await SharedPreferences.getInstance();
    final claimed = prefs.getBool('hasClaimedGift') ?? false;

    if (claimed) {
      Navigator.of(context).pop(); // 已领取自动关闭
    } else {
      setState(() {
        hasClaimed = false;
      });
    }
  }

  Future<void> _claimGift() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasClaimedGift', true);

    final currentStone = prefs.getInt('stone_low') ?? 0;
    final currentTickets = prefs.getInt('ticket_human') ?? 0;
    await prefs.setInt('stone_low', currentStone + 10000);
    await prefs.setInt('ticket_human', currentTickets + 100);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('🎁 修仙大礼包已领取！灵石+10000，招募券+100')),
    );

    Navigator.of(context).pop();

    if (widget.onClaimed != null) {
      widget.onClaimed!(); // 回调骚哥的函数
    }

  }

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
                onPressed: _claimGift,
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
