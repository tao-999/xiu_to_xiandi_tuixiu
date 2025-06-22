import 'package:flutter/material.dart';
import 'package:xiu_to_xiandi_tuixiu/models/disciple.dart';
import 'package:xiu_to_xiandi_tuixiu/pages/page_disciple_detail.dart';
import 'package:xiu_to_xiandi_tuixiu/pages/page_zhaomu.dart';
import 'package:xiu_to_xiandi_tuixiu/services/zongmen_storage.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/back_button_overlay.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/zongmen_disciple_card.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/disciple_limit_info_dialog.dart';

// ✅ 全局 route observer
final RouteObserver<ModalRoute<void>> routeObserver = RouteObserver<ModalRoute<void>>();

class DiscipleListPage extends StatefulWidget {
  const DiscipleListPage({super.key});

  @override
  State<DiscipleListPage> createState() => _DiscipleListPageState();
}

class _DiscipleListPageState extends State<DiscipleListPage> with RouteAware {
  List<Disciple> disciples = [];
  int maxDiscipleCount = 0;

  @override
  void initState() {
    super.initState();
    _loadDisciples();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!); // ✅ 注册监听
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this); // ✅ 注销监听
    super.dispose();
  }

  // ✅ 当从其他页面 pop 回来时触发
  @override
  void didPopNext() {
    _loadDisciples(); // ✅ 自动刷新弟子列表
  }

  Future<void> _loadDisciples() async {
    final list = await ZongmenStorage.loadDisciples();
    final zongmen = await ZongmenStorage.loadZongmen();
    int max = 0;
    if (zongmen != null) {
      final level = ZongmenStorage.calcSectLevel(zongmen.sectExp);
      max = 5 * level;
    }

    setState(() {
      disciples = list;
      maxDiscipleCount = max;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/zongmen_bg_dizi.webp',
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text(
                      "弟子管理",
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.white,
                        fontFamily: 'ZcoolCangEr',
                      ),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (_) => const DiscipleLimitInfoDialog(),
                        );
                      },
                      child: const Icon(
                        Icons.info_outline,
                        size: 18,
                        color: Colors.white70,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${disciples.length} / $maxDiscipleCount',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                        fontFamily: 'ZcoolCangEr',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: disciples.isEmpty
                      ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          "一个人也没有，宗主你要孤独终老吗？",
                          style: TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF9F5E3),
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.zero,
                            ),
                          ),
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ZhaomuPage(),
                              ),
                            );
                            _loadDisciples();
                          },
                          child: const Text(
                            "前往招募",
                            style: TextStyle(
                              fontSize: 16,
                              fontFamily: 'ZcoolCangEr',
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                      : GridView.builder(
                    padding: const EdgeInsets.only(top: 4),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 3 / 4.5,
                    ),
                    itemCount: disciples.length,
                    itemBuilder: (context, index) {
                      final disciple = disciples[index];
                      return GestureDetector(
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DiscipleDetailPage(disciple: disciple),
                            ),
                          );
                          // ❌ 不需要主动刷新，交给 didPopNext 自动刷新
                        },
                        child: ZongmenDiscipleCard(disciple: disciple),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const BackButtonOverlay(),
        ],
      ),
    );
  }
}
