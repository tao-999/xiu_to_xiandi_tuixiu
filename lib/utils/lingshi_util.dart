enum LingShiType { lower, middle, upper, supreme }

const Map<LingShiType, String> lingShiNames = {
  LingShiType.lower: '下品灵石',
  LingShiType.middle: '中品灵石',
  LingShiType.upper: '上品灵石',
  LingShiType.supreme: '极品灵石',
};

const Map<LingShiType, int> lingShiRates = {
  LingShiType.lower: 1,
  LingShiType.middle: 1000,
  LingShiType.upper: 1000000,
  LingShiType.supreme: 1000000000,
};

/// 灵石钱包类（支持存储、读取、消耗、增加）
/// 兑换比例：1000下品 = 1中品 = 0.001上品，以此类推
class LingShiWallet {
  int lower = 0;
  int middle = 0;
  int upper = 0;
  int supreme = 0;

  LingShiWallet({
    this.lower = 0,
    this.middle = 0,
    this.upper = 0,
    this.supreme = 0,
  });

  /// 获取以“下品灵石”为单位的总数值（用于统一计算）
  int get totalInLowerUnits =>
      lower +
          middle * lingShiRates[LingShiType.middle]! +
          upper * lingShiRates[LingShiType.upper]! +
          supreme * lingShiRates[LingShiType.supreme]!;

  /// 消耗指定修为所需的灵石（1下品 = 10修为）
  /// 按照：下品→中品→上品→极品顺序消耗
  bool consumeForQi(int requiredQi) {
    final requiredStones = (requiredQi / 10).ceil();
    if (totalInLowerUnits < requiredStones) return false;

    int remaining = requiredStones;

    void deduct(int rate, void Function(int count) apply) {
      final canUse = (remaining ~/ rate).clamp(0, _getCountByRate(rate));
      if (canUse > 0) {
        apply(canUse);
        remaining -= canUse * rate;
      }
    }

    deduct(lingShiRates[LingShiType.lower]!, (count) => lower -= count);
    deduct(lingShiRates[LingShiType.middle]!, (count) => middle -= count);
    deduct(lingShiRates[LingShiType.upper]!, (count) => upper -= count);
    deduct(lingShiRates[LingShiType.supreme]!, (count) => supreme -= count);

    return true;
  }

  int _getCountByRate(int rate) {
    if (rate == 1) return lower;
    if (rate == 1000) return middle;
    if (rate == 1000000) return upper;
    if (rate == 1000000000) return supreme;
    return 0;
  }

  /// 增加指定类型的灵石
  void add(LingShiType type, int count) {
    switch (type) {
      case LingShiType.lower:
        lower += count;
        break;
      case LingShiType.middle:
        middle += count;
        break;
      case LingShiType.upper:
        upper += count;
        break;
      case LingShiType.supreme:
        supreme += count;
        break;
    }
  }

  /// 转换为 JSON 便于存储
  Map<String, dynamic> toJson() => {
    'lower': lower,
    'middle': middle,
    'upper': upper,
    'supreme': supreme,
  };

  /// 从 JSON 中恢复
  static LingShiWallet fromJson(Map<String, dynamic> json) => LingShiWallet(
    lower: json['lower'] ?? 0,
    middle: json['middle'] ?? 0,
    upper: json['upper'] ?? 0,
    supreme: json['supreme'] ?? 0,
  );
}
