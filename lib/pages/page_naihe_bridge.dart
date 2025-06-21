import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/scheduler.dart';

import 'package:xiu_to_xiandi_tuixiu/pages/page_create_role.dart';
import 'package:xiu_to_xiandi_tuixiu/services/cultivation_tracker.dart';
import 'package:xiu_to_xiandi_tuixiu/services/chiyangu_storage.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/back_button_overlay.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/typewriter_poem_section.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/mengpo_soup_dialog.dart';

import '../services/cultivation_tracker.dart';
import '../services/disciple_storage.dart';
import '../services/pill_storage_service.dart';
import '../services/weapons_storage.dart';
import '../widgets/components/naihe_info_icon.dart';

class NaiheBridgePage extends StatefulWidget {
  const NaiheBridgePage({super.key});

  @override
  State<NaiheBridgePage> createState() => _NaiheBridgePageState();
}

class _NaiheBridgePageState extends State<NaiheBridgePage>
    with TickerProviderStateMixin {
  bool _showVortex = false;
  bool _showEnterWheelText = false;
  double _angle = 0.0;
  double _angularVelocity = 0.01;
  bool _spinning = false;
  late Ticker _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((_) {
      if (_spinning) {
        setState(() {
          _angle += _angularVelocity;
          _angularVelocity *= 1.05;
          if (_angularVelocity > 1000) _angularVelocity = 1000;
        });
      }
    });
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  Future<void> _resetCharacter() async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => MengpoSoupDialog(
        onDrinkConfirmed: () => Navigator.of(ctx).pop(true),
      ),
    );

    if (confirmed == true) {
      setState(() {
        _showVortex = true;
        _angle = 0.0;
        _angularVelocity = 0.01;
        _spinning = false;
      });
      _ticker.start();
      await Future.delayed(const Duration(milliseconds: 600));
      setState(() {
        _showEnterWheelText = true;
      });
    }
  }

  Future<void> _startWheel() async {
    setState(() {
      _showEnterWheelText = false;
      _spinning = true;
    });

    // 🧨 清空 SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    // 🧨 清空所有 Hive 数据
    await Hive.close();
    await Hive.deleteFromDisk();

    // 🛑 停止修为 tick、清除赤炎谷数据（内存状态）
    CultivationTracker.stopTick();
    ChiyanguStorage.resetPickaxeData();

    await Future.delayed(const Duration(seconds: 8));

    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const CreateRolePage()),
            (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _resetCharacter,
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                'assets/images/mengpotang.webp',
                fit: BoxFit.cover,
              ),
            ),
            const Center(child: TypewriterPoemSection()),
            const BackButtonOverlay(),
            // 例如放在右上角
            Positioned(
              top: 30,
              right: 20,
              child: NaiheInfoIcon(),
            ),
            if (_showVortex)
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    setState(() {
                      _showVortex = false;
                      _showEnterWheelText = false;
                      _spinning = false;
                    });
                    _ticker.stop();
                  },
                  child: Container(
                    color: Colors.black.withOpacity(0.85),
                    child: Center(
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: Center(
                              child: Transform.rotate(
                                angle: _angle,
                                child: OverflowBox(
                                  maxWidth: MediaQuery.of(context).size.height * 1.1,
                                  maxHeight: MediaQuery.of(context).size.height * 1.1,
                                  child: Image.asset(
                                    'assets/images/lunhui_xuanwo.webp',
                                    width: MediaQuery.of(context).size.height * 1.1,
                                    height: MediaQuery.of(context).size.height * 1.1,
                                    fit: BoxFit.fill, // ✅ 保证拉满目标尺寸
                                  ),
                                ),
                              ),
                            ),
                          ),
                          if (_showEnterWheelText)
                            Center(
                              child: GestureDetector(
                                behavior: HitTestBehavior.translucent,
                                onTap: _startWheel, // ✅ 关键来了！
                                child: const Text(
                                  '进入轮回',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontFamily: 'ZcoolCangEr',
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
