import 'package:xiu_to_xiandi_tuixiu/services/player_storage.dart';

class Resources {
  // 💰 灵石系列
  BigInt spiritStoneLow;
  BigInt spiritStoneMid;
  BigInt spiritStoneHigh;
  BigInt spiritStoneSupreme;

  // 🪪 招募券系统
  int recruitTicket;         // ✅ 新字段，统一招募券
  int fateRecruitCharm;      // ✅ 资质提升券，保留！

  // 🏯 宗门资源
  BigInt contribution;
  BigInt reputation;

  // 🌬️ 修炼资源
  BigInt aura;
  BigInt insight;
  BigInt karma;
  BigInt wishPower;

  // ⚔️ 战斗资源
  BigInt refinedQi;
  BigInt mindEnergy;
  BigInt battleWill;

  Resources({
    BigInt? spiritStoneLow,
    BigInt? spiritStoneMid,
    BigInt? spiritStoneHigh,
    BigInt? spiritStoneSupreme,
    int? recruitTicket,
    int? fateRecruitCharm,
    BigInt? contribution,
    BigInt? reputation,
    BigInt? aura,
    BigInt? insight,
    BigInt? karma,
    BigInt? wishPower,
    BigInt? refinedQi,
    BigInt? mindEnergy,
    BigInt? battleWill,
  })  : spiritStoneLow = spiritStoneLow ?? BigInt.zero,
        spiritStoneMid = spiritStoneMid ?? BigInt.zero,
        spiritStoneHigh = spiritStoneHigh ?? BigInt.zero,
        spiritStoneSupreme = spiritStoneSupreme ?? BigInt.zero,
        recruitTicket = recruitTicket ?? 0,
        fateRecruitCharm = fateRecruitCharm ?? 0,
        contribution = contribution ?? BigInt.zero,
        reputation = reputation ?? BigInt.zero,
        aura = aura ?? BigInt.zero,
        insight = insight ?? BigInt.zero,
        karma = karma ?? BigInt.zero,
        wishPower = wishPower ?? BigInt.zero,
        refinedQi = refinedQi ?? BigInt.zero,
        mindEnergy = mindEnergy ?? BigInt.zero,
        battleWill = battleWill ?? BigInt.zero;

  factory Resources.fromMap(Map<String, dynamic> map) {
    BigInt parseBig(dynamic v) => BigInt.tryParse(v?.toString() ?? '0') ?? BigInt.zero;
    int parseInt(dynamic v) => int.tryParse(v?.toString() ?? '0') ?? 0;

    return Resources(
      spiritStoneLow: parseBig(map['spiritStoneLow']),
      spiritStoneMid: parseBig(map['spiritStoneMid']),
      spiritStoneHigh: parseBig(map['spiritStoneHigh']),
      spiritStoneSupreme: parseBig(map['spiritStoneSupreme']),
      recruitTicket: parseInt(map['recruitTicket']),
      fateRecruitCharm: parseInt(map['fateRecruitCharm']),
      contribution: parseBig(map['contribution']),
      reputation: parseBig(map['reputation']),
      aura: parseBig(map['aura']),
      insight: parseBig(map['insight']),
      karma: parseBig(map['karma']),
      wishPower: parseBig(map['wishPower']),
      refinedQi: parseBig(map['refinedQi']),
      mindEnergy: parseBig(map['mindEnergy']),
      battleWill: parseBig(map['battleWill']),
    );
  }

  Map<String, dynamic> toMap() => {
    'spiritStoneLow': spiritStoneLow.toString(),
    'spiritStoneMid': spiritStoneMid.toString(),
    'spiritStoneHigh': spiritStoneHigh.toString(),
    'spiritStoneSupreme': spiritStoneSupreme.toString(),
    'recruitTicket': recruitTicket,
    'fateRecruitCharm': fateRecruitCharm,
    'contribution': contribution.toString(),
    'reputation': reputation.toString(),
    'aura': aura.toString(),
    'insight': insight.toString(),
    'karma': karma.toString(),
    'wishPower': wishPower.toString(),
    'refinedQi': refinedQi.toString(),
    'mindEnergy': mindEnergy.toString(),
    'battleWill': battleWill.toString(),
  };

  void add(String type, int value) => addBigInt(type, BigInt.from(value));

  void addBigInt(String type, BigInt value) {
    if (_isIntField(type)) {
      final newValue = getIntValue(type) + value.toInt();
      _setInt(type, newValue);
    } else {
      final newValue = getValue(type) + value;
      _set(type, newValue);
    }
  }

  void subtract(String type, int value) => add(type, -value);

  BigInt getValue(String type) {
    if (_isIntField(type)) {
      return BigInt.from(getIntValue(type));
    }
    return BigInt.tryParse(toMap()[type]?.toString() ?? '0') ?? BigInt.zero;
  }

  int getIntValue(String type) {
    switch (type) {
      case 'recruitTicket':
        return recruitTicket;
      case 'fateRecruitCharm':
        return fateRecruitCharm;
      default:
        return 0;
    }
  }

  bool _isIntField(String type) =>
      type == 'recruitTicket' || type == 'fateRecruitCharm';

  void _set(String type, BigInt value) {
    switch (type) {
      case 'spiritStoneLow':
        spiritStoneLow = value;
        break;
      case 'spiritStoneMid':
        spiritStoneMid = value;
        break;
      case 'spiritStoneHigh':
        spiritStoneHigh = value;
        break;
      case 'spiritStoneSupreme':
        spiritStoneSupreme = value;
        break;
      case 'contribution':
        contribution = value;
        break;
      case 'reputation':
        reputation = value;
        break;
      case 'aura':
        aura = value;
        break;
      case 'insight':
        insight = value;
        break;
      case 'karma':
        karma = value;
        break;
      case 'wishPower':
        wishPower = value;
        break;
      case 'refinedQi':
        refinedQi = value;
        break;
      case 'mindEnergy':
        mindEnergy = value;
        break;
      case 'battleWill':
        battleWill = value;
        break;
    }
  }

  void _setInt(String type, int value) {
    switch (type) {
      case 'recruitTicket':
        recruitTicket = value;
        break;
      case 'fateRecruitCharm':
        fateRecruitCharm = value;
        break;
    }
  }

  void _copyFrom(Resources other) {
    spiritStoneLow = other.spiritStoneLow;
    spiritStoneMid = other.spiritStoneMid;
    spiritStoneHigh = other.spiritStoneHigh;
    spiritStoneSupreme = other.spiritStoneSupreme;
    recruitTicket = other.recruitTicket;
    fateRecruitCharm = other.fateRecruitCharm;
    contribution = other.contribution;
    reputation = other.reputation;
    aura = other.aura;
    insight = other.insight;
    karma = other.karma;
    wishPower = other.wishPower;
    refinedQi = other.refinedQi;
    mindEnergy = other.mindEnergy;
    battleWill = other.battleWill;
  }

  Future<void> saveToStorage() async {
    await PlayerStorage.updateField('resources', toMap());
  }
}

