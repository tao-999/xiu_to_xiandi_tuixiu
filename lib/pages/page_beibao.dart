import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xiu_to_xiandi_tuixiu/services/player_storage.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/back_button_overlay.dart';

class Item {
  final String name;
  final String icon;
  final int quantity;

  const Item(this.name, this.icon, this.quantity);
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
    '人界招募券': '可用于招募人界弟子，增加宗门实力。',
    '仙界召唤令': '召唤仙界弟子所需，几率获得强大资质弟子。',
    '奇遇招募符': '触发特殊剧情，结识独特弟子。',
    '宗门贡献': '建设宗门、升级建筑的必备资源。',
    '声望值': '在修真界的名气，可解锁新剧情与隐藏任务。',
    '灵气': '挂机修炼积累所得，是突破境界的重要基础。',
    '悟性': '影响突破成功率，越高越易参悟功法。',
    '因果点': '记录修士过往因果，关键节点用于转世、剧情触发。',
    '愿力': '信仰之力，可用于保命或触发神秘召唤。',
    '真元': '驱动法术的能量来源，战斗中快速消耗。',
    '神识': '操控飞剑、控制敌人、感知周围的核心感知力。',
    '战意': '战斗越多越旺盛，可激发爆发技。',
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
        Item('下品灵石', '💰', res.spiritStoneLow),
        Item('中品灵石', '💰', res.spiritStoneMid),
        Item('上品灵石', '💰', res.spiritStoneHigh),
        Item('极品灵石', '💰', res.spiritStoneSupreme),
        Item('人界招募券', '📜', res.humanRecruitTicket),
        Item('仙界召唤令', '📜', res.immortalSummonOrder),
        Item('奇遇招募符', '📜', res.fateRecruitCharm),
        Item('宗门贡献', '🏯', res.contribution),
        Item('声望值', '🏅', res.reputation),
        Item('灵气', '🌬️', res.aura),
        Item('悟性', '🧠', res.insight),
        Item('因果点', '⚖️', res.karma),
        Item('愿力', '🙏', res.wishPower),
        Item('真元', '🔥', res.refinedQi),
        Item('神识', '🌀', res.mindEnergy),
        Item('战意', '⚔️', res.battleWill),
      ];
    });
  }

  void _showItemTooltip(BuildContext context, Offset globalPosition, Item item) {
    _tooltipEntry?.remove();

    final overlay = Overlay.of(context);
    final RenderBox overlayBox = overlay.context.findRenderObject() as RenderBox;
    final Size screenSize = overlayBox.size;

    double left = globalPosition.dx + 10;
    double top = globalPosition.dy - 40;

    const double tooltipWidth = 200;
    const double tooltipHeight = 80;

    if (left + tooltipWidth > screenSize.width) {
      left = screenSize.width - tooltipWidth - 10;
    }
    if (top + tooltipHeight > screenSize.height) {
      top = screenSize.height - tooltipHeight - 10;
    }
    if (top < 10) {
      top = 10;
    }

    final entry = OverlayEntry(
      builder: (ctx) => GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          _tooltipEntry?.remove();
          _tooltipEntry = null;
        },
        child: Stack(
          children: [
            Positioned(
              left: left,
              top: top,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white24),
                  ),
                  constraints: const BoxConstraints(maxWidth: 200),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '数量：${item.quantity}',
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        descriptions[item.name] ?? '暂无描述',
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    _tooltipEntry = entry;
    overlay.insert(entry);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B1B1B),
      body: Stack(
        children: [
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
                      color: Colors.grey.shade900,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white24),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(item.icon, style: const TextStyle(fontSize: 24)),
                        const SizedBox(height: 2),
                        Flexible(
                          child: Text(item.name,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
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
