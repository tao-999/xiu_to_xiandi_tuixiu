import 'package:flutter/material.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/sect_component.dart';
import '../../utils/number_format.dart';
import 'zongmen_diplomacy_disciple_dialog.dart';

class SectInfoDialog extends StatelessWidget {
  final SectComponent sect;
  final VoidCallback? onClose;

  const SectInfoDialog({
    Key? key,
    required this.sect,
    this.onClose,
  }) : super(key: key);

  Text _infoText(String content, {double fontSize = 12}) {
    return Text(
      content,
      style: TextStyle(
        fontSize: fontSize,
        color: Colors.black87,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 👇 用一个标志位记录是否点击了讨伐
    bool dispatched = false;

    return WillPopScope(
      onWillPop: () async {
        // 🚀 如果没点击讨伐，关闭时执行 onClose
        if (!dispatched && onClose != null) {
          onClose!();
        }
        return true;
      },
      child: Dialog(
        backgroundColor: const Color(0xFFFFF8E1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 12),
              _infoText(
                '🌟 ${sect.info.name}（${sect.info.level}级）',
                fontSize: 15,
              ),
              const SizedBox(height: 12),
              _infoText(sect.info.description),
              const SizedBox(height: 12),
              _infoText('宗主：${sect.info.masterName}'),
              const SizedBox(height: 8),
              _infoText('宗主战力：${formatAnyNumber(sect.info.masterPower)}'),
              const SizedBox(height: 8),
              _infoText('弟子人数：${sect.info.discipleCount}'),
              const SizedBox(height: 8),
              _infoText('弟子战力：${formatAnyNumber(sect.info.disciplePower)}'),
              const SizedBox(height: 8),
              _infoText(
                '宗门资源：${formatAnyNumber(sect.info.spiritStoneLow)} 下品灵石',
              ),
              const SizedBox(height: 16),
              // ✅ 讨伐按钮居中
              Center(
                child: InkWell(
                  onTap: () {
                    dispatched = true;

                    Navigator.pop(context);

                    showDialog(
                      context: context,
                      builder: (_) => ZongmenDiplomacyDiscipleDialog(
                        enemySect: sect,
                        onDispatchFinished: () {
                          if (onClose != null) {
                            onClose!();
                          }
                        },
                      ),
                    );
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.flag, color: Colors.redAccent),
                      const SizedBox(width: 6),
                      const Text(
                        "讨伐",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
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
    );
  }
}
