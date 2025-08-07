import 'package:hive/hive.dart';

class RecruitTicketStorage {
  static const _boxName = 'collected_recruit_ticket_box';
  static Box<bool>? _box;

  static Future<Box<bool>> _getBox() async {
    if (_box != null && _box!.isOpen) return _box!;
    _box = await Hive.openBox<bool>(_boxName);
    return _box!;
  }

  static Future<void> markCollected(String tileKey) async {
    final box = await _getBox();
    await box.put(tileKey, true);
  }

  static Future<bool> isCollected(String tileKey) async {
    final box = await _getBox();
    return box.get(tileKey, defaultValue: false) ?? false;
  }

  static Future<void> clear() async {
    final box = await _getBox();
    await box.clear();
  }
}
