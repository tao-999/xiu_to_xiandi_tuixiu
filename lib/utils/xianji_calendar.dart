import 'package:xiu_to_xiandi_tuixiu/services/player_storage.dart';

class XianjiCalendar {
  static const int SECONDS_PER_DAY_REAL = 86400;
  static const int SPEED_RATE = 1000;
  static const int IMMORTAL_SECONDS_PER_DAY = SECONDS_PER_DAY_REAL ~/ SPEED_RATE;
  static const int IMMORTAL_SECONDS_PER_YEAR = IMMORTAL_SECONDS_PER_DAY * 365;

  /// 获取玄历纪元（玄历第 N 年 第 M 天）
  static Future<String> formatYearFromTimestamp(int timestamp) async {
    final player = await PlayerStorage.getPlayer();
    if (player == null || player.createdAt == null) return '玄历·未知年份';

    final base = player.createdAt!;
    final diffSeconds = timestamp - base;

    if (diffSeconds < 0) return '玄历·穿越前';

    final immortalDays = diffSeconds ~/ IMMORTAL_SECONDS_PER_DAY;
    final immortalYears = immortalDays ~/ 365;
    final dayOfYear = immortalDays % 365;

    return '玄历·${immortalYears} 年 ${dayOfYear} 天';
  }

  /// 获取当前玄历时间（现在是哪年哪天）
  static Future<String> currentYear() async {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return formatYearFromTimestamp(now);
  }
}
