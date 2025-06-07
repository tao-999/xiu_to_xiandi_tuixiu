import 'package:flutter/material.dart';
import 'package:xiu_to_xiandi_tuixiu/models/zongmen.dart';
import 'package:xiu_to_xiandi_tuixiu/models/disciple.dart';
import 'package:xiu_to_xiandi_tuixiu/services/zongmen_storage.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/back_button_overlay.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/create_zongmen_card.dart';
import 'package:xiu_to_xiandi_tuixiu/pages/page_disciples.dart';
import 'package:xiu_to_xiandi_tuixiu/pages/page_danfang.dart';
import 'package:xiu_to_xiandi_tuixiu/pages/page_cangjingge.dart';

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
          Positioned.fill(
            child: Image.asset(
              'assets/images/bg_zongmen_shiwaitaoyuan.webp',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(color: Colors.black.withOpacity(0.35)),
          ),
          if (zongmen != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.auto_awesome, color: Colors.orangeAccent),
                      const SizedBox(width: 8),
                      Text(
                        "宗门总览 - ${zongmen!.name}",
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFamily: 'ZcoolCangEr',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildZongmenInfoCard(),
                  const SizedBox(height: 16),
                  _buildResourceBar(),
                  const SizedBox(height: 16),
                  _buildQuickActions(context),
                ],
              ),
            ),

          // ✅ 创建宗门卡片层（首次进入无宗门时）
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

          const BackButtonOverlay(), // 返回按钮永远在最顶层
        ],
      ),
    );
  }

  Widget _buildZongmenInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.brown.shade200.withOpacity(0.25),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("宗门等级：${zongmen!.level}", style: _infoStyle()),
          const SizedBox(height: 8),
          Text("弟子数量：${disciples.length}", style: _infoStyle()),
        ],
      ),
    );
  }

  Widget _buildResourceBar() {
    final z = zongmen!;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _resItem("下品灵石", z.spiritStoneLow),
          _resItem("中品灵石", z.spiritStoneMid),
          _resItem("上品灵石", z.spiritStoneHigh),
          _resItem("极品灵石", z.spiritStoneSupreme),
        ],
      ),
    );
  }

  Widget _resItem(String name, int value) {
    return Column(
      children: [
        Text(name, style: const TextStyle(color: Colors.white70, fontFamily: 'ZcoolCangEr')),
        const SizedBox(height: 4),
        Text(
          "$value",
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontFamily: 'ZcoolCangEr',
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final actions = [
      ["弟子管理", Icons.group, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DiscipleListPage()))],
      ["任务派遣", Icons.task_alt, () => _toast(context, "任务派遣模块开发中")],
      ["升级宗门", Icons.auto_fix_high, () => _toast(context, "升级功能开发中")],
      ["炼丹房", Icons.local_pharmacy, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DanfangPage()))],
      ["藏经阁", Icons.menu_book, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CangjinggePage()))],
      ["灵田", Icons.grass, () => _toast(context, "灵田开发中")],
      ["洞天福地", Icons.park, () => _toast(context, "洞天福地开发中")],
      ["宗门职位", Icons.chair_alt, () => _toast(context, "职位系统开发中")],
      ["历代志", Icons.history_edu, () => _toast(context, "宗门事件记录开发中")],
    ];

    return Expanded(
      child: GridView.count(
        crossAxisCount: 3,
        childAspectRatio: 1,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        children: actions.map((action) {
          return _quickButton(action[0] as String, action[1] as IconData, action[2] as VoidCallback);
        }).toList(),
      ),
    );
  }

  Widget _quickButton(String label, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: Colors.orangeAccent),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(color: Colors.white, fontFamily: 'ZcoolCangEr')),
          ],
        ),
      ),
    );
  }

  TextStyle _infoStyle() {
    return const TextStyle(fontSize: 16, color: Colors.white70, fontFamily: 'ZcoolCangEr');
  }

  void _toast(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontFamily: 'ZcoolCangEr')),
      duration: const Duration(seconds: 2),
    ));
  }
}
