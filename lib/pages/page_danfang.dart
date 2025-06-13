import 'package:flutter/material.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/back_button_overlay.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/danfang_header.dart';
import '../widgets/effects/five_star_danfang_array.dart'; // ✅ 五芒星阵法组件

class DanfangPage extends StatefulWidget {
  const DanfangPage({super.key});

  @override
  State<DanfangPage> createState() => _DanfangPageState();
}

class _DanfangPageState extends State<DanfangPage> {
  int level = 1;
  bool hasStarted = false;

  final GlobalKey<FiveStarAlchemyArrayState> _arrayKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
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

                /// ✅ 顶部标题 + 等级 + 加号按钮
                DanfangHeader(
                  level: level,
                  onLevelUp: () {
                    setState(() {
                      level += 1;
                    });
                  },
                ),

                const SizedBox(height: 24),

                /// ✅ 阵法组件
                Center(
                  child: FiveStarAlchemyArray(
                    key: _arrayKey,
                    radius: 150,
                    bigDanluSize: 200,
                    smallDanluSize: 100,
                  ),
                ),

                const SizedBox(height: 16),

                /// ✅ 开始/结束炼丹按钮
                Center(
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        if (hasStarted) {
                          _arrayKey.currentState?.stop();
                        } else {
                          _arrayKey.currentState?.start();
                        }
                        hasStarted = !hasStarted;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(hasStarted ? "结束炼丹" : "开始炼丹"),
                  ),
                ),

                const SizedBox(height: 32),

                /// ✅ 驻守弟子标题
                Text("驻守弟子", style: _titleStyle()),

                const SizedBox(height: 12),

                /// ✅ 驻守弟子占位区域
                _buildDiscipleSlot(),
              ],
            ),
          ),
          const BackButtonOverlay(),
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
}
