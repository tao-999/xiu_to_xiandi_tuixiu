import 'package:flutter/material.dart';
import 'package:xiu_to_xiandi_tuixiu/models/disciple.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/back_button_overlay.dart';
import 'package:xiu_to_xiandi_tuixiu/services/disciple_factory.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/dialogs/recruit_probability_dialog.dart';
import 'package:xiu_to_xiandi_tuixiu/services/player_storage.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/recruit_card_widget.dart';
import 'package:xiu_to_xiandi_tuixiu/services/disciple_storage.dart';
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

  Future<void> _recruit({int count = 1}) async {
    final player = await PlayerStorage.getPlayer();
    if (player == null) return;

    // ✅ 检查人界招募券
    if (currentPool == 'human') {
      final current = player.resources.humanRecruitTicket;
      if (current < count) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('招募券不足，无法招募')),
        );
        return;
      }

      player.resources.humanRecruitTicket -= count;
      await PlayerStorage.savePlayer(player);
      setState(() {
        ticketCount = player.resources.humanRecruitTicket;
      });
    }

    // ✅ 生成修士列表
    final List<Disciple> newList = await Future.wait(
      List.generate(count, (_) => DiscipleFactory.generateRandom(pool: currentPool)),
    );
    await DiscipleStorage.addAll(newList); // ✅ 关键保存
    // ✅ 展示卡牌弹窗
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => RecruitCardWidget(
        disciples: newList,
        onDismiss: () {
          setState(() {}); // 可选：关闭弹窗后刷新界面
        },
      ),
    );
  }

  void _changePool(String pool) {
    if (pool == currentPool) return;
    setState(() {
      currentPool = pool;
    });
    _loadTicketCount(); // 切换池时刷新数量
  }

  Widget _buildTabButton(String pool, String label, {bool disabled = false}) {
    final bool isSelected = currentPool == pool;
    return Expanded(
      child: GestureDetector(
        onTap: disabled ? null : () => _changePool(pool),
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
    super.build(context);
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // 背景图
          Positioned.fill(
            child: Image.asset(
              'assets/images/paper_lantern_inn.png',
              fit: BoxFit.cover,
            ),
          ),

          // SafeArea（标题 + Tab）
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                        _buildTabButton('human', '人界招募'),
                        _buildTabButton('immortal', '仙界招募', disabled: true), // 👈 禁用仙界
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 中央按钮 + 招募券数量
          Align(
            alignment: Alignment.center,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 100, 24, 140),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => _recruit(count: 1),
                        icon: const Icon(Icons.star),
                        label: const Text("招募一次"),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton.icon(
                        onPressed: () => _recruit(count: 10),
                        icon: const Icon(Icons.auto_awesome),
                        label: const Text("招募十次"),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (currentPool == 'human')
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
            ),
          ),

          // 立绘图
          Transform.translate(
            offset: const Offset(0, -60),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                height: 400,
                margin: const EdgeInsets.only(bottom: 20),
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    Positioned(
                      bottom: 20,
                      child: Container(
                        width: 260,
                        height: 30,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(100),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 24,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    ),
                    Image.asset(
                      currentPool == 'human'
                          ? 'assets/images/human_recruitment_background.png'
                          : 'assets/images/immortal_recruitment_background.png',
                      fit: BoxFit.contain,
                    ),
                  ],
                ),
              ),
            ),
          ),

          const BackButtonOverlay(),
          Positioned(
            right: 20,
            bottom: 30,
            child: FloatingActionButton(
              backgroundColor: Colors.amber,
              onPressed: () async {
                final all = await DiscipleStorage.getAll();
                if (!context.mounted) return;
                showDialog(
                  context: context,
                  builder: (_) => DiscipleListDialog(disciples: all),
                );
              },
              child: const Icon(Icons.people_alt_rounded),
            ),
          ),

        ],
      ),
    );
  }
}
