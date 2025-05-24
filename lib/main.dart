import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'pages/page_create_role.dart';
import 'pages/page_root.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化 Hive 本地存储
  await Hive.initFlutter();
  await Hive.openBox('player');

  // 判断是否已创建角色（以是否存在 playerId 为准）
  final box = Hive.box('player');
  final playerId = box.get('playerId');
  final hasCreatedRole = playerId != null && playerId.toString().isNotEmpty;

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
      theme: ThemeData.dark(),
      home: hasCreatedRole ? const XiudiRoot() : const CreateRolePage(),
    );
  }
}
