import 'package:flutter/material.dart';

class ZhaomuPage extends StatefulWidget {
  const ZhaomuPage({super.key});

  @override
  State<ZhaomuPage> createState() => _ZhaomuPageState();
}

class _ZhaomuPageState extends State<ZhaomuPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.group_add, size: 48, color: Colors.lightBlueAccent),
              SizedBox(height: 16),
              Text(
                '灵缘客栈 · 招募修士',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 12),
              Text(
                '你可以在此招募弟子、门客、护法等修士角色。\n'
                    '（后续开放“灵石抽卡”、“缘分卡池”、“招募条件筛选”等骚功能）',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
