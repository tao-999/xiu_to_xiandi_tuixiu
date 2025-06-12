import 'package:flutter/material.dart';
import 'package:xiu_to_xiandi_tuixiu/services/player_storage.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/back_button_overlay.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/beibao_grid_view.dart';
import 'package:xiu_to_xiandi_tuixiu/data/beibao_resource_config.dart';

class BeibaoPage extends StatefulWidget {
  const BeibaoPage({super.key});

  @override
  State<BeibaoPage> createState() => _BeibaoPageState();
}

class _BeibaoPageState extends State<BeibaoPage> {
  List<BeibaoItem> items = [];

  @override
  void initState() {
    super.initState();
    _loadResources();
  }

  Future<void> _loadResources() async {
    final player = await PlayerStorage.getPlayer();
    if (player == null) return;
    final res = player.resources;

    setState(() {
      items = beibaoResourceList.map((config) {
        final quantity = _getQuantityByName(config.name, res);
        return BeibaoItem(
          name: config.name,
          imagePath: config.imagePath,
          quantity: quantity,
          description: config.description,
        );
      }).toList();
    });
  }

  dynamic _getQuantityByName(String name, dynamic res) {
    switch (name) {
      case '下品灵石':
        return res.spiritStoneLow;
      case '中品灵石':
        return res.spiritStoneMid;
      case '上品灵石':
        return res.spiritStoneHigh;
      case '极品灵石':
        return res.spiritStoneSupreme;
      case '招募券':
        return res.recruitTicket;
      case '资质提升券':
        return res.fateRecruitCharm;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 背景图全屏显示
          Positioned.fill(
            child: Image.asset(
              'assets/images/bg_beibao.webp',
              fit: BoxFit.cover,
            ),
          ),

          // 背包内容居中显示
          Align(
            alignment: Alignment.topCenter,
            child: BeibaoGridView(items: items),
          ),

          // 返回按钮叠在最顶层
          const BackButtonOverlay(),
        ],
      ),
    );
  }
}
