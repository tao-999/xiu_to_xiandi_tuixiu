import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/back_button_overlay.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/youli_map_game.dart';

class YouliPage extends StatefulWidget {
  const YouliPage({super.key});

  @override
  State<YouliPage> createState() => _YouliPageState();
}

class _YouliPageState extends State<YouliPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  late YouliMapGame _game;

  @override
  void initState() {
    super.initState();
    // 暂不在 initState 初始化，改为 build 时延迟构造（因为 context 在 initState 不能安全使用）
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    // 每次构造 Game 实例（保证 context 可用）
    _game = YouliMapGame(context);

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
