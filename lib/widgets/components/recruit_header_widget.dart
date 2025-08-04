// 📄 lib/widgets/components/recruit_header_widget.dart
import 'package:flutter/material.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/dialogs/recruit_probability_dialog.dart';

class RecruitHeaderWidget extends StatelessWidget {
  const RecruitHeaderWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '灵缘客栈',
              style: TextStyle(
                fontSize: 18,
                color: Colors.white,
                fontFamily: 'ZcoolCangEr',
              ),
            ),
            IconButton(
              icon: const Icon(Icons.info_outline, color: Colors.white),
              onPressed: () {
                // 默认展示通用招募概率
                RecruitProbabilityDialog.show(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
