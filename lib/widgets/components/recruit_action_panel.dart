// lib/widgets/components/recruit_action_panel.dart

import 'package:flutter/material.dart';
import 'package:xiu_to_xiandi_tuixiu/models/disciple.dart';
import 'package:xiu_to_xiandi_tuixiu/services/disciple_factory.dart';
import 'package:xiu_to_xiandi_tuixiu/services/disciple_storage.dart';
import 'package:xiu_to_xiandi_tuixiu/services/disciple_registry.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/recruit_card_widget.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/common/toast_tip.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/dialogs/disciple_preview_dialog.dart';

import '../../services/resources_storage.dart';
import '../../utils/shared_prefs_debugger.dart';

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
  bool poolEmpty = false;

  bool isRecruiting = false; // ✅ 防止连点标识

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    final count = (await ResourcesStorage.getValue('recruitTicket')).toInt();
    final draws = await DiscipleStorage.getTotalDraws();
    final untilSSR = await DiscipleStorage.getDrawsUntilSSR();
    final empty = await isSsrPoolEmpty();

    if (mounted) {
      setState(() {
        ticketCount = count;
        totalDraws = draws;
        drawsUntilSSR = untilSSR;
        poolEmpty = empty;
      });
    }
  }

  Future<void> _doRecruit(int count) async {
    if (isRecruiting) return; // ✅ 阻止重复点击
    isRecruiting = true;

    try {
      final ticket = await ResourcesStorage.getValue('recruitTicket');
      if (ticket < BigInt.from(count)) {
        ToastTip.show(context, '招募券不足，无法招募');
        return;
      }

      await ResourcesStorage.subtract('recruitTicket', BigInt.from(count));
      await DiscipleStorage.incrementTotalDraws(count);

      final List<Disciple> newList = [];
      for (int i = 0; i < count; i++) {
        final d = await DiscipleFactory.generateRandom();
        await DiscipleRegistry.markOwned(d.aptitude);
        newList.add(d);
      }

      await Future.wait(newList.map(DiscipleStorage.save));

      int? lastSSRIndex;
      for (int i = count - 1; i >= 0; i--) {
        if (newList[i].aptitude >= 31) {
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

      ticketCount = (await ResourcesStorage.getValue('recruitTicket')).toInt();
      totalDraws += count;
      poolEmpty = await isSsrPoolEmpty();

      if (mounted) setState(() {});

      showDialog(
        context: context,
        builder: (_) => RecruitCardWidget(disciples: newList),
      );

      widget.onRecruitFinished?.call();
      SharedPrefsDebugger.printPrefsSizeDetail();
    } finally {
      isRecruiting = false; // ✅ 解锁
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            InkWell(
              onTap: () => _doRecruit(1),
              borderRadius: BorderRadius.zero,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.star, color: Colors.orange),
                    SizedBox(width: 6),
                    Text(
                      '招募一次',
                      style: TextStyle(
                        fontSize: 16,
                        fontFamily: 'ZcoolCangEr',
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            InkWell(
              onTap: () => _doRecruit(10),
              borderRadius: BorderRadius.zero,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.auto_awesome, color: Colors.deepOrange),
                    SizedBox(width: 6),
                    Text(
                      '招募十次',
                      style: TextStyle(
                        fontSize: 16,
                        fontFamily: 'ZcoolCangEr',
                        color: Colors.deepOrange,
                      ),
                    ),
                  ],
                ),
              ),
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
                fontSize: 13,
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
                fontSize: 12,
                color: Colors.white70,
                fontFamily: 'ZcoolCangEr',
              ),
            ),
            const SizedBox(width: 16),
            if (!poolEmpty)
              Text(
                '$drawsUntilSSR 抽必出美少女立绘',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white70,
                  fontFamily: 'ZcoolCangEr',
                ),
              ),
          ],
        ),
      ],
    );
  }
}
