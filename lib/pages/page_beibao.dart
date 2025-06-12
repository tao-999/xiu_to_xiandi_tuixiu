import 'package:flutter/material.dart';
import 'package:xiu_to_xiandi_tuixiu/services/player_storage.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/back_button_overlay.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/beibao_tooltip_overlay.dart';

class Item {
  final String name;
  final String imagePath;
  final dynamic quantity;

  const Item(this.name, this.imagePath, this.quantity);
}

class BeibaoPage extends StatefulWidget {
  const BeibaoPage({super.key});

  @override
  State<BeibaoPage> createState() => _BeibaoPageState();
}

class _BeibaoPageState extends State<BeibaoPage> {
  List<Item> items = [];
  OverlayEntry? _tooltipEntry;

  final Map<String, String> descriptions = {
    '下品灵石': '修炼入门的基础灵石，常用于突破练气期。',
    '中品灵石': '较为常见的灵石，修炼进阶期的重要资源。',
    '上品灵石': '品质极佳，可用于筑基、金丹等高阶修炼。',
    '极品灵石': '罕见至极，蕴含浓郁灵气，可供元婴及以上修士使用。',
    '招募券': '可用于招募弟子，增加宗门实力。',
    '资质提升券': '触发特殊剧情，结识独特弟子。',
  };

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
      items = [
        Item('下品灵石', 'assets/images/spirit_stone_low.png', res.spiritStoneLow),
        Item('中品灵石', 'assets/images/spirit_stone_mid.png', res.spiritStoneMid),
        Item('上品灵石', 'assets/images/spirit_stone_high.png', res.spiritStoneHigh),
        Item('极品灵石', 'assets/images/spirit_stone_supreme.png', res.spiritStoneSupreme),
        Item('招募券', 'assets/images/recruit_ticket.png', res.recruitTicket),
        Item('资质提升券', 'assets/images/fate_recruit_charm.png', res.fateRecruitCharm),
      ];
    });
  }

  void _showItemTooltip(BuildContext context, Offset globalPosition, Item item) {
    _tooltipEntry?.remove();

    final desc = descriptions[item.name] ?? '暂无描述';
    _tooltipEntry = BeibaoTooltipOverlay.show(
      context: context,
      position: globalPosition,
      name: item.name,
      quantity: item.quantity,
      description: desc,
      onDismiss: () {
        _tooltipEntry?.remove();
        _tooltipEntry = null;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 背景图
          Positioned.fill(
            child: Image.asset(
              'assets/images/bg_beibao.webp',
              fit: BoxFit.cover,
            ),
          ),
          // 背包内容
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 36),
            child: GridView.builder(
              itemCount: items.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 0.85,
              ),
              itemBuilder: (context, index) {
                final item = items[index];
                return GestureDetector(
                  onTapDown: (details) {
                    _showItemTooltip(context, details.globalPosition, item);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white24),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          item.imagePath,
                          width: 24,
                          height: 24,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(height: 2),
                        Flexible(
                          child: Text(
                            item.name,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 10, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const BackButtonOverlay(),
        ],
      ),
    );
  }
}
