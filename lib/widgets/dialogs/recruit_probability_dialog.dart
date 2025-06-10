import 'package:flutter/material.dart';

enum RecruitPoolType { human, immortal }

class RecruitProbabilityDialog {
  static void show(BuildContext context, RecruitPoolType type) {
    final title = type == RecruitPoolType.human
        ? '人界招募资质概率'
        : '仙界招募资质概率';

    final data = type == RecruitPoolType.human
        ?  [
      {'资质范围': '1-30', '概率': '92.5%', '最高可修炼境界': '炮灰'},
      {'资质范围': '31-40', '概率': '1.25%', '最高可修炼境界': '元婴期'},
      {'资质范围': '41-50', '概率': '1.25%', '最高可修炼境界': '化神期'},
      {'资质范围': '51-60', '概率': '1.25%', '最高可修炼境界': '炼虚期'},
      {'资质范围': '61-70', '概率': '1.25%', '最高可修炼境界': '合体期'},
      {'资质范围': '71-80', '概率': '1.25%', '最高可修炼境界': '大乘期'},
      {'资质范围': '81-90', '概率': '1.25%', '最高可修炼境界': '渡劫期'},
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
          title: Text(
            title,
            style: const TextStyle(
              fontSize: 16, // ✅ 改这里就行！
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
                    0: FlexColumnWidth(1.5),
                    1: FlexColumnWidth(1.5),
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
                      ? '📜 人界立绘弟子按资质段位分批解锁（31~90）。\n'
                      '每位立绘弟子只能抽中一次，不可重复获取。\n'
                      '当前段位集齐后，下一段位自动开放。\n'
                      '非立绘弟子（资质1~30）为普通弟子。\n'
                      '⚠️ 系统设有保底机制，最多80抽必得一张立绘弟子卡牌。'
                      : '🧙‍♂️ 仙界弟子出生即高能，抽到仙帝之资，直接封神！',
                  textAlign: TextAlign.left, // ✅ 左对齐！
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 12,
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
          color: Colors.black87,
          fontFamily: 'ZcoolCangEr',
          fontSize: 12,
        ),
      ),
    );
  }
}
