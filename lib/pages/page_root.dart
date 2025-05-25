import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'page_xiuxian.dart';
import 'page_youli.dart';
import 'page_zongmen.dart';
import 'page_zhaomu.dart';

class XiudiRoot extends StatefulWidget {
  const XiudiRoot({super.key});

  @override
  State<XiudiRoot> createState() => _XiudiRootState();
}

class _XiudiRootState extends State<XiudiRoot> {
  int _currentIndex = 0;
  String gender = 'male'; // 默认值，等会从 SharedPreferences 里读

  final List<Widget> _pages = const [
    XiuxianPage(),
    YouliPage(),
    ZongmenPage(),
    ZhaomuPage(),
  ];

  final List<String> _labels = ['挂机', '游历', '宗门', '招募'];

  List<String> get _iconPaths => [
    gender == 'female'
        ? 'assets/images/icon_dazuo_female.png'
        : 'assets/images/icon_dazuo_male.png',
    'assets/images/icon_youli.png',
    'assets/images/icon_zongmen.png',
    'assets/images/icon_zhaomu.png',
  ];

  @override
  void initState() {
    super.initState();
    _loadGender(); // ⬅️ 初始化时加载性别
  }

  Future<void> _loadGender() async {
    final prefs = await SharedPreferences.getInstance();
    final player = jsonDecode(prefs.getString('playerData')!);
    final g = player['gender']; // 🚀 不加默认值、不容错
    debugPrint('🐉 获取到角色性别：$g');

    setState(() {
      gender = g;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ✅ 包一层 padding，避免内容被底部菜单遮挡
          Padding(
            padding: const EdgeInsets.only(bottom: 80),
            child: _pages[_currentIndex],
          ),

          // ✅ 底部浮动菜单
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              top: false,
              child: SizedBox(
                height: 80,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // 背景容器
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: AssetImage('assets/images/menu_background_final.webp'),
                            fit: BoxFit.cover,
                            alignment: Alignment.bottomCenter,
                          ),
                        ),
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: List.generate(_labels.length, (index) {
                            final bool isSelected = _currentIndex == index;
                            return SizedBox(
                              width: 64,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const SizedBox(height: 26),
                                  Text(
                                    _labels[index],
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF333333),
                                      shadows: isSelected
                                          ? [Shadow(color: Colors.black.withOpacity(0.15), blurRadius: 1)]
                                          : [],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ),
                      ),
                    ),
                    // 图标溢出上浮
                    Positioned(
                      bottom: 34,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(_labels.length, (index) {
                          return GestureDetector(
                            onTap: () => setState(() => _currentIndex = index),
                            child: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: Image.asset(
                                _iconPaths[index],
                                fit: BoxFit.cover,
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
