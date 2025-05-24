import 'package:flutter/material.dart';

class YouliPage extends StatefulWidget {
  const YouliPage({super.key});

  @override
  State<YouliPage> createState() => _YouliPageState();
}

class _YouliPageState extends State<YouliPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.explore, color: Colors.white70, size: 48),
            SizedBox(height: 16),
            Text(
              '游历天下 · 奇遇无穷',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              '（未来在这里加入地图、事件卡、互动）',
              style: TextStyle(color: Colors.white54, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
