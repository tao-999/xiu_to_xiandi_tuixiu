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
    const dialogWidth = 420.0;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        Navigator.of(context).pop(); // 👈 点击遮罩关闭
      },
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Center(
          child: GestureDetector(
            onTap: () {}, // ❗ 阻止点击透传到遮罩
            child: Container(
              width: dialogWidth,
              child: AspectRatio(
                aspectRatio: 420 / 316, // ✅ 背景图真实比例
                child: Stack(
                  children: [
                    // ✅ 背景图完整显示
                    Image.asset(
                      'assets/images/lunhuilu.png',
                      fit: BoxFit.fill,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                    // ✅ 内容居中显示
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 38, vertical: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center, // ✅ 红字垂直居中
                          children: [
                            ..._buildPoemColumns().map(
                                  (column) => Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: column.map((char) {
                                    return Text(
                                      char,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontFamily: 'ZcoolCangEr',
                                        color: Colors.black87,
                                        height: 1.1,
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: SizedBox(
                                width: 50, // ✅ 给 Stack 设置宽度，避免被裁切
                                height: 100, // 和红字一样高
                                child: Stack(
                                  alignment: Alignment.centerLeft,
                                  children: [
                                    // ✅ 红字“饮下此汤”
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: TextButton(
                                        onPressed: onDrinkConfirmed,
                                        style: TextButton.styleFrom(
                                          padding: EdgeInsets.zero,
                                          minimumSize: const Size(24, 100),
                                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        child: const Text(
                                          '饮\n下\n此\n汤',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontFamily: 'ZcoolCangEr',
                                            color: Colors.redAccent,
                                          ),
                                        ),
                                      ),
                                    ),

                                    // ✅ 新增“（重置角色）”
                                    Positioned(
                                      left: 32, // ✅ 刚好贴在红字右边
                                      top: 0,
                                      bottom: 0,
                                      child: Center(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const RotatedBox(
                                              quarterTurns: 1,
                                              child: Text(
                                                '（',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontFamily: 'ZcoolCangEr',
                                                  color: Colors.black54,
                                                  height: 1.0,
                                                ),
                                              ),
                                            ),
                                            ...'重置角色'.split('').map((char) => Text(
                                              char,
                                              style: const TextStyle(
                                                fontSize: 10,
                                                fontFamily: 'ZcoolCangEr',
                                                color: Colors.black54,
                                                height: 1.1,
                                              ),
                                            )),
                                            const RotatedBox(
                                              quarterTurns: 1,
                                              child: Text(
                                                '）',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontFamily: 'ZcoolCangEr',
                                                  color: Colors.black54,
                                                  height: 1.0,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
