import 'package:flutter/material.dart';
import 'package:xiu_to_xiandi_tuixiu/models/disciple.dart';
import 'package:xiu_to_xiandi_tuixiu/pages/page_zhaomu.dart';
import 'package:xiu_to_xiandi_tuixiu/services/zongmen_storage.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/back_button_overlay.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/zongmen_disciple_card.dart';

class DiscipleListPage extends StatefulWidget {
  const DiscipleListPage({super.key});

  @override
  State<DiscipleListPage> createState() => _DiscipleListPageState();
}

class _DiscipleListPageState extends State<DiscipleListPage> {
  List<Disciple> disciples = [];
  int maxDiscipleCount = 0;

  @override
  void initState() {
    super.initState();
    _loadDisciples();
  }

  Future<void> _loadDisciples() async {
    final list = await ZongmenStorage.loadDisciples();
    final zongmen = await ZongmenStorage.loadZongmen();
    final max = zongmen == null ? 0 : 5 * (1 << (zongmen.level - 1));

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
                      style: TextStyle(fontSize: 20, color: Colors.white, fontFamily: 'ZcoolCangEr'),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            backgroundColor: const Color(0xFFF9F5E3),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            content: const Text(
                              "宗门等级越高，容纳的弟子就越多。\n\n"
                                  "等级对照表：\n"
                                  "1级：5人\n"
                                  "2级：10人\n"
                                  "3级：20人\n"
                                  "4级：40人\n"
                                  "5级：80人\n"
                                  "6级：160人\n"
                                  "7级：320人\n"
                                  "8级：640人\n"
                                  "9级：1280人",
                              style: TextStyle(fontSize: 14, fontFamily: 'ZcoolCangEr'),
                            ),
                          ),
                        );
                      },
                      child: const Icon(Icons.info_outline, size: 18, color: Colors.white70),
                    ),
                    const Spacer(),
                    Text(
                      '${disciples.length} / $maxDiscipleCount',
                      style: const TextStyle(fontSize: 14, color: Colors.white70, fontFamily: 'ZcoolCangEr'),
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
                        const Text("一个人也没有，宗主你要孤独终老吗？", style: TextStyle(color: Colors.white70)),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF9F5E3),
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const ZhaomuPage()),
                            );
                            _loadDisciples();
                          },
                          child: const Text(
                            "前往招募",
                            style: TextStyle(fontSize: 16, fontFamily: 'ZcoolCangEr'),
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
                      return ZongmenDiscipleCard(disciple: disciples[index]);
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
