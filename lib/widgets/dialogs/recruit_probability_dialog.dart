import 'package:flutter/material.dart';

enum RecruitPoolType { human, immortal }

class RecruitProbabilityDialog {
  static void show(BuildContext context, RecruitPoolType type) {
    final title = type == RecruitPoolType.human
        ? '人界招募资质概率'
        : '仙界招募资质概率';

    final data = type == RecruitPoolType.human
        ? [
      {'资质范围': '1-10', '概率': '14.9%', '最高可修炼境界': '练气期'},
      {'资质范围': '11-20', '概率': '20%', '最高可修炼境界': '筑基期'},
      {'资质范围': '21-30', '概率': '25%', '最高可修炼境界': '金丹期'},
      {'资质范围': '31-40', '概率': '20%', '最高可修炼境界': '元婴期'},
      {'资质范围': '41-50', '概率': '10%', '最高可修炼境界': '化神期'},
      {'资质范围': '51-60', '概率': '6%', '最高可修炼境界': '炼虚期'},
      {'资质范围': '61-70', '概率': '3%', '最高可修炼境界': '合体期'},
      {'资质范围': '71-80', '概率': '1%', '最高可修炼境界': '大乘期'},
      {'资质范围': '81-90', '概率': '0.1%', '最高可修炼境界': '渡劫期'},
    ]
        : [
      {'资质范围': '101-110', '概率': '35.1%', '最高可修炼境界': '地仙'},
      {'资质范围': '111-120', '概率': '30.1%', '最高可修炼境界': '天仙'},
      {'资质范围': '121-130', '概率': '25.1%', '最高可修炼境界': '真仙'},
      {'资质范围': '131-140', '概率': '16.5%', '最高可修炼境界': '玄仙'},
      {'资质范围': '141-150', '概率': '15.0%', '最高可修炼境界': '灵仙'},
      {'资质范围': '151-160', '概率': '10.0%', '最高可修炼境界': '虚仙'},
      {'资质范围': '161-170', '概率': '5.0%', '最高可修炼境界': '圣仙'},
      {'资质范围': '171-180', '概率': '2.5%', '最高可修炼境界': '混元仙'},
      {'资质范围': '181-190', '概率': '0.5%', '最高可修炼境界': '太乙仙'},
      {'资质范围': '191-200', '概率': '0.05%', '最高可修炼境界': '仙帝'},
    ];

    final thirdColumnTitle = '最高可修炼境界';

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFFF9F5E3),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(title, style: const TextStyle(color: Colors.black87)),
          content: SingleChildScrollView(
            child: Column(
              children: [
                Table(
                  border: TableBorder.all(color: Colors.black54),
                  columnWidths: const {
                    0: FlexColumnWidth(2),
                    1: FlexColumnWidth(1),
                    2: FlexColumnWidth(2),
                  },
                  children: [
                    TableRow(
                      decoration: const BoxDecoration(color: Colors.black12),
                      children: [
                        _cell('资质范围', isHeader: true),
                        _cell('概率', isHeader: true),
                        _cell(thirdColumnTitle, isHeader: true),
                      ],
                    ),
                    ...data.map((row) => TableRow(
                      children: [
                        _cell(row['资质范围']!),
                        _cell(row['概率']!),
                        _cell(row[thirdColumnTitle]!),
                      ],
                    )),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(color: Colors.black38),
                const SizedBox(height: 12),
                Text(
                  type == RecruitPoolType.human
                      ? '💡 每100次人界招募，必出一名资质81+弟子！'
                      : '🧙‍♂️ 仙界弟子出生即高能，抽到仙帝之资，直接封神！',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                    fontSize: 14,
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
        style: TextStyle(
          fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
          color: Colors.black87,
          fontFamily: 'ZcoolCangEr',
          fontSize: 14,
        ),
      ),
    );
  }
}
