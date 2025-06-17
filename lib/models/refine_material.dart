import 'package:xiu_to_xiandi_tuixiu/utils/lingshi_util.dart';

/// 使用 Resources 系统统一表示价格
class RefineMaterial {
  final String id;
  final String name;
  final int level;
  final String image;

  /// 使用资源价格字段，单位可指定是哪种灵石
  final int priceAmount;
  final LingShiType priceType;

  RefineMaterial({
    required this.id,
    required this.name,
    required this.level,
    required this.image,
    required this.priceAmount,
    required this.priceType,
  });
}
