import 'package:shared_preferences/shared_preferences.dart';
import 'resources_storage.dart';

class GiftRewardResult {
  final bool isFirstTime;
  final int claimCount;
  final BigInt spiritStone;
  final BigInt recruitTicket;
  final BigInt fateCharm;

  const GiftRewardResult({
    required this.isFirstTime,
    required this.claimCount,
    required this.spiritStone,
    required this.recruitTicket,
    required this.fateCharm,
  });
}

class GiftService {
  static const String _keyLastClaimed = 'lastClaimedGiftAt';
  static const String _keyClaimCount = 'giftClaimCount';
  static const Duration cooldown = Duration(hours: 12);

  /// 获取上次领取时间（null 表示首次）
  static Future<DateTime?> getLastClaimedAt() async {
    final prefs = await SharedPreferences.getInstance();
    final ms = prefs.getInt(_keyLastClaimed);
    if (ms == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(ms);
  }

  /// 获取累计领取次数（首次为 0）
  static Future<int> getClaimCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyClaimCount) ?? 0;
  }

  /// 计算当前奖励（用于展示或发放）
  static GiftRewardResult calculateReward(int claimCount) {
    final isFirst = claimCount == 1; // 第1次
    BigInt stone;
    BigInt ticket;
    BigInt charm;
    if (isFirst) {
      stone = BigInt.from(10000000000000);
      ticket = BigInt.from(500);
      charm = BigInt.from(1000);
    } else {
      final base = 10000 + (claimCount - 1) * 500; // 第2次起递增
      stone = BigInt.from(base);
      ticket = BigInt.one;
      charm = BigInt.one;
    }
    return GiftRewardResult(
      isFirstTime: isFirst,
      claimCount: claimCount,
      spiritStone: stone,
      recruitTicket: ticket,
      fateCharm: charm,
    );
  }

  /// 发放奖励 + 写入时间 + 次数 + 返回奖励结果（给组件展示）
  static Future<GiftRewardResult> claimReward() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();

    // ⚡改这里：首次就是1
    final oldCount = prefs.getInt(_keyClaimCount);
    final newCount = (oldCount ?? 0) + 1;

    final result = calculateReward(newCount);

    // ✅ 发奖励
    await ResourcesStorage.add('spiritStoneLow', result.spiritStone);
    await ResourcesStorage.add('recruitTicket', result.recruitTicket);
    await ResourcesStorage.add('fateRecruitCharm', result.fateCharm);

    // ✅ 写入记录
    await prefs.setInt(_keyLastClaimed, now.millisecondsSinceEpoch);
    await prefs.setInt(_keyClaimCount, newCount);

    return result;
  }

  /// 调试用：清除所有数据
  static Future<void> resetGiftData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyLastClaimed);
    await prefs.remove(_keyClaimCount);
  }
}
