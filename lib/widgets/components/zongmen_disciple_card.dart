import 'package:flutter/material.dart';
import 'package:xiu_to_xiandi_tuixiu/models/disciple.dart';
import 'package:xiu_to_xiandi_tuixiu/pages/page_disciple_detail.dart';
import 'package:xiu_to_xiandi_tuixiu/utils/aptitude_color_util.dart';
import 'package:xiu_to_xiandi_tuixiu/services/portrait_selection_service.dart';

class ZongmenDiscipleCard extends StatefulWidget {
  final Disciple disciple;

  const ZongmenDiscipleCard({super.key, required this.disciple});

  @override
  State<ZongmenDiscipleCard> createState() => _ZongmenDiscipleCardState();
}

class _ZongmenDiscipleCardState extends State<ZongmenDiscipleCard> {
  late Future<String> _imagePathFuture;

  @override
  void initState() {
    super.initState();
    _imagePathFuture = _loadSelectedImagePath();
  }

  Future<String> _loadSelectedImagePath() async {
    final index = await PortraitSelectionService.getSelection(widget.disciple.id);

    if (index == 0) {
      return widget.disciple.imagePath;
    } else {
      final ext = widget.disciple.imagePath.split('.').last;
      final withoutExt = widget.disciple.imagePath.substring(
        0,
        widget.disciple.imagePath.length - ext.length - 1,
      );
      return "${withoutExt}_$index.$ext";
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.disciple;
    return FutureBuilder<String>(
      future: _imagePathFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Container(
            height: 120,
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
              ),
            ),
          );
        }

        final imagePath = snapshot.data!;

        return InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DiscipleDetailPage(disciple: d),
              ),
            ).then((_) {
              // 返回后刷新立绘
              setState(() {
                _imagePathFuture = _loadSelectedImagePath();
              });
            });
          },
          child: Container(
            decoration: AptitudeColorUtil.getBackgroundDecoration(d.aptitude),
            clipBehavior: Clip.hardEdge,
            child: Stack(
              children: [
                Positioned.fill(
                  child: Image.asset(
                    imagePath,
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
      },
    );
  }
}
