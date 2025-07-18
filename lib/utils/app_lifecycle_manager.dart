import 'package:flutter/material.dart';
import 'package:xiu_to_xiandi_tuixiu/services/player_storage.dart';

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
    } else if (state == AppLifecycleState.paused) {
      debugPrint('🌙 App 切后台');
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
