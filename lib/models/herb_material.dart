import 'package:xiu_to_xiandi_tuixiu/utils/lingshi_util.dart';

class HerbMaterial {
  final String id;         // 唯一 ID，如 yunmengcao
  final String name;       // 显示名称，如 云梦草
  final int level;         // 材料阶数（1~21）
  final String image;      // 图标路径，如 'assets/images/herbs/yunmengcao.png'
  final int priceAmount;   // 单价
  final LingShiType priceType; // 价格类型（下品/中品/上品灵石）

  HerbMaterial({
    required this.id,
    required this.name,
    required this.level,
    required this.image,
    required this.priceAmount,
    required this.priceType,
  });
}
