// 📄 lib/widgets/components/recruit_header_widget.dart
import 'package:flutter/material.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/dialogs/recruit_probability_dialog.dart';

class RecruitHeaderWidget extends StatelessWidget {
  final String currentPool;
  final Function(String pool) onPoolChanged;

  const RecruitHeaderWidget({
    super.key,
    required this.currentPool,
    required this.onPoolChanged,
  });

  Widget _buildTabButton(BuildContext context, String pool, String label, {bool disabled = false}) {
    final bool isSelected = currentPool == pool;
    return Expanded(
      child: GestureDetector(
        onTap: disabled ? null : () => onPoolChanged(pool),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: disabled ? Border.all(color: Colors.white24) : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              color: disabled
                  ? Colors.white38
                  : (isSelected ? Colors.black87 : Colors.white),
              fontWeight: FontWeight.bold,
              fontSize: 16,
              fontFamily: 'ZcoolCangEr',
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 顶部标题 + info按钮
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '灵缘客栈',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontFamily: 'ZcoolCangEr',
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.info_outline, color: Colors.white),
                  onPressed: () {
                    RecruitProbabilityDialog.show(
                      context,
                      currentPool == 'human'
                          ? RecruitPoolType.human
                          : RecruitPoolType.immortal,
                    );
                  },
                ),
              ],
            ),
          ),

          // Tab切换栏
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  _buildTabButton(context, 'human', '人界招募'),
                  _buildTabButton(context, 'immortal', '仙界招募', disabled: true),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
