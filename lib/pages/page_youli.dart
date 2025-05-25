import 'package:flutter/material.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/world_map_image_view.dart';

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
    return Scaffold(
      backgroundColor: const Color(0xFFECECEC),
      body: Builder( // 👈 这里包一层 Builder 才能拿 context
        builder: (context) {
          final safePadding = MediaQuery.of(context).padding;
          return WorldMapImageView(safePadding: safePadding);
        },
      ),
    );
  }
}
