import 'package:flutter/material.dart';

class RecruitProbabilityDialog {
  static void show(BuildContext context) {
    const title = '招募概率';

    final data = <Map<String, String>>[
      {'资质范围': '1-30', '概率': '98.75%'},
      {'资质范围': '31-40', '概率': '1.25%'},
      {'资质范围': '41-50', '概率': '1.25%'},
      {'资质范围': '51-60', '概率': '1.25%'},
      {'资质范围': '61-70', '概率': '1.25%'},
      {'资质范围': '71-80', '概率': '1.25%'},
      {'资质范围': '81-90', '概率': '1.25%'},
      {'资质范围': '91-100', '概率': '1.25%'},
    ];

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFFF9F5E3),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          title: const Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.black87,
              fontFamily: 'ZcoolCangEr',
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              children: [
                Table(
                  border: TableBorder.all(color: Colors.black54),
                  columnWidths: const {
                    0: FlexColumnWidth(2),
                    1: FlexColumnWidth(1.5),
                  },
                  children: [
                    const TableRow(
                      decoration: BoxDecoration(color: Colors.black12),
                      children: [
                        Padding(
                          padding: EdgeInsets.all(6),
                          child: Text(
                            '资质范围',
                            style: TextStyle(
                              color: Colors.black87,
                              fontSize: 11,
                              fontFamily: 'ZcoolCangEr',
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.all(6),
                          child: Text(
                            '概率',
                            style: TextStyle(
                              color: Colors.black87,
                              fontSize: 11,
                              fontFamily: 'ZcoolCangEr',
                            ),
                          ),
                        ),
                      ],
                    ),
                    ...data.map((row) => TableRow(
                      children: [
                        _cell(row['资质范围']!),
                        _cell(row['概率']!),
                      ],
                    )),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(color: Colors.black38),
                const SizedBox(height: 12),
                const Text(
                  '''📜 卡牌按资质段位分批解锁。
每个卡牌只能抽中一次，不可重复获取。
当前段位集齐后，下一段位自动开放。
资质1~30为炮灰弟子。
⚠️ 系统设有保底机制，最多80抽必得一张立绘弟子卡牌。''',
                  textAlign: TextAlign.left,
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 11,
                    fontFamily: 'ZcoolCangEr',
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static Widget _cell(String text, {bool isHeader = false}) {
    return Padding(
      padding: const EdgeInsets.all(6),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.black87,
          fontFamily: 'ZcoolCangEr',
          fontSize: 11,
        ),
      ),
    );
  }
}
