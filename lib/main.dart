import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xiu_to_xiandi_tuixiu/services/cultivation_tracker.dart';

import 'pages/page_create_role.dart';
import 'pages/page_root.dart';
import 'models/character.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化修为系统
  await CultivationTracker.init();

  // 判断是否已创建角色（根据 playerData 是否存在 + id 是否为空）
  final prefs = await SharedPreferences.getInstance();
  final playerStr = prefs.getString('playerData');

  bool hasCreatedRole = false;
  if (playerStr != null && playerStr.isNotEmpty) {
    final playerJson = jsonDecode(playerStr);
    final playerId = playerJson['id'];
    hasCreatedRole = playerId != null && playerId.toString().isNotEmpty;
  }
  if (hasCreatedRole) {
    final playerJson = jsonDecode(playerStr!);
    final player = Character.fromJson(playerJson);
    CultivationTracker.startTickWithPlayer(player);
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
