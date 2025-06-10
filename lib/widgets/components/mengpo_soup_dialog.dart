import 'package:flutter/material.dart';

class MengpoSoupDialog extends StatelessWidget {
  final VoidCallback onDrinkConfirmed;

  const MengpoSoupDialog({super.key, required this.onDrinkConfirmed});

  List<List<String>> _buildPoemColumns() {
    const raw = '''
生死如潮起梦醒在桥西
千载恩仇尽一碗忘川息
花谢不闻春剑断不留名
若问轮回事黄泉只应听
万劫皆可斩唯情最难平
此汤三分苦七分不甘心
莫怨今生错且将前路清
他年若得道愿忘此曾经
''';
    final lines = raw.trim().split('\n');
    return List.generate(lines.length, (i) => lines[i].split(''));
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Image.asset('assets/images/lunhuilu.png'),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ..._buildPoemColumns().map((column) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: column
                        .map((char) => Text(
                      char,
                      style: const TextStyle(
                        fontSize: 11,
                        fontFamily: 'ZcoolCangEr',
                        color: Colors.black87,
                        height: 1.1,
                      ),
                    ))
                        .toList(),
                  ),
                )),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton(
                        onPressed: onDrinkConfirmed,
                        child: const Text(
                          '饮\n下\n此\n汤',
                          style: TextStyle(
                            fontSize: 12,
                            fontFamily: 'ZcoolCangEr',
                            color: Colors.redAccent,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
