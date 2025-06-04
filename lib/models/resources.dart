/// 📦 Resources —— 修士角色身上的资源系统
/// 管理各种灵石、灵气、贡献、因果、招募券等资源，用于修炼、招募、兑换、剧情等功能

import 'package:xiu_to_xiandi_tuixiu/services/player_storage.dart';

class Resources {
  // 💰 灵石系列（修炼提升专用）
  int spiritStoneLow;      // 下品灵石
  int spiritStoneMid;      // 中品灵石
  int spiritStoneHigh;     // 上品灵石
  int spiritStoneSupreme;  // 极品灵石

  // 🪪 招募资源（仅用于招募）
  int humanRecruitTicket;  // 人界招募券（人界弟子招募）
  int immortalSummonOrder; // 仙界召唤令（仙界高阶弟子）
  int fateRecruitCharm;    // 资质提升券（

  // 🏯 宗门资源（兑换、宗门建筑升级等）
  int contribution;        // 宗门贡献
  int reputation;          // 声望值（拜访其他宗门、开启隐藏事件）

  // 🌬️ 修炼资源（挂机获取、突破使用）
  int aura;                // 灵气（挂机积累）
  int insight;             // 悟性（突破/参悟用）
  int karma;               // 因果点（剧情相关、特定弟子招募）
  int wishPower;           // 愿力（保命/特殊召唤）

  // ⚔️ 战斗资源（战斗释放技能用）
  int refinedQi;           // 真元（法术/法宝驱动）
  int mindEnergy;          // 神识（御剑、控制）
  int battleWill;          // 战意（连续战斗提升，触发爆发技能）

  Resources({
    this.spiritStoneLow = 0,
    this.spiritStoneMid = 0,
    this.spiritStoneHigh = 0,
    this.spiritStoneSupreme = 0,
    this.humanRecruitTicket = 0,
    this.immortalSummonOrder = 0,
    this.fateRecruitCharm = 0,
    this.contribution = 0,
    this.reputation = 0,
    this.aura = 0,
    this.insight = 0,
    this.karma = 0,
    this.wishPower = 0,
    this.refinedQi = 0,
    this.mindEnergy = 0,
    this.battleWill = 0,
  });

  /// ✅ 从 Map 构造资源对象
  factory Resources.fromMap(Map<String, dynamic> map) {
    return Resources(
      spiritStoneLow: map['spiritStoneLow'] ?? 0,
      spiritStoneMid: map['spiritStoneMid'] ?? 0,
      spiritStoneHigh: map['spiritStoneHigh'] ?? 0,
      spiritStoneSupreme: map['spiritStoneSupreme'] ?? 0,
      humanRecruitTicket: map['humanRecruitTicket'] ?? 0,
      immortalSummonOrder: map['immortalSummonOrder'] ?? 0,
      fateRecruitCharm: map['fateRecruitCharm'] ?? 0,
      contribution: map['contribution'] ?? 0,
      reputation: map['reputation'] ?? 0,
      aura: map['aura'] ?? 0,
      insight: map['insight'] ?? 0,
      karma: map['karma'] ?? 0,
      wishPower: map['wishPower'] ?? 0,
      refinedQi: map['refinedQi'] ?? 0,
      mindEnergy: map['mindEnergy'] ?? 0,
      battleWill: map['battleWill'] ?? 0,
    );
  }

  /// ✅ 转为 Map（用于存储）
  Map<String, dynamic> toMap() => {
    'spiritStoneLow': spiritStoneLow,
    'spiritStoneMid': spiritStoneMid,
    'spiritStoneHigh': spiritStoneHigh,
    'spiritStoneSupreme': spiritStoneSupreme,
    'humanRecruitTicket': humanRecruitTicket,
    'immortalSummonOrder': immortalSummonOrder,
    'fateRecruitCharm': fateRecruitCharm,
    'contribution': contribution,
    'reputation': reputation,
    'aura': aura,
    'insight': insight,
    'karma': karma,
    'wishPower': wishPower,
    'refinedQi': refinedQi,
    'mindEnergy': mindEnergy,
    'battleWill': battleWill,
  };

  /// ✅ 增加指定资源（支持负数，等同于消耗）
  void add(String type, int value) {
    final newValue = getValue(type) + value;
    _set(type, newValue);
  }

  /// ✅ 减少指定资源（语义 sugar）
  void subtract(String type, int value) => add(type, -value);

  /// ✅ 获取资源值
  int getValue(String type) => toMap()[type] ?? 0;

  /// ✅ 设置某个资源的值（内部私用）
  void _set(String type, int value) {
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
      case 'humanRecruitTicket':
        humanRecruitTicket = value;
        break;
      case 'immortalSummonOrder':
        immortalSummonOrder = value;
        break;
      case 'fateRecruitCharm':
        fateRecruitCharm = value;
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

  /// ✅ 从另一个资源对象复制值
  void _copyFrom(Resources other) {
    spiritStoneLow = other.spiritStoneLow;
    spiritStoneMid = other.spiritStoneMid;
    spiritStoneHigh = other.spiritStoneHigh;
    spiritStoneSupreme = other.spiritStoneSupreme;
    humanRecruitTicket = other.humanRecruitTicket;
    immortalSummonOrder = other.immortalSummonOrder;
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

  /// ✅ 保存当前资源到 SharedPreferences
  Future<void> saveToStorage() async {
    await PlayerStorage.updateField('resources', toMap());
  }
}
