import 'package:xiu_to_xiandi_tuixiu/services/resources_storage.dart';
import 'package:xiu_to_xiandi_tuixiu/models/resources.dart';
import 'package:xiu_to_xiandi_tuixiu/utils/bigint_extensions.dart';
import 'package:xiu_to_xiandi_tuixiu/utils/lingshi_util.dart';

class LingShiExchangeService {
  /// 执行灵石兑换
  static Future<bool> exchangeLingShi({
    required LingShiType fromType,
    required LingShiType toType,
    required BigInt inputAmount, // ✅ 改成 BigInt
    required Resources res,
  }) async {
    final fromField = lingShiFieldMap[fromType]!;
    final toField = lingShiFieldMap[toType]!;

    final BigInt available = await ResourcesStorage.getValue(fromField);
    final BigInt fromRate = lingShiRates[fromType]!;
    final BigInt toRate = lingShiRates[toType]!;

    final BigInt required = (toRate * inputAmount) ~/ fromRate;

    if (inputAmount <= BigInt.zero || required > available) {
      return false;
    }

    await ResourcesStorage.subtract(fromField, required);
    await ResourcesStorage.add(toField, inputAmount);

    final updatedRes = await ResourcesStorage.load();

    // 确保不为负
    updatedRes.spiritStoneLow = updatedRes.spiritStoneLow < BigInt.zero ? BigInt.zero : updatedRes.spiritStoneLow;
    updatedRes.spiritStoneMid = updatedRes.spiritStoneMid < BigInt.zero ? BigInt.zero : updatedRes.spiritStoneMid;
    updatedRes.spiritStoneHigh = updatedRes.spiritStoneHigh < BigInt.zero ? BigInt.zero : updatedRes.spiritStoneHigh;
    updatedRes.spiritStoneSupreme = updatedRes.spiritStoneSupreme < BigInt.zero ? BigInt.zero : updatedRes.spiritStoneSupreme;

    await ResourcesStorage.save(updatedRes);
    return true;
  }

  /// 获取最大可兑换数量（BigInt 返回）
  static Future<BigInt> getMaxExchangeAmount({
    required LingShiType fromType,
    required LingShiType toType,
    required Resources res,
  }) async {
    final fromField = lingShiFieldMap[fromType]!;
    final fromRate = lingShiRates[fromType]!;
    final toRate = lingShiRates[toType]!;

    final BigInt available = await ResourcesStorage.getValue(fromField);
    return (available * fromRate) ~/ toRate;
  }
}
