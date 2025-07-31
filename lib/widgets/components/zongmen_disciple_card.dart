import 'package:flutter/material.dart';
import 'package:xiu_to_xiandi_tuixiu/models/disciple.dart';
import 'package:xiu_to_xiandi_tuixiu/utils/aptitude_color_util.dart';
import 'package:xiu_to_xiandi_tuixiu/utils/number_format.dart';
import '../../services/zongmen_disciple_service.dart';

class ZongmenDiscipleCard extends StatelessWidget {
  final Disciple disciple;

  const ZongmenDiscipleCard({super.key, required this.disciple});

  @override
  Widget build(BuildContext context) {
    final d = disciple;
    final int power = ZongmenDiscipleService.calculatePower(d);
    final realmName = ZongmenDiscipleService.getRealmNameByLevel(d.realmLevel);

    return Container(
      decoration: AptitudeColorUtil.getBackgroundDecoration(d.aptitude),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              d.imagePath,
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            ),
          ),
          Positioned(
            top: 6,
            right: 6,
            child: Container(
              width: 28,
              height: 28,
              decoration: AptitudeColorUtil.getBackgroundDecoration(d.aptitude).copyWith(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black, width: 1),
              ),
              alignment: Alignment.center,
              child: Text(
                '${d.aptitude}',
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 12,
                  fontFamily: 'ZcoolCangEr',
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          d.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontFamily: 'ZcoolCangEr',
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.favorite, color: Colors.pinkAccent, size: 12),
                      const SizedBox(width: 2),
                      Text(
                        "${d.favorability}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontFamily: 'ZcoolCangEr',
                        ),
                      ),
                    ],
                  ),
                  Text(
                    realmName,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontFamily: 'ZcoolCangEr',
                    ),
                  ),
                  Text(
                    "${d.age}岁",
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 10,
                      fontFamily: 'ZcoolCangEr',
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    formatAnyNumber(power),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontFamily: 'ZcoolCangEr',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
