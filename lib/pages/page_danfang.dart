import 'package:flutter/material.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/back_button_overlay.dart';

class DanfangPage extends StatefulWidget {
  const DanfangPage({super.key});

  @override
  State<DanfangPage> createState() => _DanfangPageState();
}

class _DanfangPageState extends State<DanfangPage> {
  int level = 1;
  int outputPerHour = 5;
  int cooldownSeconds = 3600;
  DateTime lastCollectTime = DateTime.now().subtract(const Duration(hours: 1));

  @override
  Widget build(BuildContext context) {
    final elapsed = DateTime.now().difference(lastCollectTime).inSeconds;
    final remaining = cooldownSeconds - elapsed;
    final isReady = remaining <= 0;

    return Scaffold(
      backgroundColor: const Color(0xFF1D1A17),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                Text('🔥 炼丹房',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.orangeAccent,
                      fontFamily: 'ZcoolCangEr',
                    )),
                const SizedBox(height: 20),
                _infoRow("当前等级", "$level 级"),
                _infoRow("每小时产出", "$outputPerHour 颗灵药"),
                _infoRow("冷却状态", isReady ? "可收取" : _formatTime(remaining)),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: isReady ? _collectOutput : null,
                  icon: const Icon(Icons.local_florist),
                  label: const Text("收取炼丹成果"),
                ),
                const SizedBox(height: 32),
                Text("驻守弟子", style: _titleStyle()),
                const SizedBox(height: 12),
                _buildDiscipleSlot(),
                const SizedBox(height: 32),
                Center(
                  child: ElevatedButton.icon(
                    onPressed: _upgrade,
                    icon: const Icon(Icons.upgrade),
                    label: const Text("升级炼丹房"),
                  ),
                ),
              ],
            ),
          ),

          // ✅ 返回按钮叠在页面底部
          const BackButtonOverlay(),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Text("$label：", style: const TextStyle(color: Colors.white70, fontFamily: 'ZcoolCangEr')),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'ZcoolCangEr')),
        ],
      ),
    );
  }

  TextStyle _titleStyle() => const TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: Colors.orangeAccent,
    fontFamily: 'ZcoolCangEr',
  );

  Widget _buildDiscipleSlot() {
    return Container(
      width: double.infinity,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.white12,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24),
      ),
      child: const Center(
        child: Text(
          "尚未指派弟子驻守",
          style: TextStyle(color: Colors.white54, fontFamily: 'ZcoolCangEr'),
        ),
      ),
    );
  }

  void _collectOutput() {
    setState(() {
      lastCollectTime = DateTime.now();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("成功收取 5 颗灵药！")),
    );
  }

  void _upgrade() {
    setState(() {
      level += 1;
      outputPerHour += 2;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("炼丹房升级至 Lv.$level！")),
    );
  }

  String _formatTime(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return "$m 分 $s 秒后可收取";
  }
}
