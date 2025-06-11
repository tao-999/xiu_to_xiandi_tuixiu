// lib/widgets/components/recruit_action_panel.dart
import 'package:flutter/material.dart';
import 'package:xiu_to_xiandi_tuixiu/models/disciple.dart';
import 'package:xiu_to_xiandi_tuixiu/services/player_storage.dart';
import 'package:xiu_to_xiandi_tuixiu/services/disciple_factory.dart';
import 'package:xiu_to_xiandi_tuixiu/services/disciple_storage.dart';
import 'package:xiu_to_xiandi_tuixiu/services/disciple_registry.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/recruit_card_widget.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/common/toast_tip.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/dialogs/disciple_preview_dialog.dart';

class RecruitActionPanel extends StatefulWidget {
  final VoidCallback? onRecruitFinished;

  const RecruitActionPanel({
    super.key,
    this.onRecruitFinished,
  });

  @override
  State<RecruitActionPanel> createState() => _RecruitActionPanelState();
}

class _RecruitActionPanelState extends State<RecruitActionPanel> {
  int ticketCount = 0;
  int totalDraws = 0;
  int drawsUntilSSR = 80;
  bool poolEmpty  = false; // ✅ 新增：是否已抽光美少女

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    final player = await PlayerStorage.getPlayer();
    final count = player?.resources.humanRecruitTicket ?? 0;
    final draws = await DiscipleStorage.getTotalDraws();
    final untilSSR = await DiscipleStorage.getDrawsUntilSSR();

    // ✅ 调用你封装好的函数
    final empty = await isSsrPoolEmpty();

    if (mounted) {
      setState(() {
        ticketCount = count;
        totalDraws = draws;
        drawsUntilSSR = untilSSR;
        poolEmpty  = empty;
      });
    }
  }

  Future<void> _doRecruit(int count) async {
    final player = await PlayerStorage.getPlayer();
    if (player == null) return;

    if (player.resources.humanRecruitTicket < count) {
      ToastTip.show(context, '招募券不足，无法招募');
      return;
    }

    player.resources.humanRecruitTicket -= count;
    await PlayerStorage.savePlayer(player);
    await DiscipleStorage.incrementTotalDraws(count);

    final List<Disciple> newList = [];
    for (int i = 0; i < count; i++) {
      final d = await DiscipleFactory.generateRandom();
      await DiscipleRegistry.markOwned(d.aptitude);
      newList.add(d);
    }

    await DiscipleStorage.addAll(newList);

    int? lastSSRIndex;
    for (int i = count - 1; i >= 0; i--) {
      final d = newList[i];
      if (d.aptitude >= 31) {
        lastSSRIndex = i;
        break;
      }
    }

    if (lastSSRIndex != null) {
      final afterSSR = count - lastSSRIndex - 1;
      final resetValue = 80 - afterSSR;
      await DiscipleStorage.setDrawsUntilSSR(resetValue);
      drawsUntilSSR = resetValue;
    } else {
      await DiscipleStorage.incrementDrawsUntilSSR(count, hitSSR: false);
      drawsUntilSSR -= count;
    }

    totalDraws += count;
    ticketCount = player.resources.humanRecruitTicket;
    poolEmpty  = await isSsrPoolEmpty(); // ✅ 刷新状态
    if (mounted) setState(() {});

    showDialog(
      context: context,
      builder: (_) => RecruitCardWidget(disciples: newList),
    );
    widget.onRecruitFinished?.call();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 100, 24, 140),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: () => _doRecruit(1),
                icon: const Icon(Icons.star),
                label: const Text('招募一次'),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: () => _doRecruit(10),
                icon: const Icon(Icons.auto_awesome),
                label: const Text('招募十次'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '招募券：$ticketCount',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                  fontFamily: 'ZcoolCangEr',
                ),
              ),
              IconButton(
                icon: const Icon(Icons.visibility, color: Colors.white70, size: 20),
                onPressed: () => showDisciplePreviewDialog(context),
                tooltip: '预览资质角色',
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '抽卡次数：$totalDraws',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                  fontFamily: 'ZcoolCangEr',
                ),
              ),
              const SizedBox(width: 16),
              if (!poolEmpty)
                Text(
                  '$drawsUntilSSR 抽必出美少女立绘',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                    fontFamily: 'ZcoolCangEr',
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

