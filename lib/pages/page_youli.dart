import 'package:flutter/material.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/world_map_image_view.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/back_button_overlay.dart';

class YouliPage extends StatefulWidget {
  const YouliPage({super.key});

  @override
  State<YouliPage> createState() => _YouliPageState();
}

class _YouliPageState extends State<YouliPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final safePadding = MediaQuery.of(context).padding;

    return Scaffold(
      body: Stack(
        children: [
          // 地图背景
          Positioned.fill(
            child: WorldMapImageView(safePadding: safePadding),
          ),

          // 左下角返回按钮
          const BackButtonOverlay(),
        ],
      ),
    );
  }
}
