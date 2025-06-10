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
                _infoRow("当前等级", "$level 级", trailing: const CirclePlusIcon()),
                _infoRow("每小时产出", "$outputPerHour 颗灵药"),
                _infoRow("冷却状态", isReady ? "可收取" : _formatTime(remaining)),
                const SizedBox(height: 24),
                Center(
                  child: Image.asset(
                    'assets/images/zongmen_liandanlu.png',
                    width: 240,
                    height: 240,
                    fit: BoxFit.contain,
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

// ✅ 圆圈 + 号图标
class CirclePlusIcon extends StatelessWidget {
  const CirclePlusIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24,
      height: 24,
      child: CustomPaint(
        painter: _CirclePlusPainter(),
      ),
    );
  }
}

class _CirclePlusPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.orangeAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 2;

    // 画圆圈
    canvas.drawCircle(center, radius, paint);

    // 画十字
    final plusPaint = Paint()
      ..color = Colors.orangeAccent
      ..strokeWidth = 2;

    final offset = radius * 0.6;
    canvas.drawLine(
      Offset(center.dx - offset, center.dy),
      Offset(center.dx + offset, center.dy),
      plusPaint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - offset),
      Offset(center.dx, center.dy + offset),
      plusPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
