import 'package:flutter/material.dart';
import 'package:xiu_to_xiandi_tuixiu/services/player_storage.dart';
import 'package:xiu_to_xiandi_tuixiu/services/cultivation_tracker.dart';

class AppLifecycleManager extends StatefulWidget {
  final Widget child;

  const AppLifecycleManager({super.key, required this.child});

  @override
  State<AppLifecycleManager> createState() => _AppLifecycleManagerState();
}

class _AppLifecycleManagerState extends State<AppLifecycleManager>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.resumed) {
      debugPrint('📲 App 重新进入前台');

      final player = await PlayerStorage.getPlayer();
      if (player != null) {
        await CultivationTracker.initWithPlayer(player); // ⏳ 补算离线修为
        CultivationTracker.startGlobalTick();             // ⏱️ 重启 tick
      }
    } else if (state == AppLifecycleState.paused) {
      debugPrint('🌙 App 切后台');
      CultivationTracker.stopTick();
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
