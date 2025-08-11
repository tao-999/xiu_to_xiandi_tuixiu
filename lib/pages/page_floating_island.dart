import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // 🔧 关输入法/焦点
import 'package:flame/game.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/floating_island_map_component.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/player_distance_indicator.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/floating_island_map_loader.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/root_menu.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/gift_button_overlay.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/xiuxian_era_label.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/resource_bar.dart';
import 'package:xiu_to_xiandi_tuixiu/services/player_storage.dart';
import 'package:xiu_to_xiandi_tuixiu/utils/route_observer.dart';

import '../platform/ime_guard.dart';                 // ✅ 窗口级禁用 IME（Windows）
import '../widgets/components/character_panel.dart';

class FloatingIslandPage extends StatefulWidget {
  const FloatingIslandPage({super.key});

  @override
  State<FloatingIslandPage> createState() => FloatingIslandPageState();
}

class FloatingIslandPageState extends State<FloatingIslandPage> with RouteAware {
  FloatingIslandMapComponent? _mapComponent;
  bool _hasSeed = false;
  String _gender = 'male';

  // 🔥 用 key 控制资源条刷新的骚操作
  final GlobalKey<ResourceBarState> _resourceBarKey = GlobalKey<ResourceBarState>();

  // 🎯 唯一给 GameWidget 用的焦点节点（不包外层 Focus，防环引用）
  final FocusNode _gameFocus = FocusNode(
    debugLabel: 'GameFocus',
    skipTraversal: true,
    canRequestFocus: true,
  );

  @override
  void initState() {
    super.initState();
    _loadPlayerGender();

    // ✅ 窗口模式：顶层窗 + Flutter 子视图窗同时禁用 IME（带重试）
    ImeGuard.disableForWindow();

    // 焦点变化时，顺手把软键盘也关掉（双保险）
    _gameFocus.addListener(() {
      if (_gameFocus.hasFocus) {
        SystemChannels.textInput.invokeMethod('TextInput.hide');
      }
    });

    // 首帧给游戏抢焦点
    WidgetsBinding.instance.addPostFrameCallback((_) => _takeGameFocus());
  }

  // 抢焦点 + 关输入法（用在点击地图、返回页面等场景）
  void _takeGameFocus() {
    _gameFocus.requestFocus();
    SystemChannels.textInput.invokeMethod('TextInput.hide');
  }

  Future<void> _loadPlayerGender() async {
    final player = await PlayerStorage.getPlayer();
    if (!mounted) return;
    setState(() {
      _gender = player?.gender ?? 'male';
    });
  }

  void destroyMapComponent() {
    _mapComponent?.onRemove();
    setState(() {
      _mapComponent = null;
      _hasSeed = false;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)! as PageRoute);
  }

  @override
  void dispose() {
    debugPrint('🚨 FloatingIslandPage dispose triggered');
    routeObserver.unsubscribe(this);
    _mapComponent?.saveState();
    _destroyMapComponent();

    // ✅ 离开地图时恢复 IME
    ImeGuard.restore();

    _gameFocus.dispose();
    super.dispose();
  }

  void _destroyMapComponent() {
    if (_mapComponent != null) {
      _mapComponent!.pauseEngine();
      _mapComponent!.onRemove(); // 你可以 override onRemove 做清理
      _mapComponent = null;
    }
  }

  @override
  void didPopNext() {
    debugPrint('👋 FloatingIslandPage popped');
    _resourceBarKey.currentState?.refresh();
    _takeGameFocus(); // 回来时把焦点拉回给游戏
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ✅ 地图组件（用 Listener 抢焦点，不参与手势竞技场 → 拖拽/缩放正常）
          if (_mapComponent != null)
            Positioned.fill(
              child: Listener(
                behavior: HitTestBehavior.translucent,
                onPointerDown: (_) => _takeGameFocus(),
                child: GameWidget(
                  game: _mapComponent!,
                  focusNode: _gameFocus, // ✅ 只在这里使用同一个 FocusNode
                  autofocus: true,
                ),
              ),
            ),

          // ✅ 初始加载地图
          if (!_hasSeed)
            FloatingIslandMapLoader(
              onSeedReady: (seed) {
                setState(() {
                  _hasSeed = true;
                  _mapComponent = FloatingIslandMapComponent(
                    seed: seed,
                    resourceBarKey: _resourceBarKey,
                  );
                });
                // 地图创建完立刻把焦点给游戏
                WidgetsBinding.instance.addPostFrameCallback((_) => _takeGameFocus());
              },
            ),

          // ✅ 资源条（顶部居中）
          if (_mapComponent != null)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ResourceBar(key: _resourceBarKey),
                ],
              ),
            ),

          // ✅ 第二行：玄历 + 礼物按钮 + 距离指示器（左上）
          if (_mapComponent != null)
            Positioned(
              top: 25,
              left: 15,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const XiuxianEraLabel(),
                  const SizedBox(height: 8),
                  GiftButtonOverlay(
                    onGiftClaimed: () {
                      _resourceBarKey.currentState?.refresh();
                    },
                  ),
                  const SizedBox(height: 8),
                  PlayerDistanceIndicator(mapComponent: _mapComponent!),
                ],
              ),
            ),

          // 🆕 用 Positioned 把右侧的角色面板独立放置
          const Positioned(
            top: 10,
            right: 50, // 调整这个值定位角色面板的位置
            child: CharacterPanel(),
          ),

          // ✅ 第三行：底部菜单
          if (_mapComponent != null)
            Positioned(
              top: 85,
              left: 15,
              right: 15,
              child: RootMenu(
                gender: _gender,
                mapComponent: _mapComponent!,
                onChanged: () {
                  _resourceBarKey.currentState?.refresh();
                },
              ),
            ),

          // ✅ 右上角定位按钮
          if (_mapComponent != null)
            Positioned(
              top: 80,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.my_location, color: Colors.white),
                onPressed: () => _mapComponent!.centerOnPlayer(),
              ),
            ),
        ],
      ),
    );
  }
}
