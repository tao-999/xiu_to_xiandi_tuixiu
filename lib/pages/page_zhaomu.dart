import 'package:flutter/material.dart';
import 'package:xiu_to_xiandi_tuixiu/models/disciple.dart';
import 'package:xiu_to_xiandi_tuixiu/services/zongmen_storage.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/back_button_overlay.dart';
import 'package:xiu_to_xiandi_tuixiu/services/disciple_factory.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/dialogs/recruit_probability_dialog.dart';

class ZhaomuPage extends StatefulWidget {
  const ZhaomuPage({super.key});

  @override
  State<ZhaomuPage> createState() => _ZhaomuPageState();
}

class _ZhaomuPageState extends State<ZhaomuPage> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  List<Disciple> _humanRecruited = [];
  List<Disciple> _immortalRecruited = [];
  String currentPool = 'human';

  Color getHumanAptitudeColor(int aptitude) {
    if (aptitude >= 81) return const Color(0xFFFFD700);
    if (aptitude >= 71) return const Color(0xFFDA70D6);
    if (aptitude >= 61) return const Color(0xFF8A2BE2);
    if (aptitude >= 51) return const Color(0xFF00CED1);
    if (aptitude >= 41) return const Color(0xFF1E90FF);
    if (aptitude >= 31) return const Color(0xFF40E0D0);
    if (aptitude >= 21) return const Color(0xFF7FFF00);
    if (aptitude >= 11) return const Color(0xFFADFF2F);
    return const Color(0xFF808080);
  }

  Color getImmortalAptitudeColor(int aptitude) {
    if (aptitude >= 201) return const Color(0xFFB03060);
    if (aptitude >= 171) return const Color(0xFF800000);
    if (aptitude >= 141) return const Color(0xFFB22222);
    if (aptitude >= 101) return const Color(0xFFFF4500);
    return const Color(0xFFFF4500);
  }

  Color getAptitudeColor(int aptitude) {
    return currentPool == 'human'
        ? getHumanAptitudeColor(aptitude)
        : getImmortalAptitudeColor(aptitude);
  }

  Future<void> _recruit({int count = 1}) async {
    final List<Disciple> newList = [];
    for (int i = 0; i < count; i++) {
      final d = DiscipleFactory.generateRandom(pool: currentPool);
      newList.add(d);
    }
    for (final d in newList) {
      await ZongmenStorage.addDisciple(d);
    }
    setState(() {
      if (currentPool == 'human') {
        _humanRecruited = newList;
      } else {
        _immortalRecruited = newList;
      }
    });
  }

  List<Disciple> get _currentRecruitedList =>
      currentPool == 'human' ? _humanRecruited : _immortalRecruited;

  void _changePool(String pool) {
    if (pool == currentPool) return;
    setState(() {
      currentPool = pool;
    });
  }

  void _showDiscipleDialog(Disciple d) {
    final glowColor = getAptitudeColor(d.aptitude);

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          backgroundColor: const Color(0xFFF9F5E3),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  d.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    fontFamily: 'ZcoolCangEr',
                  ),
                ),
                const SizedBox(height: 8),
                _info("年龄", "${d.age}"),
                _info("性别", d.gender == "female" ? "女" : "男"),
                _info("资质", "${d.aptitude}"),
                _info("忠诚", "${d.loyalty}"),
                _info("境界", d.realm),
                _info("特长", d.specialty),
                _info("天赋", d.talents.join("、")),
                _info("寿命", "${d.lifespan}"),
                _info("当前修为", "${d.cultivation}"),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _info(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "$title：",
            style: const TextStyle(
              color: Colors.black54,
              fontFamily: 'ZcoolCangEr',
              fontSize: 16,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.black87,
              fontFamily: 'ZcoolCangEr',
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard(Disciple d) {
    final bool isHuman = currentPool == 'human';
    final glowColor = getAptitudeColor(d.aptitude);

    return GestureDetector(
      onTap: () => _showDiscipleDialog(d),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isHuman
              ? glowColor.withOpacity(0.10)
              : glowColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: glowColor.withOpacity(isHuman ? 0.6 : 1.0),
            width: 1.2,
          ),
          boxShadow: isHuman
              ? [
            BoxShadow(
              color: glowColor.withOpacity(0.5),
              blurRadius: 12,
              spreadRadius: 2,
              offset: Offset.zero,
            ),
          ]
              : [],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: glowColor,
              child: Icon(
                d.gender == "female" ? Icons.female : Icons.male,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(d.name, style: const TextStyle(fontSize: 16, color: Colors.white)),
                  const SizedBox(height: 4),
                  Text("资质：${d.aptitude} / 境界：${d.realm}", style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  Text("特长：${d.specialty} / 天赋：${d.talents.join(", ")}", style: const TextStyle(color: Colors.white54, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.info_outline, color: Colors.white),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: const Color(0xFF4B432F),
      appBar: AppBar(
        title: const Text('灵缘客栈 · 招募修士'),
        backgroundColor: const Color(0xFF4B432F),
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.white),
            tooltip: '查看招募概率',
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
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: const Text('人界招募', textAlign: TextAlign.center),
                        selected: currentPool == 'human',
                        onSelected: (_) => _changePool('human'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ChoiceChip(
                        label: const Text('仙界招募', textAlign: TextAlign.center),
                        selected: currentPool == 'immortal',
                        onSelected: (_) => _changePool('immortal'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
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
                const SizedBox(height: 24),
                if (_currentRecruitedList.isNotEmpty)
                  Expanded(
                    child: ListView(
                      children: [
                        Text(
                          currentPool == 'human'
                              ? "🎉 本次人界招募结果："
                              : "🎉 本次仙界招募结果：",
                          style: const TextStyle(color: Colors.orangeAccent),
                        ),
                        const SizedBox(height: 12),
                        ..._currentRecruitedList.map(_buildResultCard).toList(),
                      ],
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
