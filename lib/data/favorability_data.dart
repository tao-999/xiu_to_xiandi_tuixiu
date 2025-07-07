// lib/data/favorability_data.dart
import '../models/favorability_item.dart';

class FavorabilityData {
  static const List<String> names = [
    '青玉发簪',
    '折扇残片',
    '竹简心语',
    '红绳信物',
    '忘忧草花环',
    '流云石坠',
    '手绘画像',
    '琉璃铃铛',
    '共饮葫芦',
    '月下石灯',
    '旧信笺',
    '古琴断弦',
    '折翼羽毛',
    '师门印章',
    '风铃结界符',
    '寒玉佩环',
    '星辰锦囊',
    '紫电流苏',
    '梦蝶琉璃盏',
    '灵犀纸鹤',
    '青藤结书签',
    '绛云香囊',
    '云岚绸带',
    '霜花耳坠',
    '长明檀灯',
    '望月银镜',
    '血誓玉简',
    '幽兰发绳',
    '雾隐竹笛',
    '晨露手链',
  ];

  static final List<FavorabilityItem> items = List.generate(
    30,
        (index) {
      final i = index + 1;
      return FavorabilityItem(
        assetPath: 'assets/images/favorability/$i.png',
        favorValue: i,
        name: names[index], // index: 0~29 ✅正确
      );
    },
  );

  static FavorabilityItem getByIndex(int index) {
    if (index < 1 || index > 30) {
      throw RangeError('index must be between 1 and 30');
    }
    return items[index - 1]; // 注意这里 index-1
  }

  static FavorabilityItem getByFavorValue(int favorValue) {
    return getByIndex(favorValue);
  }
}
