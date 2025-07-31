import 'dart:async';
import 'dart:convert';
import 'dart:io'; // ✅ 新增：平台判断
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_size/window_size.dart'; // ✅ 新增：窗口控制
import 'package:xiu_to_xiandi_tuixiu/pages/page_floating_island.dart';
import 'package:xiu_to_xiandi_tuixiu/utils/route_observer.dart';

import 'models/disciple.dart';
import 'models/weapon.dart';
import 'models/pill.dart';
import 'models/character.dart';
import 'pages/page_create_role.dart';
import 'widgets/effects/touch_effect_overlay.dart';
import 'utils/app_lifecycle_manager.dart';

void main() async {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // ✅ 桌面端设置窗口标题和最小尺寸
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      setWindowTitle('修到仙帝退休 · 桌面版');
      setWindowMinSize(const Size(1280, 720));
    }

    // ✅ 沉浸式 + 白色图标
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.black,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );

    debugPrint('✅ 准备初始化 Hive...');
    // ✅ 获取安全的应用目录（不要用 getApplicationDocumentsDirectory，会踩坑）
    final Directory dir = await getApplicationSupportDirectory();
    Hive.init(dir.path); // ✅ 手动指定路径，避免“拒绝访问”错误

    // ✅ 注册所有模型
    Hive.registerAdapter(DiscipleAdapter());
    Hive.registerAdapter(WeaponAdapter());
    Hive.registerAdapter(PillAdapter());
    Hive.registerAdapter(PillTypeAdapter());
    debugPrint('✅ Hive 注册完成');

    bool hasCreatedRole = false;
    Character? player;

    try {
      final prefs = await SharedPreferences.getInstance();
      final playerStr = prefs.getString('playerData');
      debugPrint('✅ 读取 SharedPreferences 成功');

      if (playerStr != null && playerStr.isNotEmpty) {
        final playerJson = jsonDecode(playerStr);
        debugPrint('✅ playerData 解码成功：$playerJson');

        final playerId = playerJson['id'];
        if (playerId != null && playerId.toString().isNotEmpty) {
          hasCreatedRole = true;
          player = Character.fromJson(playerJson);
          debugPrint('✅ 角色对象初始化成功：${player.name}');
        }
      } else {
        debugPrint('⚠️ 未找到 playerData，进入创建角色页');
      }
    } catch (e, stack) {
      debugPrint('❌ 初始化过程异常：$e');
      debugPrintStack(stackTrace: stack);
    }

    runApp(
      AppLifecycleManager(
        child: XiudiApp(hasCreatedRole: hasCreatedRole),
      ),
    );
  }, (error, stack) {
    debugPrint('❌ 捕获到未处理异常：$error');
    debugPrintStack(stackTrace: stack);
  });
}

class XiudiApp extends StatelessWidget {
  final bool hasCreatedRole;
  const XiudiApp({super.key, required this.hasCreatedRole});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '修到仙帝退休',
      navigatorObservers: [routeObserver],
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'ZcoolCangEr',
        textTheme: const TextTheme(
          bodyMedium: TextStyle(fontSize: 18),
        ),
      ),
      home: Scaffold(
        body: Stack(
          children: [
            hasCreatedRole ? const FloatingIslandPage() : const CreateRolePage(),
            const TouchEffectOverlay(),
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 40,
              child: ColoredBox(color: Colors.transparent),
            ),
          ],
        ),
      ),
    );
  }
}
