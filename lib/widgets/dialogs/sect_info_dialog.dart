import 'package:flutter/material.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/sect_component.dart';

class SectInfoDialog extends StatelessWidget {
  final SectComponent sect;

  const SectInfoDialog({Key? key, required this.sect}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFFFFF8E1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            Text(
              '✨ ${sect.info.name}\n'
                  '✨ ${sect.info.level}级宗门\n'
                  '✨ ${sect.info.description}',
              style: const TextStyle(color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }
}
