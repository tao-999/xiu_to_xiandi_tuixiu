import 'package:flutter/material.dart';
import '../../services/chiyangu_storage.dart';
import '../../utils/number_format.dart';
import '../../widgets/components/chiyangu_game.dart';

class DepthAndRewardInfo extends StatelessWidget {
  const DepthAndRewardInfo({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: ChiyanguStorage.rewardVersion, // ✅ 奖励刷新
      builder: (context, _, __) {
        return ValueListenableBuilder<int>(
          valueListenable: ChiyanguGame.depthNotifier, // ✅ 深度刷新
          builder: (context, depth, __) {
            return FutureBuilder<Map<String, int>>(
              future: ChiyanguStorage.getAllRewards(),
              builder: (context, snapshot) {
                final rewards = snapshot.data ?? {};
                final supreme = rewards['spiritStoneSupreme'] ?? 0;
                final high = rewards['spiritStoneHigh'] ?? 0;
                final mid = rewards['spiritStoneMid'] ?? 0;
                final low = rewards['spiritStoneLow'] ?? 0;

                return Container(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '深度：$depth 米',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          shadows: [
                            Shadow(
                              blurRadius: 4,
                              color: Colors.black,
                              offset: Offset(1, 1),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '💛 下品灵石：${formatAnyNumber(low)}',
                        style: const TextStyle(color: Color(0xFFFFFF66), fontSize: 10),
                      ),
                      Text(
                        '💚 中品灵石：${formatAnyNumber(mid)}',
                        style: const TextStyle(color: Color(0xFF66FF66), fontSize: 10),
                      ),
                      Text(
                        '💙 上品灵石：${formatAnyNumber(high)}',
                        style: const TextStyle(color: Color(0xFF66CCFF), fontSize: 10),
                      ),
                      Text(
                        '❤️ 极品灵石：${formatAnyNumber(supreme)}',
                        style: const TextStyle(color: Color(0xFFFF4444), fontSize: 10),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
