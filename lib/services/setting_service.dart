import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum DisplayMode { windowed, fullscreen, borderless }

class SettingService {
  static const _keyDisplayMode = 'displayMode';
  static const _keyResolutionWidth = 'resolutionWidth';
  static const _keyResolutionHeight = 'resolutionHeight';

  static const defaultResolution = Size(1280, 720);

  /// 📦 保存设置
  static Future<void> saveSettings(DisplayMode mode, Size resolution) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyDisplayMode, mode.index);
    await prefs.setDouble(_keyResolutionWidth, resolution.width);
    await prefs.setDouble(_keyResolutionHeight, resolution.height);
  }

  /// 🧠 读取显示模式
  static Future<DisplayMode> getDisplayMode() async {
    final prefs = await SharedPreferences.getInstance();
    final index = prefs.getInt(_keyDisplayMode) ?? 0;
    return DisplayMode.values[index];
  }

  /// 🧠 读取分辨率
  static Future<Size> getResolution() async {
    final prefs = await SharedPreferences.getInstance();
    final width = prefs.getDouble(_keyResolutionWidth) ?? defaultResolution.width;
    final height = prefs.getDouble(_keyResolutionHeight) ?? defaultResolution.height;
    return Size(width, height);
  }

  /// 🔍 根据分辨率推导地图缩放倍率（供地图调用）
  static double getZoomForResolution(Size resolution) {
    final w = resolution.width;
    if (w <= 1280) return 0.75;
    if (w <= 1600) return 0.9;
    if (w <= 1920) return 1.0;
    return 1.2;
  }
}
