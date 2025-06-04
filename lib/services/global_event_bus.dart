// 📂 lib/services/global_event_bus.dart

typedef EventCallback = void Function();

class EventBus {
  static final Map<String, List<EventCallback>> _listeners = {};

  /// 注册事件监听
  static void on(String event, EventCallback callback) {
    _listeners.putIfAbsent(event, () => []).add(callback);
  }

  /// 触发事件
  static void emit(String event) {
    final callbacks = _listeners[event];
    if (callbacks != null) {
      for (final callback in List.of(callbacks)) {
        callback();
      }
    }
  }

  /// 取消事件监听
  static void off(String event, EventCallback callback) {
    final callbacks = _listeners[event];
    callbacks?.remove(callback);
  }

  /// 清除所有监听（慎用）
  static void clear() {
    _listeners.clear();
  }
}
