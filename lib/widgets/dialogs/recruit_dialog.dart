import 'package:flutter/material.dart';

import 'package:xiu_to_xiandi_tuixiu/widgets/components/recruit_header_widget.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/recruit_illustration_widget.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/recruit_action_panel.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/dialogs/disciple_list_dialog.dart';

import '../../services/resources_storage.dart';

class RecruitDialog extends StatefulWidget {
  final VoidCallback? onChanged;

  const RecruitDialog({super.key, this.onChanged});

  @override
  State<RecruitDialog> createState() => _RecruitDialogState();
}

class _RecruitDialogState extends State<RecruitDialog> {
  String currentPool = 'human';
  int ticketCount = 0;

  @override
  void initState() {
    super.initState();
    _loadTicketCount();
  }

  Future<void> _loadTicketCount() async {
    final countBigInt = await ResourcesStorage.getValue('recruitTicket');
    setState(() {
      ticketCount = countBigInt.toInt();
    });
    widget.onChanged?.call(); // 通用通知外层刷新
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
        side: BorderSide.none,
      ),
      insetPadding: const EdgeInsets.all(40),
      child: Container(
        width: 420,
        height: 720,
        decoration: BoxDecoration(
          color: const Color(0xFFFFF8DC),
          borderRadius: BorderRadius.zero,
        ),
        child: Stack(
          children: [
            // 背景
            Positioned.fill(
              child: Image.asset(
                'assets/images/paper_lantern_inn.webp',
                fit: BoxFit.cover,
              ),
            ),
            // 顶部标题
            RecruitHeaderWidget(),
            // 中部按钮 + 招募券
            Align(
              alignment: Alignment.center,
              child: RecruitActionPanel(
                onRecruitFinished: _loadTicketCount,
              ),
            ),
            // 立绘
            RecruitIllustrationWidget(),
            // 弟子列表按钮
            DiscipleListDialog.showButton(context),
          ],
        ),
      ),
    );
  }
}
