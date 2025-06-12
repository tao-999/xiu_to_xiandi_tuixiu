import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xiu_to_xiandi_tuixiu/models/resources.dart';

class ResourcesStorage {
  static const _key = 'resourcesData';

  /// 保存资源
  static Future<void> save(Resources res) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(res.toMap()));
    print('📦 [资源已保存] => ${jsonEncode(res.toMap())}');
  }

  /// 读取资源
  static Future<Resources> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) {
      print('📦 [资源未找到]，返回默认空资源');
      return Resources();
    }
    print('📦 [资源已读取] => $raw');
    return Resources.fromMap(jsonDecode(raw));
  }

  /// 增加 BigInt 类型资源（自动分类）
  static Future<void> add(String type, BigInt value) async {
    final res = await load();
    final map = res.toMap();
    final isInt = _intFields.contains(type);

    if (isInt) {
      final oldVal = int.tryParse(map[type]?.toString() ?? '0') ?? 0;
      final newVal = oldVal + value.toInt();
      map[type] = newVal;
      print('➕ [Int资源增加] $type: $oldVal -> $newVal');
    } else {
      final oldVal = BigInt.tryParse(map[type]?.toString() ?? '0') ?? BigInt.zero;
      final newVal = oldVal + value;
      map[type] = newVal.toString();
      print('➕ [BigInt资源增加] $type: $oldVal -> $newVal');
    }

    await save(Resources.fromMap(map));
  }

  /// 减少 BigInt 类型资源
  static Future<void> subtract(String type, BigInt value) async {
    print('➖ [资源减少] $type: -$value');
    await add(type, -value);
  }

  /// 获取 BigInt 类型资源值
  static Future<BigInt> getValue(String type) async {
    final res = await load();
    final map = res.toMap();
    final raw = map[type];
    BigInt result;

    if (_intFields.contains(type)) {
      result = BigInt.from(int.tryParse(raw.toString()) ?? 0);
    } else {
      result = BigInt.tryParse(raw?.toString() ?? '0') ?? BigInt.zero;
    }

    print('🔍 [资源查询] $type: $result');
    return result;
  }

  static const List<String> _intFields = [
    'recruitTicket',
    'fateRecruitCharm',
  ];
}
