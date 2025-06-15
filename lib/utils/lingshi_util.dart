// 📦 lib/utils/lingshi_util.dart

enum LingShiType { lower, middle, upper, supreme }

/// 💎 灵石中文名
const Map<LingShiType, String> lingShiNames = {
  LingShiType.lower: '下品灵石',
  LingShiType.middle: '中品灵石',
  LingShiType.upper: '上品灵石',
  LingShiType.supreme: '极品灵石',
};

/// 🔁 兑换倍率（以“下品”为1）
final Map<LingShiType, BigInt> lingShiRates = {
  LingShiType.lower: BigInt.from(1),
  LingShiType.middle: BigInt.from(1000),
  LingShiType.upper: BigInt.from(1000000),
  LingShiType.supreme: BigInt.from(1000000000),
};

/// 🧾 对应 Resources 字段名
const Map<LingShiType, String> lingShiFieldMap = {
  LingShiType.lower: 'spiritStoneLow',
  LingShiType.middle: 'spiritStoneMid',
  LingShiType.upper: 'spiritStoneHigh',
  LingShiType.supreme: 'spiritStoneSupreme',
};

/// 🖼️ 灵石图片路径
const Map<LingShiType, String> lingShiImagePaths = {
  LingShiType.lower: 'assets/images/spirit_stone_low.png',
  LingShiType.middle: 'assets/images/spirit_stone_mid.png',
  LingShiType.upper: 'assets/images/spirit_stone_high.png',
  LingShiType.supreme: 'assets/images/spirit_stone_supreme.png',
};

/// 🧰 工具方法：根据类型取图片路径
String getLingShiImagePath(LingShiType type) => lingShiImagePaths[type]!;
