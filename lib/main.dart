import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xiu_to_xiandi_tuixiu/utils/route_observer.dart';

import 'models/disciple.dart';
import 'models/weapon.dart';
import 'models/pill.dart'; // ✅ 新增
import 'models/character.dart';
import 'pages/page_create_role.dart';
import 'pages/page_root.dart';
import 'widgets/effects/touch_effect_overlay.dart';
import 'services/cultivation_tracker.dart';
import 'utils/app_lifecycle_manager.dart';

void main() async {
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

  await Hive.initFlutter();
  Hive.registerAdapter(DiscipleAdapter());
  Hive.registerAdapter(WeaponAdapter());
  Hive.registerAdapter(PillAdapter()); // ✅ 注册丹药适配器
  Hive.registerAdapter(PillTypeAdapter()); // ✅ 注册丹药类型适配器

  final prefs = await SharedPreferences.getInstance();
  final playerStr = prefs.getString('playerData');

  bool hasCreatedRole = false;
  Character? player;

  if (playerStr != null && playerStr.isNotEmpty) {
    final playerJson = jsonDecode(playerStr);
    final playerId = playerJson['id'];
    if (playerId != null && playerId.toString().isNotEmpty) {
      hasCreatedRole = true;
      player = Character.fromJson(playerJson);
    }
  }

  // ✅ 修为系统初始化
  if (hasCreatedRole && player != null) {
    await CultivationTracker.initWithPlayer(player);
    CultivationTracker.startGlobalTick();
  }

  runApp(
    AppLifecycleManager( // ✅ 外层包裹
      child: XiudiApp(hasCreatedRole: hasCreatedRole),
    ),
  );
}

class XiudiApp extends StatelessWidget {
  final bool hasCreatedRole;
  const XiudiApp({super.key, required this.hasCreatedRole});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '修到仙帝退休',
      navigatorObservers: [routeObserver], // 🧠 注入 observer！
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
