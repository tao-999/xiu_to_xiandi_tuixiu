import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/scheduler.dart';

import 'package:xiu_to_xiandi_tuixiu/pages/page_create_role.dart';
import 'package:xiu_to_xiandi_tuixiu/services/chiyangu_storage.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/back_button_overlay.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/typewriter_poem_section.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/mengpo_soup_dialog.dart';

import '../models/dead_boss_entry.dart';
import '../models/disciple.dart';
import '../models/pill.dart';
import '../models/weapon.dart';
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

    // ✅ 清空 SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    // ✅ 关闭所有已打开的 box（带泛型）
    await closeAllBoxes();

    // ✅ 关闭 Hive 并尝试官方删除
    await Hive.close();
    await Hive.deleteFromDisk();

    // ✅ 暴力物理删除 Hive 数据文件（保险）
    await nukeHiveStorage();

    // ✅ 清理游戏状态
    ChiyanguStorage.resetPickaxeData();

    await Future.delayed(const Duration(seconds: 8));

    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const CreateRolePage()),
            (route) => false,
      );
    }
  }

  Future<void> nukeHiveStorage() async {
    // ✅ 等 Hive 全部关闭
    await Hive.close();

    // ✅ 获取默认 Hive 目录
    final dir = await getApplicationDocumentsDirectory();

    // ✅ Hive 默认 box 是保存在这里的（你没改 path 就准在这）
    final hiveRoot = dir.path;
    final files = Directory(hiveRoot).listSync(recursive: true);

    for (final file in files) {
      final name = file.path;
      if (name.endsWith('.hive') || name.endsWith('.lock') || name.contains('hive')) {
        try {
          await File(name).delete();
          debugPrint('🔥 删除文件: $name');
        } catch (e) {
          debugPrint('⚠️ 删除失败: $name');
        }
      }
    }

    debugPrint('✅ Hive 文件全干掉了');
  }

// ⚡ 最骚范例，close 和 open 泛型一定要完全对齐！
  Future<void> closeAllBoxes() async {
    // disciples: openBox<Disciple>
    if (Hive.isBoxOpen('disciples')) {
      await Hive.box<Disciple>('disciples').close();
      print('[Hive] Closed box: disciples');
    }
    // weapons: openBox<Weapon>
    if (Hive.isBoxOpen('weapons')) {
      await Hive.box<Weapon>('weapons').close();
      print('[Hive] Closed box: weapons');
    }
    // pills: openBox<Pill>
    if (Hive.isBoxOpen('pills')) {
      await Hive.box<Pill>('pills').close();
      print('[Hive] Closed box: pills');
    }
    // role_regions: 没加泛型，直接 dynamic
    if (Hive.isBoxOpen('role_regions')) {
      await Hive.box('role_regions').close();
      print('[Hive] Closed box: role_regions');
    }
    // floating_island: 没加泛型
    if (Hive.isBoxOpen('floating_island')) {
      await Hive.box('floating_island').close();
      print('[Hive] Closed box: floating_island');
    }
    // noise_cache: openBox<double>
    if (Hive.isBoxOpen('noise_cache')) {
      await Hive.box<double>('noise_cache').close();
      print('[Hive] Closed box: noise_cache');
    }
    // terrain_events: 没加泛型
    if (Hive.isBoxOpen('terrain_events')) {
      await Hive.box('terrain_events').close();
      print('[Hive] Closed box: terrain_events');
    }
    // zongmen_diplomacy
    if (Hive.isBoxOpen('zongmen_diplomacy')) {
      await Hive.box('zongmen_diplomacy').close();
      print('[Hive] Closed box: zongmen_diplomacy');
    }
    if (Hive.isBoxOpen('opened_chests')) {
      await Hive.box('opened_chests').close();
      print('[Hive] Closed box: opened_chests');
    }
    if (Hive.isBoxOpen('dead_boss_box')) {
      await Hive.box<DeadBossEntry>('dead_boss_box').close();
      print('[Hive] Closed box: dead_boss_box');
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
