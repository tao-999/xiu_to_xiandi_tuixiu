import 'package:xiu_to_xiandi_tuixiu/services/resources_storage.dart';
import 'package:xiu_to_xiandi_tuixiu/models/resources.dart';
import 'package:xiu_to_xiandi_tuixiu/utils/bigint_extensions.dart';
import 'package:xiu_to_xiandi_tuixiu/utils/lingshi_util.dart';

class LingShiExchangeService {
  /// 执行灵石兑换
  static Future<bool> exchangeLingShi({
    required LingShiType fromType,
    required LingShiType toType,
    required int inputAmount,
    required Resources res,
  }) async {
    // 获取资源（灵石）字段
    final fromField = lingShiFieldMap[fromType]!;
    final toField = lingShiFieldMap[toType]!;

    // 获取当前拥有的灵石数量
    BigInt available = await ResourcesStorage.getValue(fromField);
    print('当前可用灵石：$available');

    // 计算所需的灵石数量
    final fromRate = lingShiRates[fromType]!;
    final toRate = lingShiRates[toType]!;
    final required = (toRate * BigInt.from(inputAmount) ~/ fromRate);
    print('所需灵石：$required');

    // 检查是否足够兑换
    if (inputAmount <= 0 || required > available) {
      print('兑换失败，灵石不足');
      return false; // 灵石不足
    }

    // 执行兑换操作：从已有灵石中扣除
    await ResourcesStorage.subtract(fromField, required);
    print('灵石已扣除：$required');

    // 增加目标灵石
    await ResourcesStorage.add(toField, BigInt.from(inputAmount));
    print('灵石已增加：$inputAmount ${lingShiNames[toType]}');

    // 更新资源对象并保存
    res = await ResourcesStorage.load();  // 确保读取最新资源

    // 检查并确保灵石不为负数
    res.spiritStoneLow = res.spiritStoneLow < BigInt.zero ? BigInt.zero : res.spiritStoneLow;
    res.spiritStoneMid = res.spiritStoneMid < BigInt.zero ? BigInt.zero : res.spiritStoneMid;
    res.spiritStoneHigh = res.spiritStoneHigh < BigInt.zero ? BigInt.zero : res.spiritStoneHigh;
    res.spiritStoneSupreme = res.spiritStoneSupreme < BigInt.zero ? BigInt.zero : res.spiritStoneSupreme;

    await ResourcesStorage.save(res); // 保存更新后的资源数据
    print('资源数据已更新');
    print('💰 下品：${res.spiritStoneLow}');
    print('💰 中品：${res.spiritStoneMid}');
    print('💰 上品：${res.spiritStoneHigh}');
    print('💰 极品：${res.spiritStoneSupreme}');
    return true; // 兑换成功
  }

  /// 获取最大可兑换数量
  static Future<int> getMaxExchangeAmount({
    required LingShiType fromType,
    required LingShiType toType,
    required Resources res,
  }) async {
    final fromField = lingShiFieldMap[fromType]!;
    final toField = lingShiFieldMap[toType]!;

    final fromRate = lingShiRates[fromType]!;
    final toRate = lingShiRates[toType]!;

    // 获取当前拥有的灵石数量
    BigInt available = await ResourcesStorage.getValue(fromField);

    // 计算最大可兑换数量
    final maxAmount = (available * fromRate ~/ toRate).toInt();
    print('最大可兑换数量：$maxAmount');
    return maxAmount; // 最大可兑换数量
  }
}


