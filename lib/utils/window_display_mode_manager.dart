import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'package:screen_retriever/screen_retriever.dart';
import '../services/setting_service.dart';

class WindowDisplayModeManager {
  static Future<void> applyDisplayMode() async {
    final mode = await SettingService.getDisplayMode();
    final resolution = await SettingService.getResolution();
    final display = await screenRetriever.getPrimaryDisplay();

    debugPrint('🧭 读取到模式: $mode');

    final windowOptions = WindowOptions(
      size: resolution,
      center: true,
      title: '宗主请留步',
      minimumSize: const Size(1280, 720),
      titleBarStyle: TitleBarStyle.normal,
      backgroundColor: Colors.transparent,
    );

    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      // ✅ 必须先 show，再改 fullscreen，否则会卡死
      debugPrint('🪟 show 窗口...');
      await windowManager.show();
      await windowManager.focus();

      await Future.delayed(const Duration(milliseconds: 300)); // 延迟确保窗口完全 ready

      if (mode == DisplayMode.fullscreen) {
        try {
          debugPrint('🖥️ 尝试设置 fullscreen...');
          await windowManager.setFullScreen(true);

          await Future.delayed(const Duration(milliseconds: 200));
          final ok = await windowManager.isFullScreen();
          debugPrint('✅ 全屏状态确认: $ok');
        } catch (e) {
          debugPrint('❌ 全屏设置失败: $e');
        }
      }

      if (mode == DisplayMode.windowed) {
        debugPrint('🖥️ 设置为 windowed 模式');
        await windowManager.setFullScreen(false);
        await windowManager.setSize(resolution);
        await windowManager.setPosition(const Offset(100, 100));
      }

      if (mode == DisplayMode.borderless) {
        debugPrint('🖥️ 设置为 borderless 模式');
        await windowManager.setFullScreen(false);
        await windowManager.setHasShadow(false);
        await windowManager.setResizable(false);
        await windowManager.setBounds(
          Rect.fromLTWH(0, 0, display.size.width, display.size.height),
        );
      }
    });
  }
}
