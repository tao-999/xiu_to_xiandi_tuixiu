import 'package:flutter/material.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/zongmen_map_component.dart'; // 等下你建这文件

class ZongmenPage extends StatefulWidget {
  const ZongmenPage({super.key});

  @override
  State<ZongmenPage> createState() => _ZongmenPageState();
}

class _ZongmenPageState extends State<ZongmenPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return const Scaffold(
      backgroundColor: Colors.black,
      body: ZongmenMapComponent(), // 👈 放地图组件
    );
  }
}
