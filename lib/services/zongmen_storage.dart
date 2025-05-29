import 'package:hive/hive.dart';
import 'package:xiu_to_xiandi_tuixiu/models/disciple.dart';

class ZongmenStorage {
  static const String _discipleBoxKey = 'disciples';

  /// 加载所有弟子
  static Future<List<Disciple>> loadDisciples() async {
    final box = await Hive.openBox(_discipleBoxKey);
    final list = box.get('list');
    if (list == null) return [];
    return List<Disciple>.from(list.map((e) => Disciple.fromMap(Map<String, dynamic>.from(e))));
  }

  /// 保存弟子列表（全覆盖）
  static Future<void> saveDisciples(List<Disciple> disciples) async {
    final box = await Hive.openBox(_discipleBoxKey);
    final list = disciples.map((e) => e.toMap()).toList();
    await box.put('list', list);
  }

  /// 添加一个新弟子
  static Future<void> addDisciple(Disciple disciple) async {
    final current = await loadDisciples();
    current.add(disciple);
    await saveDisciples(current);
  }

  /// 删除弟子（比如出宗、暴毙）
  static Future<void> removeDisciple(String id) async {
    final current = await loadDisciples();
    current.removeWhere((d) => d.id == id);
    await saveDisciples(current);
  }

  /// 清空所有弟子（debug 用）
  static Future<void> clearAll() async {
    final box = await Hive.openBox(_discipleBoxKey);
    await box.clear();
  }
}
