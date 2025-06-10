import 'package:flutter/material.dart';
import 'package:xiu_to_xiandi_tuixiu/models/disciple.dart';
import 'package:xiu_to_xiandi_tuixiu/pages/page_disciple_detail.dart';
import 'package:xiu_to_xiandi_tuixiu/utils/aptitude_color_util.dart';

class ZongmenDiscipleCard extends StatelessWidget {
  final Disciple disciple;

  const ZongmenDiscipleCard({super.key, required this.disciple});

  @override
  Widget build(BuildContext context) {
    final d = disciple;
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DiscipleDetailPage(disciple: d),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: AptitudeColorUtil.getBackgroundColor(d.aptitude).withOpacity(0.75),
          borderRadius: BorderRadius.circular(12),
        ),
        clipBehavior: Clip.hardEdge,
        child: Stack(
          children: [
            Positioned.fill(
              child: d.imagePath.isNotEmpty
                  ? Image.asset(
                d.imagePath,
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
              )
                  : Container(color: Colors.black26),
            ),
            Positioned(
              top: 6,
              right: 6,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AptitudeColorUtil.getBackgroundColor(d.aptitude),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1),
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
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      d.name,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontFamily: 'ZcoolCangEr',
                      ),
                    ),
                    Text(
                      d.realm,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontFamily: 'ZcoolCangEr',
                      ),
                    ),
                    Text(
                      "${d.age}岁",
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 10,
                        fontFamily: 'ZcoolCangEr',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
