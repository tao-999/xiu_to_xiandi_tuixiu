import 'dart:io';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'package:screen_retriever/screen_retriever.dart';

import '../services/setting_service.dart';

class SettingPage extends StatefulWidget {
  const SettingPage({super.key});

  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  DisplayMode _selectedDisplayMode = DisplayMode.windowed;
  Size _selectedResolution = SettingService.defaultResolution;

  final _availableResolutions = const [
    Size(1280, 720),
    Size(1600, 900),
    Size(1920, 1080),
    Size(2560, 1440),
  ];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final mode = await SettingService.getDisplayMode();
    final res = await SettingService.getResolution();
    setState(() {
      _selectedDisplayMode = mode;
      _selectedResolution = res;
    });
  }

  Future<void> _applySettings() async {
    await SettingService.saveSettings(_selectedDisplayMode, _selectedResolution);

    switch (_selectedDisplayMode) {
      case DisplayMode.windowed:
        await windowManager.setFullScreen(false);
        await windowManager.setResizable(true);
        await windowManager.setHasShadow(true);
        await windowManager.setTitleBarStyle(TitleBarStyle.normal);
        await windowManager.setSize(_selectedResolution);
        await windowManager.setPosition(const Offset(100, 100));
        break;

      case DisplayMode.fullscreen:
        await windowManager.setFullScreen(true);
        break;

      case DisplayMode.borderless:
        await windowManager.setFullScreen(false);
        await windowManager.setResizable(false);
        await windowManager.setHasShadow(false);
        await windowManager.setTitleBarStyle(TitleBarStyle.hidden);
        final display = await screenRetriever.getPrimaryDisplay();
        final size = display.size;
        await windowManager.setBounds(Rect.fromLTWH(0, 0, size.width, size.height));
        break;
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('设置已应用 ✅')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212), // 🌚 暗色背景
      appBar: AppBar(
        title: const Text('设置中心'),
        backgroundColor: const Color(0xFF1E1E1E),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: '退出游戏',
            icon: const Icon(Icons.exit_to_app),
            onPressed: () {
              exit(0); // 💥 立即退出游戏进程
            },
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 420,
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: DefaultTextStyle(
              style: const TextStyle(color: Colors.white),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('显示模式', style: TextStyle(fontSize: 18)),
                  const SizedBox(height: 8),
                  DropdownButton<DisplayMode>(
                    value: _selectedDisplayMode,
                    dropdownColor: const Color(0xFF2A2A2A),
                    style: const TextStyle(color: Colors.white),
                    isExpanded: true,
                    items: DisplayMode.values.map((mode) {
                      return DropdownMenuItem(
                        value: mode,
                        child: Text({
                          DisplayMode.windowed: '窗口模式',
                          DisplayMode.fullscreen: '全屏模式',
                          DisplayMode.borderless: '无边框窗口',
                        }[mode]!),
                      );
                    }).toList(),
                    onChanged: (mode) {
                      if (mode != null) {
                        setState(() => _selectedDisplayMode = mode);
                      }
                    },
                  ),
                  const SizedBox(height: 24),
                  const Text('分辨率', style: TextStyle(fontSize: 18)),
                  const SizedBox(height: 8),
                  DropdownButton<Size>(
                    value: _selectedResolution,
                    dropdownColor: const Color(0xFF2A2A2A),
                    style: const TextStyle(color: Colors.white),
                    isExpanded: true,
                    items: _availableResolutions.map((res) {
                      return DropdownMenuItem(
                        value: res,
                        child: Text('${res.width.toInt()} x ${res.height.toInt()}'),
                      );
                    }).toList(),
                    onChanged: (res) {
                      if (res != null) {
                        setState(() => _selectedResolution = res);
                      }
                    },
                  ),
                  const SizedBox(height: 32),
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: _applySettings,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                      icon: const Icon(Icons.check),
                      label: const Text('应用设置'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
