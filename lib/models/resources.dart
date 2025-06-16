class Resources {
  // 💰 灵石系列
  BigInt spiritStoneLow;
  BigInt spiritStoneMid;
  BigInt spiritStoneHigh;
  BigInt spiritStoneSupreme;

  // 🪪 招募券系统
  int recruitTicket;
  int fateRecruitCharm;

  // 🌬️ 修炼资源
  BigInt aura;
  BigInt insight;
  BigInt karma;
  BigInt wishPower;

  // ⚔️ 战斗资源
  BigInt refinedQi;
  BigInt mindEnergy;
  BigInt battleWill;

  // 📜 图纸唯一 key 列表，例如 weapon-1、armor-3（图纸类型-阶数）
  List<String> ownedBlueprintKeys;

  Resources({
    BigInt? spiritStoneLow,
    BigInt? spiritStoneMid,
    BigInt? spiritStoneHigh,
    BigInt? spiritStoneSupreme,
    int? recruitTicket,
    int? fateRecruitCharm,
    BigInt? aura,
    BigInt? insight,
    BigInt? karma,
    BigInt? wishPower,
    BigInt? refinedQi,
    BigInt? mindEnergy,
    BigInt? battleWill,
    List<String>? ownedBlueprintKeys,
  })  : spiritStoneLow = spiritStoneLow ?? BigInt.zero,
        spiritStoneMid = spiritStoneMid ?? BigInt.zero,
        spiritStoneHigh = spiritStoneHigh ?? BigInt.zero,
        spiritStoneSupreme = spiritStoneSupreme ?? BigInt.zero,
        recruitTicket = recruitTicket ?? 0,
        fateRecruitCharm = fateRecruitCharm ?? 0,
        aura = aura ?? BigInt.zero,
        insight = insight ?? BigInt.zero,
        karma = karma ?? BigInt.zero,
        wishPower = wishPower ?? BigInt.zero,
        refinedQi = refinedQi ?? BigInt.zero,
        mindEnergy = mindEnergy ?? BigInt.zero,
        battleWill = battleWill ?? BigInt.zero,
        ownedBlueprintKeys = ownedBlueprintKeys ?? [];

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
      aura: parseBig(map['aura']),
      insight: parseBig(map['insight']),
      karma: parseBig(map['karma']),
      wishPower: parseBig(map['wishPower']),
      refinedQi: parseBig(map['refinedQi']),
      mindEnergy: parseBig(map['mindEnergy']),
      battleWill: parseBig(map['battleWill']),
      ownedBlueprintKeys: List<String>.from(map['ownedBlueprintKeys'] ?? []),
    );
  }

  Map<String, dynamic> toMap() => {
    'spiritStoneLow': spiritStoneLow.toString(),
    'spiritStoneMid': spiritStoneMid.toString(),
    'spiritStoneHigh': spiritStoneHigh.toString(),
    'spiritStoneSupreme': spiritStoneSupreme.toString(),
    'recruitTicket': recruitTicket,
    'fateRecruitCharm': fateRecruitCharm,
    'aura': aura.toString(),
    'insight': insight.toString(),
    'karma': karma.toString(),
    'wishPower': wishPower.toString(),
    'refinedQi': refinedQi.toString(),
    'mindEnergy': mindEnergy.toString(),
    'battleWill': battleWill.toString(),
    'ownedBlueprintKeys': ownedBlueprintKeys,
  };
}
