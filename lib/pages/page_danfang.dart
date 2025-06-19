import 'package:flutter/material.dart';
import 'package:xiu_to_xiandi_tuixiu/services/zongmen_storage.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/back_button_overlay.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/danfang_header.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/zhushou_disciple_slot.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/alchemy_material_selector.dart'; // ✅ 引入新组件
import '../widgets/components/danfang_main_content.dart';
import '../widgets/effects/five_star_danfang_array.dart';
import '../models/zongmen.dart';

class DanfangPage extends StatefulWidget {
  const DanfangPage({super.key});

  @override
  State<DanfangPage> createState() => _DanfangPageState();
}

class _DanfangPageState extends State<DanfangPage> {
  final GlobalKey<FiveStarAlchemyArrayState> _arrayKey = GlobalKey();
  late Future<Zongmen?> _zongmenFuture;

  @override
  void initState() {
    super.initState();
    _zongmenFuture = ZongmenStorage.loadZongmen();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<Zongmen?>(
        future: _zongmenFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final zongmen = snapshot.data!;
          final level = ZongmenStorage.calcSectLevel(zongmen.sectExp);

          return Stack(
            children: [
              // 背景
              Positioned.fill(
                child: Image.asset(
                  'assets/images/zongmen_bg_liandanfang.webp',
                  fit: BoxFit.cover,
                ),
              ),

              // 页面内容
              DanfangMainContent(level: level, arrayKey: _arrayKey),

              /// ✅ 驻守弟子头像（右上角）
              const Positioned(
                bottom: 128,
                right: 24,
                child: ZhushouDiscipleSlot(
                  roomName: '炼丹房',
                  isRefining: false, // ✅ 如果你要支持切换
                ),
              ),

              const BackButtonOverlay(),
            ],
          );
        },
      ),
    );
  }
}
