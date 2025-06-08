import 'package:flutter/material.dart';
import 'package:xiu_to_xiandi_tuixiu/services/player_storage.dart';

import 'package:xiu_to_xiandi_tuixiu/widgets/components/back_button_overlay.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/recruit_header_widget.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/recruit_illustration_widget.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/recruit_action_panel.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/dialogs/disciple_list_dialog.dart';

class ZhaomuPage extends StatefulWidget {
  const ZhaomuPage({super.key});

  @override
  State<ZhaomuPage> createState() => _ZhaomuPageState();
}

class _ZhaomuPageState extends State<ZhaomuPage> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  String currentPool = 'human';
  int ticketCount = 0;

  @override
  void initState() {
    super.initState();
    _loadTicketCount();
  }

  Future<void> _loadTicketCount() async {
    final player = await PlayerStorage.getPlayer();
    final count = player?.resources.humanRecruitTicket ?? 0;
    setState(() {
      ticketCount = count;
    });
  }

  void _changePool(String pool) {
    if (pool == currentPool) return;
    setState(() {
      currentPool = pool;
    });
    _loadTicketCount();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // 🖼 背景图
          Positioned.fill(
            child: Image.asset(
              'assets/images/paper_lantern_inn.webp',
              fit: BoxFit.cover,
            ),
          ),

          // 📍顶部标题 + 池切换
          RecruitHeaderWidget(
            currentPool: currentPool,
            onPoolChanged: _changePool,
          ),

          // 🎯 中部按钮 + 招募券
          Align(
            alignment: Alignment.center,
            child: RecruitActionPanel(
              currentPool: currentPool,
              onRecruitFinished: _loadTicketCount,
            ),
          ),

          // 🧍‍♀️立绘图
          RecruitIllustrationWidget(pool: currentPool),

          // 🔙 返回按钮
          const BackButtonOverlay(),

          // 📋 弟子列表按钮
          DiscipleListDialog.showButton(context),
        ],
      ),
    );
  }
}
