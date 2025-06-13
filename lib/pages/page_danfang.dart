import 'package:flutter/material.dart';
import 'package:xiu_to_xiandi_tuixiu/services/zongmen_storage.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/back_button_overlay.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/danfang_header.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/zhushou_disciple_slot.dart';
import '../widgets/effects/five_star_danfang_array.dart';
import '../models/zongmen.dart';

class DanfangPage extends StatefulWidget {
  const DanfangPage({super.key});

  @override
  State<DanfangPage> createState() => _DanfangPageState();
}

class _DanfangPageState extends State<DanfangPage> {
  bool hasStarted = false;
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
              Positioned.fill(
                child: Image.asset(
                  'assets/images/zongmen_bg_liandanfang.webp',
                  fit: BoxFit.cover,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 40),

                    /// 顶部标题 + 等级（已去除加号）
                    DanfangHeader(
                      level: level,
                    ),

                    const SizedBox(height: 24),

                    /// 阵法组件
                    Center(
                      child: FiveStarAlchemyArray(
                        key: _arrayKey,
                        radius: 150,
                        bigDanluSize: 200,
                        smallDanluSize: 100,
                      ),
                    ),

                    const SizedBox(height: 16),

                    /// 开始/结束炼丹按钮
                    Center(
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            if (hasStarted) {
                              _arrayKey.currentState?.stop();
                            } else {
                              _arrayKey.currentState?.start();
                            }
                            hasStarted = !hasStarted;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                        child: Text(hasStarted ? "结束炼丹" : "开始炼丹"),
                      ),
                    ),
                    /// 驻守弟子组件
                    const ZhushouDiscipleSlot(),
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
