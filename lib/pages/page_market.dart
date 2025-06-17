import 'package:flutter/material.dart';
import '../widgets/components/back_button_overlay.dart';
import '../widgets/components/duihuan_lingshi.dart';
import '../widgets/components/forge_blueprint_shop.dart';
import '../widgets/components/refine_material_shop.dart'; // ✅ 新增导入

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

          // ✅ 灵石兑换组件放在中间稍下方（左侧）
          const Positioned(
            bottom: 300,
            left: 0,
            child: Center(
              child: DuihuanLingshi(),
            ),
          ),

          // ✅ 炼器材料招牌（中下方偏右一点）
          const Positioned(
            bottom: 120,
            right: 110, // ✅ 调整位置别太靠边
            child: RefineMaterialShop(),
          ),

          // ✅ 武器图纸招牌（右下角）
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
