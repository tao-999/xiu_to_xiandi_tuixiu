import 'package:flutter/material.dart';
import 'package:xiu_to_xiandi_tuixiu/pages/page_disciples.dart';
import 'package:xiu_to_xiandi_tuixiu/pages/page_danfang.dart';
import 'package:xiu_to_xiandi_tuixiu/pages/page_cangjingge.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/common/toast_tip.dart';
import 'package:xiu_to_xiandi_tuixiu/pages/page_task_dispatch.dart';
import 'package:xiu_to_xiandi_tuixiu/pages/page_lianqi.dart';

class ZongmenQuickMenu extends StatelessWidget {
  const ZongmenQuickMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final actions = [
      ["弟子管理", "dizi", () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DiscipleListPage()))],
      ["任务派遣", "renwu", () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TaskDispatchPage()))],
      ["升级宗门", "shengji", () => ToastTip.show(context, "升级功能开发中")],
      ["炼丹房", "liandan", () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DanfangPage()))],
      ["炼器房", "lianqi", () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LianqiPage()))],
      ["藏经阁", "gongfa", () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CangjinggePage()))],
      ["灵田", "lingtian", () => ToastTip.show(context, "灵田开发中")],
      ["洞天福地", "dongtianfudi", () => ToastTip.show(context, "洞天福地开发中")],
      ["宗门职位", "zhiwei", () => ToastTip.show(context, "职位系统开发中")],
      ["外交", "waijiao", () => ToastTip.show(context, "外交系统开发中")],
      ["历代志", "lidaizhi", () => ToastTip.show(context, "宗门事件记录开发中")],
    ];

    return Expanded(
      child: GridView.count(
        crossAxisCount: 4,              // ✅ 每行 4 项
        childAspectRatio: 0.85,         // ✅ 更紧凑些
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        children: actions.map((action) {
          return _quickButton(
            label: action[0] as String,
            iconName: action[1] as String,
            onTap: action[2] as VoidCallback,
          );
        }).toList(),
      ),
    );
  }

  Widget _quickButton({
    required String label,
    required String iconName,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/zongmen_$iconName.png',
              width: 60,
              height: 60,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white,
                fontFamily: 'ZcoolCangEr',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
