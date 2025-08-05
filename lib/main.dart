import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';
import 'package:xiu_to_xiandi_tuixiu/services/treasure_chest_storage.dart';

import 'models/character.dart';
import 'models/disciple.dart';
import 'models/pill.dart';
import 'models/weapon.dart';
import 'pages/page_create_role.dart';
import 'pages/page_floating_island.dart';
import 'utils/app_lifecycle_manager.dart';
import 'utils/route_observer.dart';
import 'widgets/effects/touch_effect_overlay.dart';

void main() async {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    await windowManager.ensureInitialized();

    // ✅ 沉浸式 UI 设置
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.black,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );

    debugPrint('✅ 正在初始化 Hive...');
    final Directory dir = await getApplicationSupportDirectory();
    Hive.init(dir.path);

    // ✅ 注册模型
    Hive.registerAdapter(DiscipleAdapter());
    Hive.registerAdapter(WeaponAdapter());
    Hive.registerAdapter(PillAdapter());
    Hive.registerAdapter(PillTypeAdapter());
    debugPrint('✅ Hive 模型注册完成');

    await TreasureChestStorage.preloadAllOpenedStates();

    bool hasCreatedRole = false;
    Character? player;

    try {
      final prefs = await SharedPreferences.getInstance();
      final playerStr = prefs.getString('playerData');
      debugPrint('✅ SharedPreferences 读取成功');

      if (playerStr != null && playerStr.isNotEmpty) {
        final playerJson = jsonDecode(playerStr);
        debugPrint('✅ playerData 解码成功：$playerJson');

        final playerId = playerJson['id'];
        if (playerId != null && playerId.toString().isNotEmpty) {
          hasCreatedRole = true;
          player = Character.fromJson(playerJson);
          debugPrint('✅ 玩家对象创建成功：${player.name}');
        }
      } else {
        debugPrint('⚠️ 未检测到玩家数据，准备跳转创建角色页');
      }
    } catch (e, stack) {
      debugPrint('❌ 初始化错误：$e');
      debugPrintStack(stackTrace: stack);
    }

    runApp(
      AppLifecycleManager(
        child: XiudiApp(hasCreatedRole: hasCreatedRole),
      ),
    );
  }, (error, stack) {
    debugPrint('❌ 全局异常：$error');
    debugPrintStack(stackTrace: stack);
  });
}

class XiudiApp extends StatelessWidget {
  final bool hasCreatedRole;
  const XiudiApp({super.key, required this.hasCreatedRole});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '宗主请留步',
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
            hasCreatedRole
                ? const FloatingIslandPage()
                : const CreateRolePage(),
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
