import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:xiu_to_xiandi_tuixiu/services/cultivation_tracker.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/effects/touch_effect_overlay.dart';
import 'models/disciple.dart';
import 'pages/page_create_role.dart';
import 'pages/page_root.dart';
import 'models/character.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ 沉浸式全屏（系统UI自动隐藏，滑动出现再自动隐藏）
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  // ✅ 透明状态栏和导航栏 + 白色图标
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

  // ✅ 判断是否已创建角色
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

  // ✅ 启动修为增长 Tracker（只在此处注册一次，全局通用）
  if (hasCreatedRole && player != null) {
    await CultivationTracker.initWithPlayer(player); // 💤 离线修为补算
    CultivationTracker.startGlobalTick();            // ⏱️ 每秒 tick，更新缓存
  }

  runApp(XiudiApp(hasCreatedRole: hasCreatedRole));
}

class XiudiApp extends StatelessWidget {
  final bool hasCreatedRole;
  const XiudiApp({super.key, required this.hasCreatedRole});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '修到仙帝退休',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'ZcoolCangEr',
        textTheme: const TextTheme(
          bodyMedium: TextStyle(fontSize: 18),
        ),
      ),
      home: Scaffold(
        body: Builder(
          builder: (context) {
            return Stack(
              children: [
                hasCreatedRole ? const XiudiRoot() : const CreateRolePage(),

                // ✅ 全局触摸特效（点击光圈）
                const TouchEffectOverlay(),

                const Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 40,
                  child: ColoredBox(color: Colors.transparent),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
