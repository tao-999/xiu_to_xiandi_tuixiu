class AptitudeGate {
  final int minAptitude; // 达到这个资质才能达到对应境界
  final String realmName; // 显示名称（如“太清仙”）

  const AptitudeGate({
    required this.minAptitude,
    required this.realmName,
  });
}

final List<AptitudeGate> aptitudeTable = [
  AptitudeGate(minAptitude: 211, realmName: '退休仙帝'),
  AptitudeGate(minAptitude: 201, realmName: '至尊仙帝'),
  AptitudeGate(minAptitude: 191, realmName: '太清仙'),
  AptitudeGate(minAptitude: 181, realmName: '太乙仙'),
  AptitudeGate(minAptitude: 171, realmName: '混元仙'),
  AptitudeGate(minAptitude: 161, realmName: '圣仙'),
  AptitudeGate(minAptitude: 151, realmName: '虚仙'),
  AptitudeGate(minAptitude: 141, realmName: '灵仙'),
  AptitudeGate(minAptitude: 131, realmName: '玄仙'),
  AptitudeGate(minAptitude: 121, realmName: '真仙'),
  AptitudeGate(minAptitude: 111, realmName: '天仙'),
  AptitudeGate(minAptitude: 101, realmName: '地仙'),
  AptitudeGate(minAptitude: 91, realmName: '飞升'),
  AptitudeGate(minAptitude: 81, realmName: '渡劫期'),
  AptitudeGate(minAptitude: 71, realmName: '大乘期'),
  AptitudeGate(minAptitude: 61, realmName: '合体期'),
  AptitudeGate(minAptitude: 51, realmName: '炼虚期'),
  AptitudeGate(minAptitude: 41, realmName: '化神期'),
  AptitudeGate(minAptitude: 31, realmName: '元婴期'),
  AptitudeGate(minAptitude: 21, realmName: '金丹期'),
  AptitudeGate(minAptitude: 11, realmName: '筑基期'),
  AptitudeGate(minAptitude: 1, realmName: '练气期'),
];
