import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

class _NaiheBridgePageState extends State<NaiheBridgePage> {
  bool _isResetting = false;

  Future<void> _resetCharacter() async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => MengpoSoupDialog(
        onDrinkConfirmed: () => Navigator.of(ctx).pop(true),
      ),
    );

    if (confirmed == true) {
      await _startWheel();
    }
  }

  Future<void> _startWheel() async {
    setState(() => _isResetting = true);

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    await closeAllBoxes();
    await Hive.close();
    await Hive.deleteFromDisk();
    await nukeHiveStorage();
    ChiyanguStorage.resetPickaxeData();

    await Future.delayed(const Duration(milliseconds: 1000));

    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const CreateRolePage()),
            (route) => false,
      );
    }

    setState(() => _isResetting = false);
  }

  Future<void> nukeHiveStorage() async {
    await Hive.close();
    final dir = await getApplicationSupportDirectory();
    final files = Directory(dir.path).listSync(recursive: true);

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

  Future<void> closeAllBoxes() async {
    if (Hive.isBoxOpen('disciples')) {
      await Hive.box<Disciple>('disciples').close();
      print('[Hive] Closed box: disciples');
    }
    if (Hive.isBoxOpen('weapons')) {
      await Hive.box<Weapon>('weapons').close();
      print('[Hive] Closed box: weapons');
    }
    if (Hive.isBoxOpen('pills')) {
      await Hive.box<Pill>('pills').close();
      print('[Hive] Closed box: pills');
    }
    if (Hive.isBoxOpen('role_regions')) {
      await Hive.box('role_regions').close();
      print('[Hive] Closed box: role_regions');
    }
    if (Hive.isBoxOpen('floating_island')) {
      await Hive.box('floating_island').close();
      print('[Hive] Closed box: floating_island');
    }
    if (Hive.isBoxOpen('noise_cache')) {
      await Hive.box<double>('noise_cache').close();
      print('[Hive] Closed box: noise_cache');
    }
    if (Hive.isBoxOpen('terrain_events')) {
      await Hive.box('terrain_events').close();
      print('[Hive] Closed box: terrain_events');
    }
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
      body: Stack(
        children: [
          AbsorbPointer(
            absorbing: _isResetting,
            child: GestureDetector(
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
                  Positioned(
                    top: 30,
                    right: 20,
                    child: NaiheInfoIcon(),
                  ),
                ],
              ),
            ),
          ),

          if (_isResetting)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.4),
                child: const Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
