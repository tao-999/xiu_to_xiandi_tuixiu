import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:xiu_to_xiandi_tuixiu/pages/page_create_role.dart';
import 'package:xiu_to_xiandi_tuixiu/pages/page_floating_island.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/back_button_overlay.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/typewriter_poem_section.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/mengpo_soup_dialog.dart';

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

    await Hive.close();             // ✅ 这句会关掉所有已开的 box
    await Hive.deleteFromDisk();
    await nukeHiveStorage();

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
    debugPrint('📂 Hive 存储目录: ${dir.path}');

    final folder = Directory(dir.path);
    final files = folder.listSync(recursive: false); // 只删根目录文件

    for (final entity in files) {
      if (entity is File) {
        try {
          await entity.delete();
          debugPrint('🔥 删除文件: ${entity.path}');
        } catch (e) {
          debugPrint('⚠️ 删除失败: ${entity.path}，原因：$e');
        }
      }
    }

    debugPrint('✅ Hive 存储目录下所有文件已清空');
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
                  BackButtonOverlay(targetPage: const FloatingIslandPage()),
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