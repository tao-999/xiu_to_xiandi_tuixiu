import 'package:flutter/material.dart';
import '../widgets/components/back_button_overlay.dart';
import '../widgets/components/duihuan_lingshi.dart';
import '../widgets/components/forge_blueprint_shop.dart';
import '../widgets/components/refine_material_shop.dart';
import '../widgets/components/herb_material_shop.dart';
import '../widgets/components/pill_blueprint_shop.dart'; // ✅ 新加

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

          // ✅ 灵石兑换组件（左中下）
          const Positioned(
            bottom: 300,
            left: 0,
            child: Center(
              child: DuihuanLingshi(),
            ),
          ),

          // ✅ 炼器材料招牌（中下右）
          const Positioned(
            bottom: 120,
            right: 80,
            child: RefineMaterialShop(),
          ),

          // ✅ 武器图纸招牌（右下角）
          const Positioned(
            bottom: 250,
            right: 15,
            child: ForgeBlueprintShop(),
          ),

          // ✅ 丹药草药商店招牌（左下角）
          const Positioned(
            bottom: 120,
            left: 20,
            child: HerbMaterialShop(),
          ),

          // ✅ 丹方图纸招牌（左上中）
          const Positioned(
            top: 80,
            right: 100,
            child: PillBlueprintShop(),
          ),

          // ✅ 返回按钮
          const BackButtonOverlay(),
        ],
      ),
    );
  }
}
