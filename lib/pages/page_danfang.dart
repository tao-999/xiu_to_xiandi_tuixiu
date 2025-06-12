import 'package:flutter/material.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/back_button_overlay.dart';
import '../widgets/effects/five_star_danfang_array.dart';

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

  bool isRunning = false;
  bool hasStarted = false;

  @override
  Widget build(BuildContext context) {
    final elapsed = DateTime.now().difference(lastCollectTime).inSeconds;
    final remaining = cooldownSeconds - elapsed;
    final isReady = remaining <= 0;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/zongmen_bg_liandanfang.webp',
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                Text('🔥 炼丹房',
                    style: const TextStyle(
                      fontSize: 20,
                      color: Colors.orangeAccent,
                      fontFamily: 'ZcoolCangEr',
                    )),
                const SizedBox(height: 20),
                _infoRow(
                  "当前等级",
                  "$level 级",
                  trailing: const Icon(Icons.add_circle_outline, color: Colors.orangeAccent, size: 20),
                ),
                _infoRow("每小时产出", "$outputPerHour 颗灵药"),
                _infoRow("冷却状态", isReady ? "可收取" : _formatTime(remaining)),
                const SizedBox(height: 24),
                Center(
                  child: FiveStarDanfangArray(
                    imagePath: 'assets/images/zongmen_liandanlu.png',
                    radius: 120,
                    imageSize: 80,
                    isRunning: isRunning,
                    hasStarted: hasStarted,
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Center(
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          if (hasStarted) {
                            // 停止炼丹
                            hasStarted = false;
                            isRunning = false;
                          } else {
                            // 开始炼丹
                            hasStarted = true;
                            isRunning = true;
                          }
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(hasStarted ? "结束炼丹" : "开始炼丹"),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Text("驻守弟子", style: _titleStyle()),
                const SizedBox(height: 12),
                _buildDiscipleSlot(),
              ],
            ),
          ),
          const BackButtonOverlay(),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value, {Widget? trailing}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Text("$label：", style: const TextStyle(color: Colors.white70, fontFamily: 'ZcoolCangEr')),
          Text(value, style: const TextStyle(color: Colors.white, fontFamily: 'ZcoolCangEr')),
          if (trailing != null) ...[
            const SizedBox(width: 8),
            trailing,
          ],
        ],
      ),
    );
  }

  TextStyle _titleStyle() => const TextStyle(
    fontSize: 16,
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

  String _formatTime(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return "$m 分 $s 秒后可收取";
  }
}
