import 'package:flutter/material.dart';
import 'package:xiu_to_xiandi_tuixiu/pages/page_zongmen.dart';
import 'package:xiu_to_xiandi_tuixiu/pages/page_chiyangu.dart';
import 'package:xiu_to_xiandi_tuixiu/pages/page_huanyue_explore.dart';
import 'package:xiu_to_xiandi_tuixiu/pages/page_market.dart';
import 'package:xiu_to_xiandi_tuixiu/pages/page_xianling_qizhen.dart';
import 'package:xiu_to_xiandi_tuixiu/services/menu_state_service.dart';

import '../../pages/page_naihe_bridge.dart';
import '../dialogs/beibao_dialog.dart';
import '../dialogs/character_dialog.dart';
import '../dialogs/recruit_dialog.dart';
import 'floating_island_map_component.dart'; // 角色弹框

class RootBottomMenu extends StatefulWidget {
  final String gender;
  final VoidCallback? onChanged;
  final FloatingIslandMapComponent mapComponent; // ✅ 新增

  const RootBottomMenu({
    super.key,
    required this.gender,
    required this.mapComponent, // ✅ 必传
    this.onChanged,
  });

  @override
  State<RootBottomMenu> createState() => _RootBottomMenuState();
}

class _RootBottomMenuState extends State<RootBottomMenu>
    with SingleTickerProviderStateMixin {
  bool _expanded = true;
  late final AnimationController _controller;
  late List<Animation<double>> _itemAnimations;
  late final List<String> _iconPaths;

  @override
  void initState() {
    super.initState();

    _iconPaths = [
      widget.gender == 'female'
          ? 'assets/images/icon_dazuo_female.png'
          : 'assets/images/icon_dazuo_male.png',
      'assets/images/icon_beibao.png',
      'assets/images/icon_zongmen.png',
      'assets/images/icon_zhaomu.png',
      'assets/images/youli_fanchenshiji.png',
      'assets/images/youli_huanyueshan.png',
      'assets/images/youli_ciyangu.png',
      'assets/images/youli_naiheqiao.png',
    ];

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _itemAnimations = List.generate(_iconPaths.length, (i) {
      final count = _iconPaths.length;
      final maxIndex = count - 1;
      final start = (i / count).clamp(0.0, 1.0);
      final end = (i == maxIndex)
          ? 1.0
          : ((i + 1) / count).clamp(0.0, 1.0 - 0.000001);

      return CurvedAnimation(
        parent: _controller,
        curve: Interval(start, end, curve: Curves.easeOut),
      );
    });

    _loadExpandedState();
  }

  Future<void> _loadExpandedState() async {
    final state = await MenuStateService.loadExpandedState();
    setState(() {
      _expanded = state;
      if (_expanded) {
        _controller.forward(from: 0);
      } else {
        _controller.value = 0;
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap(BuildContext context, int index) {
    final Widget page;

    switch (index) {
      case 0:
      // 角色弹窗
        showDialog(
          context: context,
          builder: (_) => CharacterDialog(
            onChanged: widget.onChanged, // ✅ 透传回调
          ),
        );
        return;

      case 1:
      // 背包弹窗，扩容回调统一透传 onChanged
        showDialog(
          context: context,
          builder: (_) => BeibaoDialog(
            onChanged: widget.onChanged, // ✅ 直接透传
          ),
        );
        return;

      case 2:
        page = const ZongmenPage();
        break;
      case 3:
        showDialog(
          context: context,
          builder: (_) => RecruitDialog(
            onChanged: widget.onChanged,
          ),
        );
        return;
      case 4:
        page = const XiuXianMarketPage();
        break;
      case 5:
        page = const HuanyueExplorePage();
        break;
      case 6:
        page = const ChiyanguPage();
        break;
      case 7:
        page = const NaiheBridgePage();
        break;
      default:
        return;
    }

    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          IconButton(
            icon: Icon(
              _expanded ? Icons.arrow_back_ios : Icons.arrow_forward_ios,
              color: Colors.black.withOpacity(0.5),
              size: 20,
            ),
            onPressed: () async {
              setState(() {
                _expanded = !_expanded;
                if (_expanded) {
                  _controller.forward(from: 0);
                } else {
                  _controller.reverse();
                }
              });
              await MenuStateService.saveExpandedState(_expanded);
            },
          ),
          Expanded(
            child: SizedBox(
              height: 60,
              child: Row(
                children: List.generate(_iconPaths.length, (index) {
                  final animation = _itemAnimations[index];
                  final offsetX = 100.0 + index * 30;

                  return AnimatedBuilder(
                    animation: animation,
                    builder: (_, child) {
                      return Opacity(
                        opacity: animation.value,
                        child: Transform.translate(
                          offset: Offset((1 - animation.value) * -offsetX, 0),
                          child: child,
                        ),
                      );
                    },
                    child: GestureDetector(
                      onTap: () => _handleTap(context, index),
                      child: Container(
                        width: 32,
                        height: 32,
                        margin: const EdgeInsets.only(right: 12),
                        child: Image.asset(
                          _iconPaths[index],
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
