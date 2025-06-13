import 'package:flutter/material.dart';
import 'package:xiu_to_xiandi_tuixiu/services/zongmen_storage.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/back_button_overlay.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/lianqi_header.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/zhushou_disciple_slot.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/refine_material_selector.dart'; // ⛏️ 后续封装组件
import '../models/zongmen.dart';

class LianqiPage extends StatefulWidget {
  const LianqiPage({super.key});

  @override
  State<LianqiPage> createState() => _LianqiPageState();
}

class _LianqiPageState extends State<LianqiPage> {
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
              Positioned.fill(
                child: Image.asset(
                  'assets/images/zongmen_bg_lianqifang.webp',
                  fit: BoxFit.cover,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 40),

                    /// 顶部标题 + 等级
                    LianqiHeader(level: level),

                    const SizedBox(height: 24),

                    /// 👇 特效区域空着，等锤子特效上场
                    Center(
                      child: Container(
                        width: 200,
                        height: 120,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          border: Border.all(color: Colors.white24),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          '（此处预留炼器特效）',
                          style: TextStyle(
                            color: Colors.white54,
                            fontFamily: 'ZcoolCangEr',
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    /// 材料选择组件
                    const RefineMaterialSelector(),

                    const SizedBox(height: 16),

                    /// 驻守弟子组件
                    const ZhushouDiscipleSlot(roomName: '炼器房'),
                  ],
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
