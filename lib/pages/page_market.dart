// 📄 lib/pages/page_market.dart

import 'package:flutter/material.dart';
import '../widgets/components/back_button_overlay.dart';
import '../widgets/components/duihuan_lingshi.dart'; // ✅ 引入组件

class XiuXianMarketPage extends StatelessWidget {
  const XiuXianMarketPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ✅ 背景图层
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/bg_market.webp'),
                fit: BoxFit.cover,
              ),
            ),
          ),

          // ✅ 灵石兑换组件放在中间稍下方
          const Positioned(
            bottom: 300,
            left: 0,
            child: Center(
              child: DuihuanLingshi(),
            ),
          ),

          // ✅ 返回按钮浮在最上
          const BackButtonOverlay(),
        ],
      ),
    );
  }
}
