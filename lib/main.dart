import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xiu_to_xiandi_tuixiu/utils/route_observer.dart';

import 'models/disciple.dart';
import 'models/weapon.dart';
import 'models/pill.dart';
import 'models/character.dart';
import 'pages/page_create_role.dart';
import 'pages/page_root.dart';
import 'widgets/effects/touch_effect_overlay.dart';
import 'utils/app_lifecycle_manager.dart';

void main() async {
  // ✅ 捕获最外层所有异常
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

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
    await Hive.initFlutter();

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
            hasCreatedRole ? const XiudiRoot() : const CreateRolePage(),
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
