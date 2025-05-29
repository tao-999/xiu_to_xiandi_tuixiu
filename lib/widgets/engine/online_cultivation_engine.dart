// lib/engine/online_cultivation_engine.dart

class OnlineCultivationEngine {
  double _cultivation = 0.0;       // 当前修为值
  double _qiPerSecond = 1.0;       // 每秒增长量

  OnlineCultivationEngine({
    double initialQi = 0.0,
    double qiPerSecond = 1.0,
  }) {
    _cultivation = initialQi;
    _qiPerSecond = qiPerSecond;
  }

  /// 每帧调用，传入 dt 秒
  void tick(double deltaSeconds) {
    _cultivation += _qiPerSecond * deltaSeconds;
  }

  /// 设置当前修为
  void setCultivation(double value) {
    _cultivation = value;
  }

  /// 设置增长速率（可动态调整）
  void setRate(double rate) {
    _qiPerSecond = rate;
  }

  /// 获取当前修为
  double get cultivation => _cultivation;

  /// 获取修为文本
  String getFormatted() => _cultivation.toStringAsFixed(1);
}
