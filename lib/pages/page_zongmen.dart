import 'package:flutter/material.dart';
import 'package:flame/game.dart';

import 'package:xiu_to_xiandi_tuixiu/models/zongmen.dart';
import 'package:xiu_to_xiandi_tuixiu/models/disciple.dart';
import 'package:xiu_to_xiandi_tuixiu/pages/page_floating_island.dart';
import 'package:xiu_to_xiandi_tuixiu/services/zongmen_storage.dart';
import 'package:xiu_to_xiandi_tuixiu/services/resources_storage.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/back_button_overlay.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/create_zongmen_card.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/zongmen_header_widget.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/dialogs/upgrade_zongmen_dialog.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/common/toast_tip.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/zongmen_map_component.dart';

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
    return Scaffold(
      backgroundColor: const Color(0xFF0F0D0B),
      body: Stack(
        children: [
          // ✅ 修复黑屏：让地图组件填满整个页面
          Positioned.fill(
            child: _checkingZongmen || zongmen == null
                ? const SizedBox.shrink() // 或者 Loading 指示器
                : GameWidget(game: ZongmenMapComponent(
                sectLevel: zongmen!.sectLevel,
              context: context,
            )),
          ),

          if (zongmen != null) ...[
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
          ],

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

          BackButtonOverlay(targetPage: const FloatingIslandPage()),
        ],
      ),
    );
  }
}
