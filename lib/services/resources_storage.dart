import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xiu_to_xiandi_tuixiu/models/resources.dart';

import '../models/refine_blueprint.dart';
import '../utils/lingshi_util.dart';

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

  /// 添加已拥有图纸记录（根据类型 + 阶数）
  /// 例如：RefineBlueprint(type=weapon, level=3) → 'weapon-3'
  static Future<void> addBlueprintKey(RefineBlueprint blueprint) async {
    final res = await load();
    final key = '${blueprint.type.name}-${blueprint.level}';

    if (!res.ownedBlueprintKeys.contains(key)) {
      res.ownedBlueprintKeys.add(key);
      await save(res);
      print('✅ [图纸已记录] $key');
    } else {
      print('ℹ️ [图纸已存在] $key，跳过保存');
    }
  }

  static Future<Set<String>> getBlueprintKeys() async {
    final res = await load(); // 已有的读取 Resources 方法
    return res.ownedBlueprintKeys.toSet(); // 确保是 Set<String>
  }

  /// 获取某种灵石数量（支持下中上极品）
  static BigInt getStoneAmount(Resources res, LingShiType type) {
    final field = lingShiFieldMap[type];

    switch (field) {
      case 'spiritStoneLow':
        return res.spiritStoneLow;
      case 'spiritStoneMid':
        return res.spiritStoneMid;
      case 'spiritStoneHigh':
        return res.spiritStoneHigh;
      case 'spiritStoneSupreme':
        return res.spiritStoneSupreme;
      default:
        return BigInt.zero;
    }
  }

}
