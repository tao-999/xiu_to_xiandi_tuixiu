import 'package:flutter/material.dart';
import '../widgets/components/back_button_overlay.dart';
import '../widgets/components/duihuan_lingshi.dart';
import '../widgets/components/forge_blueprint_shop.dart';
import '../widgets/components/refine_material_shop.dart';
import '../widgets/components/herb_material_shop.dart';
import '../widgets/components/pill_blueprint_shop.dart';

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

          // ✅ 铺子横向一排，居中显示
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                SizedBox(width: 128, height: 128, child: DuihuanLingshi()),
                SizedBox(width: 20),
                SizedBox(width: 128, height: 128, child: RefineMaterialShop()),
                SizedBox(width: 20),
                SizedBox(width: 128, height: 128, child: ForgeBlueprintShop()),
                SizedBox(width: 20),
                SizedBox(width: 128, height: 128, child: PillBlueprintShop()),
                SizedBox(width: 20),
                SizedBox(width: 128, height: 128, child: HerbMaterialShop()),
              ],
            )
          ),

          const BackButtonOverlay(),
        ],
      ),
    );
  }
}
