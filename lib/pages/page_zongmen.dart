import 'package:flutter/material.dart';
import 'package:xiu_to_xiandi_tuixiu/models/zongmen.dart';
import 'package:xiu_to_xiandi_tuixiu/models/disciple.dart';
import 'package:xiu_to_xiandi_tuixiu/services/zongmen_storage.dart';
import 'package:xiu_to_xiandi_tuixiu/services/resources_storage.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/back_button_overlay.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/create_zongmen_card.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/zongmen_header_widget.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/zongmen_quick_menu.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/dialogs/upgrade_zongmen_dialog.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/common/toast_tip.dart';

class ZongmenPage extends StatefulWidget {
  const ZongmenPage({super.key});

  @override
  State<ZongmenPage> createState() => _ZongmenPageState();
}

class _ZongmenPageState extends State<ZongmenPage> {
  Zongmen? zongmen;
  List<Disciple> disciples = [];
  bool _checkingZongmen = true;
  bool _showCreateCard = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final stored = await ZongmenStorage.loadZongmen();
    if (stored == null) {
      setState(() {
        _showCreateCard = true;
        _checkingZongmen = false;
      });
    } else {
      final list = await ZongmenStorage.loadDisciples();
      setState(() {
        zongmen = stored;
        disciples = list;
        _checkingZongmen = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingZongmen) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.orangeAccent)),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F0D0B),
      body: Stack(
        children: [
          // 背景图及遮罩
          Positioned.fill(
            child: Image.asset(
              'assets/images/bg_zongmen_shiwaitaoyuan.webp',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(color: Colors.black.withOpacity(0.35)),
          ),

          if (zongmen != null) ...[
            // ✅ 左上角宗门信息
            Positioned(
              left: 16,
              top: 36,
              child: ZongmenHeaderWidget(
                zongmen: zongmen!,
                onUpgrade: () async {
                  final required = ZongmenStorage.requiredStones(zongmen!.sectLevel);
                  final res = await ResourcesStorage.load();
                  final has = res.spiritStoneLow;

                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (_) => UpgradeZongmenDialog(
                      currentStones: has,
                      requiredStones: required,
                    ),
                  );

                  if (confirmed == true) {
                    final newZongmen = await ZongmenStorage.upgradeSectLevel(zongmen!);
                    setState(() => zongmen = newZongmen);
                    ToastTip.show(context, '✨宗门升级成功！');
                  }
                },
              ),
            ),

            // ✅ 中央居中菜单
            const Center(child: ZongmenQuickMenu()),
          ],

          // 创建宗门
          if (_showCreateCard)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.5),
                child: CreateZongmenCard(
                  onConfirm: (name) async {
                    final newZongmen = Zongmen(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      name: name,
                      founderName: '你自己',
                      emblemPath: 'assets/images/emblem_default.png',
                      specialization: '未知',
                    );
                    await ZongmenStorage.saveZongmen(newZongmen);
                    final list = await ZongmenStorage.loadDisciples();
                    setState(() {
                      zongmen = newZongmen;
                      disciples = list;
                      _showCreateCard = false;
                    });
                  },
                ),
              ),
            ),

          // 返回按钮
          const BackButtonOverlay(),
        ],
      ),
    );
  }
}
