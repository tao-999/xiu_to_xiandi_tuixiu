// 📦 lib/utils/lingshi_util.dart

enum LingShiType { lower, middle, upper, supreme }

const Map<LingShiType, String> lingShiNames = {
  LingShiType.lower: '下品灵石',
  LingShiType.middle: '中品灵石',
  LingShiType.upper: '上品灵石',
  LingShiType.supreme: '极品灵石',
};

/// 灵石兑换倍率（单位：以“下品”为基准）
final Map<LingShiType, BigInt> lingShiRates = {
  LingShiType.lower: BigInt.from(1),
  LingShiType.middle: BigInt.from(1000),
  LingShiType.upper: BigInt.from(1000000),
  LingShiType.supreme: BigInt.from(1000000000),
};

/// 灵石字段映射（用于操作 Resources）
const Map<LingShiType, String> lingShiFieldMap = {
  LingShiType.lower: 'spiritStoneLow',
  LingShiType.middle: 'spiritStoneMid',
  LingShiType.upper: 'spiritStoneHigh',
  LingShiType.supreme: 'spiritStoneSupreme',
};
