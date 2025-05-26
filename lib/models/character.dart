class Character {
  final String id;
  String name;
  String gender; // 男 / 女
  String realm; // 如：炼气三层
  String career; // 职业，例如“散修”/“炼丹师”
  int level;
  int exp;
  int expMax;

  // 核心属性
  int hp;
  int atk;
  int def;
  double atkSpeed;

  // 战斗相关
  double critRate;
  double critDamage;
  double dodgeRate;
  double lifeSteal;
  double breakArmorRate;
  double luckRate;
  double comboRate;

  // 光环类
  double evilAura;
  double weakAura;
  double corrosionAura;

  // 五行属性（建议用 Map）
  Map<String, int> elements; // 例如：{'金': 8, '木': 5, '水': 3, '火': 2, '土': 4}

  // 当前修炼心法
  String technique;

  Character({
    required this.id,
    required this.name,
    required this.gender,
    required this.realm,
    required this.career,
    required this.level,
    required this.exp,
    required this.expMax,
    required this.hp,
    required this.atk,
    required this.def,
    required this.atkSpeed,
    required this.critRate,
    required this.critDamage,
    required this.dodgeRate,
    required this.lifeSteal,
    required this.breakArmorRate,
    required this.luckRate,
    required this.comboRate,
    required this.evilAura,
    required this.weakAura,
    required this.corrosionAura,
    required this.elements,
    required this.technique,
  });

  int get totalElement => elements.values.reduce((a, b) => a + b);

  int get power => (atk * 2 + def + hp / 2 + (critRate * 100).toInt() + totalElement * 10).toInt();
}
