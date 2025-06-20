import 'package:flutter/material.dart';
import 'package:xiu_to_xiandi_tuixiu/services/zongmen_storage.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/back_button_overlay.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/zhushou_disciple_slot.dart';
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

  bool _isRefining = false; // ✅ 控制是否正在炼丹
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    _zongmenFuture = ZongmenStorage.loadZongmen();
  }

  /// ✅ 接收来自 DanfangMainContent 的炼丹状态回调
  void _updateRefiningState(bool value) {
    if (mounted && _isRefining != value) {
      setState(() {
        _isRefining = value;
      });
    }
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
              DanfangMainContent(
                level: level,
                arrayKey: _arrayKey,
                onRefineStateChanged: _updateRefiningState, // ✅ 接收炼丹状态
                onAnimationStateChanged: (bool value) {
                  if (mounted) {
                    setState(() {
                      _isAnimating = value; // 控制罩子
                    });
                  }
                },
              ),

              // ✅ 驻守弟子（炼丹中不能点击）
              Positioned(
                bottom: 128,
                right: 24,
                child: ZhushouDiscipleSlot(
                  roomName: '炼丹房',
                  isRefining: _isRefining, // ✅ 控制是否允许点击
                ),
              ),

              if (_isAnimating)
                IgnorePointer(
                  ignoring: false,
                  child: Container(
                    color: Colors.transparent,
                    width: double.infinity,
                    height: double.infinity,
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
