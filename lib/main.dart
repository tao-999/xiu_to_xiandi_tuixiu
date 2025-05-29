import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xiu_to_xiandi_tuixiu/services/cultivation_tracker.dart';

import 'pages/page_create_role.dart';
import 'pages/page_root.dart';
import 'models/character.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 判断是否已创建角色（根据 playerData 是否存在 + id 是否为空）
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

  // ✅ 用角色数据初始化 Tracker（用 player.cultivation 作为修为起点）
  if (hasCreatedRole && player != null) {
    CultivationTracker.startTickWithPlayer();
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
      home: hasCreatedRole ? const XiudiRoot() : const CreateRolePage(),
    );
  }
}
