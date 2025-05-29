class AptitudeGate {
  final int minAptitude; // 达到这个资质才能达到对应境界
  final String realmName; // 显示名称（如“太清仙”）

  const AptitudeGate({
    required this.minAptitude,
    required this.realmName,
  });
}

final List<AptitudeGate> aptitudeTable = [
  AptitudeGate(minAptitude: 200, realmName: '退休仙帝'),
  AptitudeGate(minAptitude: 190, realmName: '至尊仙帝'),
  AptitudeGate(minAptitude: 180, realmName: '太清仙'),
  AptitudeGate(minAptitude: 170, realmName: '太乙仙'),
  AptitudeGate(minAptitude: 160, realmName: '混元仙'),
  AptitudeGate(minAptitude: 150, realmName: '圣仙'),
  AptitudeGate(minAptitude: 140, realmName: '虚仙'),
  AptitudeGate(minAptitude: 130, realmName: '灵仙'),
  AptitudeGate(minAptitude: 120, realmName: '玄仙'),
  AptitudeGate(minAptitude: 110, realmName: '真仙'),
  AptitudeGate(minAptitude: 100, realmName: '天仙'),
  AptitudeGate(minAptitude: 90, realmName: '地仙'),
  AptitudeGate(minAptitude: 80, realmName: '渡劫期'),
  AptitudeGate(minAptitude: 70, realmName: '大乘期'),
  AptitudeGate(minAptitude: 60, realmName: '合体期'),
  AptitudeGate(minAptitude: 50, realmName: '炼虚期'),
  AptitudeGate(minAptitude: 40, realmName: '化神期'),
  AptitudeGate(minAptitude: 30, realmName: '元婴期'),
  AptitudeGate(minAptitude: 20, realmName: '金丹期'),
  AptitudeGate(minAptitude: 10, realmName: '筑基期'),
  AptitudeGate(minAptitude: 1, realmName: '练气期'),
];
