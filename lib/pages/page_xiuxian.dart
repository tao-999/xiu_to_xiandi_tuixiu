import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/meditation_widget.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/cultivator_info_card.dart';

class XiuxianPage extends StatefulWidget {
  const XiuxianPage({super.key});

  @override
  State<XiuxianPage> createState() => _XiuxianPageState();
}

class _XiuxianPageState extends State<XiuxianPage>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _offset;

  String gender = 'male';
  bool _ready = false;
  DateTime? createdAt; // ✅ 新增全局变量

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _opacity = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _offset = Tween<Offset>(
      begin: const Offset(0, 0.01),
      end: const Offset(0, -0.01),
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _initGender();
  }

  Future<void> _initGender() async {
    final prefs = await SharedPreferences.getInstance();
    final player = jsonDecode(prefs.getString('playerData')!);
    final g = player['gender'];
    final created = DateTime.parse(player['createdAt']);

    setState(() {
      gender = g;
      createdAt = created;
      _ready = true;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final imagePath = gender == 'female'
        ? 'assets/images/icon_dazuo_female_256.png'
        : 'assets/images/icon_dazuo_male_256.png';

    if (!_ready || createdAt == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/bg_xiuxian_mountain.png',
              fit: BoxFit.cover,
            ),
          ),

          // 用 Align 固定整体居中靠下，不让它上下漂移
          Align(
            alignment: Alignment(0, 0.4), // 调这个值往上或往下推（0=居中，1=底部）
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                MeditationWidget(
                  imagePath: imagePath,
                  ready: _ready,
                  offset: _offset,
                  opacity: _opacity,
                  createdAt: createdAt!,
                ),
                CultivatorInfoCard(
                  name: '雨落尘',
                  realm: '炼气三层',
                  elements: {'金': 9, '木': 6, '水': 5, '火': 4, '土': 6},
                  currentQi: 3200,
                  maxQi: 4000,
                  technique: '赤焰心经',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
