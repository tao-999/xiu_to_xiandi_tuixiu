import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/floating_island_map_component.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/player_distance_indicator.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/floating_island_map_loader.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/root_bottom_menu.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/gift_button_overlay.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/xiuxian_era_label.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/resource_bar.dart';
import 'package:xiu_to_xiandi_tuixiu/services/player_storage.dart';
import 'package:xiu_to_xiandi_tuixiu/utils/route_observer.dart';

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

  @override
  void initState() {
    super.initState();
    _loadPlayerGender();
  }

  Future<void> _loadPlayerGender() async {
    final player = await PlayerStorage.getPlayer();
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
    routeObserver.unsubscribe(this);
    _mapComponent?.saveState();
    _mapComponent?.onRemove();
    super.dispose();
  }

  @override
  void didPopNext() {
    debugPrint('👋 FloatingIslandPage popped');
    _resourceBarKey.currentState?.refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ✅ 地图组件
          if (_mapComponent != null)
            Positioned.fill(child: GameWidget(game: _mapComponent!)),

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
              top: 60,
              left: 20,
              child: Row(
                children: [
                  const XiuxianEraLabel(),
                  const SizedBox(width: 12),
                  GiftButtonOverlay(
                    onGiftClaimed: () {
                      _resourceBarKey.currentState?.refresh();
                    },
                  ),
                  const SizedBox(width: 12),
                  PlayerDistanceIndicator(mapComponent: _mapComponent!),
                ],
              ),
            ),

          // ✅ 第三行：底部菜单
          if (_mapComponent != null)
            Positioned(
              top: 100,
              left: 20,
              right: 20,
              child: RootBottomMenu(
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
              top: 40,
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
