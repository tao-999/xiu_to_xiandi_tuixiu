import 'package:flutter/material.dart';
import 'package:xiu_to_xiandi_tuixiu/models/disciple.dart';
import 'package:xiu_to_xiandi_tuixiu/services/player_storage.dart';
import 'package:xiu_to_xiandi_tuixiu/services/disciple_factory.dart';
import 'package:xiu_to_xiandi_tuixiu/services/disciple_storage.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/recruit_card_widget.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/common/toast_tip.dart';

class RecruitActionPanel extends StatefulWidget {
  final String currentPool;

  /// 招募结束后的回调，可用于通知外部刷新招募券
  final VoidCallback? onRecruitFinished;

  const RecruitActionPanel({
    super.key,
    required this.currentPool,
    this.onRecruitFinished,
  });

  @override
  State<RecruitActionPanel> createState() => _RecruitActionPanelState();
}

class _RecruitActionPanelState extends State<RecruitActionPanel> {
  int ticketCount = 0;

  @override
  void initState() {
    super.initState();
    _loadTickets();
  }

  Future<void> _loadTickets() async {
    final player = await PlayerStorage.getPlayer();
    final count = player?.resources.humanRecruitTicket ?? 0;
    if (mounted) {
      setState(() {
        ticketCount = count;
      });
    }
  }

  Future<void> _doRecruit(int count) async {
    final player = await PlayerStorage.getPlayer();
    if (player == null) return;

    // 🎟 检查招募券
    if (widget.currentPool == 'human') {
      if (player.resources.humanRecruitTicket < count) {
        ToastTip.show(context, '招募券不足，无法招募');
        return;
      }

      player.resources.humanRecruitTicket -= count;
      await PlayerStorage.savePlayer(player);
      if (mounted) {
        setState(() {
          ticketCount = player.resources.humanRecruitTicket;
        });
      }
    }

    // 🧙‍♂️ 生成弟子
    final List<Disciple> newList = await Future.wait(
      List.generate(count, (_) => DiscipleFactory.generateRandom(pool: widget.currentPool)),
    );
    await DiscipleStorage.addAll(newList);

    if (!mounted) return;

    // 💳 展示招募结果卡片
    showDialog(
      context: context,
      builder: (_) => RecruitCardWidget(disciples: newList),
    );

    // 🔁 通知外部刷新
    widget.onRecruitFinished?.call();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 100, 24, 140),
      child: Column(
        children: [
          // 🎯 招募按钮组
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: () => _doRecruit(1),
                icon: const Icon(Icons.star),
                label: const Text("招募一次"),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: () => _doRecruit(10),
                icon: const Icon(Icons.auto_awesome),
                label: const Text("招募十次"),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // 🧾 招募券显示
          if (widget.currentPool == 'human')
            Text(
              '人界招募券：$ticketCount',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white70,
                fontFamily: 'ZcoolCangEr',
              ),
            ),
        ],
      ),
    );
  }
}
