import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/back_button_overlay.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/youli_map_game.dart'; // 👈 注意导入

class YouliPage extends StatefulWidget {
  const YouliPage({super.key});

  @override
  State<YouliPage> createState() => _YouliPageState();
}

class _YouliPageState extends State<YouliPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  late final YouliMapGame _game;

  @override
  void initState() {
    super.initState();
    _game = YouliMapGame();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      body: Stack(
        children: [
          // ✅ 地图背景：用 Flame Game 渲染
          GameWidget(game: _game),

          // ✅ 左下角返回按钮悬浮
          const BackButtonOverlay(),
        ],
      ),
    );
  }
}
