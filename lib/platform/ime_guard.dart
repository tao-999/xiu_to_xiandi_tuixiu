// 📄 lib/platform/ime_guard.dart
import 'dart:async';
import 'dart:ffi';
import 'dart:io' show Platform;

import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart' as win;

// --------- IMM32 绑定 ----------
typedef _ImmAssociateContextNative = IntPtr Function(IntPtr hWnd, IntPtr hIMC);
typedef _ImmAssociateContextDart = int Function(int hWnd, int hIMC);
final DynamicLibrary _imm32 = DynamicLibrary.open('imm32.dll');
final _ImmAssociateContextDart _immAssociateContext =
_imm32.lookupFunction<_ImmAssociateContextNative, _ImmAssociateContextDart>(
    'ImmAssociateContext');

// --------- 小工具 ----------
Pointer<Utf16> _w(String s) => s.toNativeUtf16();

int _findFlutterTopWindow() {
  // 优先用 Flutter 的顶层类名
  final cls = _w('FLUTTER_RUNNER_WIN32_WINDOW');
  final hwnd = win.FindWindow(cls, nullptr);
  calloc.free(cls);
  if (hwnd != 0) return hwnd;

  // 兜底：当前前台窗口
  return win.GetForegroundWindow();
}

int _findFlutterViewWindow(int parentHwnd) {
  if (parentHwnd == 0) return 0;
  // 先找 FLUTTER_VIEW
  var cls = _w('FLUTTER_VIEW');
  var child = win.FindWindowEx(parentHwnd, 0, cls, nullptr);
  calloc.free(cls);
  if (child != 0) return child;

  // 再试 FLUTTERVIEW（有些版本用这个）
  cls = _w('FLUTTERVIEW');
  child = win.FindWindowEx(parentHwnd, 0, cls, nullptr);
  calloc.free(cls);
  return child;
}

// --------- 对外 API ----------
class ImeGuard {
  static int? _prevTop;
  static int? _prevView;
  static int? _hwndTop;
  static int? _hwndView;
  static Timer? _retryTimer;

  /// 禁用 IME（顶层+子视图都禁），多次重试直到成功或超时
  static void disableForWindow({Duration timeout = const Duration(seconds: 2)}) {
    if (!Platform.isWindows) return;

    // 先来一次立即尝试
    final done = _applyOnce();

    if (!done) {
      // 窗口可能还没激活，启动重试（每 200ms）
      var elapsed = Duration.zero;
      _retryTimer?.cancel();
      _retryTimer = Timer.periodic(const Duration(milliseconds: 200), (t) {
        elapsed += const Duration(milliseconds: 200);
        final ok = _applyOnce();
        if (ok || elapsed >= timeout) {
          t.cancel();
          _retryTimer = null;
        }
      });
    }
  }

  /// 恢复进入前的 IME 状态
  static void restore() {
    if (!Platform.isWindows) return;
    try {
      final top = _hwndTop ?? _findFlutterTopWindow();
      final view = _hwndView ?? _findFlutterViewWindow(top);

      if (view != null && view != 0) {
        _immAssociateContext(view, _prevView ?? 0);
      }
      if (top != null && top != 0) {
        _immAssociateContext(top, _prevTop ?? 0);
      }
    } catch (_) {
      // 忽略恢复失败
    } finally {
      _prevTop = null;
      _prevView = null;
      _hwndTop = null;
      _hwndView = null;
    }
  }

  /// 实际执行一次禁用操作；返回是否有任何一个窗口成功应用
  static bool _applyOnce() {
    final top = _findFlutterTopWindow();
    final view = _findFlutterViewWindow(top);
    _hwndTop = top;
    _hwndView = view;

    var applied = false;

    if (top != 0) {
      _prevTop ??= _immAssociateContext(top, 0);
      applied = true;
    }
    if (view != 0) {
      _prevView ??= _immAssociateContext(view, 0);
      applied = true;
    }

    return applied;
  }
}
