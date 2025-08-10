import 'package:flutter/material.dart';
import 'package:xiu_to_xiandi_tuixiu/pages/page_disciple_detail.dart';
import 'package:xiu_to_xiandi_tuixiu/services/zongmen_storage.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/back_button_overlay.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/zongmen_disciple_card.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/disciple_limit_info_dialog.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/disciple_list_header.dart';

import '../models/disciple.dart';
import '../services/zongmen_disciple_service.dart';
import '../utils/route_observer.dart';
import '../widgets/components/empty_disciple_hint.dart';

class DisciplesPage extends StatefulWidget {
  const DisciplesPage({super.key});

  @override
  State<DisciplesPage> createState() => _DisciplesPageState();
}

class _DisciplesPageState extends State<DisciplesPage> with RouteAware {
  List<Disciple> disciples = [];
  int maxDiscipleCount = 0;
  String _sortOption = 'apt_desc';

  @override
  void initState() {
    super.initState();
    _loadSortOption();
    _loadDisciples();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)! as PageRoute);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    _loadDisciples();
  }

  Future<void> _loadSortOption() async {
    final option = await ZongmenDiscipleService.loadSortOption();
    Future.microtask(() {
      if (mounted) {
        setState(() {
          _sortOption = option;
        });
      }
    });
  }

  Future<void> _loadDisciples() async {
    final list = await ZongmenStorage.loadDisciples();
    final zongmen = await ZongmenStorage.loadZongmen();
    int max = 0;
    if (zongmen != null) {
      max = ZongmenStorage.calcMaxDiscipleCount(zongmen.sectLevel);
    }

    Future.microtask(() {
      if (mounted) {
        setState(() {
          disciples = list;
          maxDiscipleCount = max;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final sortedDisciples = [...disciples];

    switch (_sortOption) {
      case 'apt_desc':
        sortedDisciples.sort((a, b) => b.aptitude.compareTo(a.aptitude));
        break;
      case 'apt_asc':
        sortedDisciples.sort((a, b) => a.aptitude.compareTo(b.aptitude));
        break;
      case 'age_desc':
        sortedDisciples.sort((a, b) => b.age.compareTo(a.age));
        break;
      case 'age_asc':
        sortedDisciples.sort((a, b) => a.age.compareTo(b.age));
        break;
      case 'atk_desc':
        sortedDisciples.sort((a, b) {
          final powerA = ZongmenDiscipleService.calculatePower(a);
          final powerB = ZongmenDiscipleService.calculatePower(b);
          return powerB.compareTo(powerA);
        });
        break;
      case 'atk_asc':
        sortedDisciples.sort((a, b) {
          final powerA = ZongmenDiscipleService.calculatePower(a);
          final powerB = ZongmenDiscipleService.calculatePower(b);
          return powerA.compareTo(powerB);
        });
        break;
      case 'favor_desc':
        sortedDisciples.sort((a, b) => b.favorability.compareTo(a.favorability));
        break;
      case 'favor_asc':
        sortedDisciples.sort((a, b) => a.favorability.compareTo(b.favorability));
        break;
    }

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
                DiscipleListHeader(
                  count: sortedDisciples.length,
                  maxCount: maxDiscipleCount,
                  sortOption: _sortOption,
                  onSortChanged: (v) async {
                    await ZongmenDiscipleService.saveSortOption(v);
                    Future.microtask(() {
                      if (mounted) setState(() => _sortOption = v);
                    });
                  },
                  onInfoTap: () {
                    showDialog(
                      context: context,
                      builder: (_) => const DiscipleLimitInfoDialog(),
                    );
                  },
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: sortedDisciples.isEmpty
                      ? EmptyDiscipleHint(onRecruitSuccess: _loadDisciples)
                      : SingleChildScrollView(
                    child: Center( // ✅ 整个卡片区域居中
                      child: Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: sortedDisciples.map((disciple) {
                          return GestureDetector(
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => DiscipleDetailPage(discipleId: disciple.id),
                                ),
                              );
                              Future.microtask(() {
                                if (mounted) _loadDisciples();
                              });
                            },
                            child: SizedBox(
                              width: 200,
                              child: AspectRatio(
                                aspectRatio: 3 / 4.5,
                                child: ZongmenDiscipleCard(disciple: disciple),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
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
