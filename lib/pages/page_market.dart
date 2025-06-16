// 📄 lib/pages/page_market.dart

import 'package:flutter/material.dart';
import '../widgets/components/back_button_overlay.dart';
import '../widgets/components/duihuan_lingshi.dart';
import '../widgets/components/forge_blueprint_shop.dart';

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

          // ✅ 武器图纸招牌（右下角位置，方便你改）
          const Positioned(
            bottom: 250,
            right: 15,
            child: ForgeBlueprintShop(),
          ),

          // ✅ 返回按钮浮在最上
          const BackButtonOverlay(),
        ],
      ),
    );
  }
}
