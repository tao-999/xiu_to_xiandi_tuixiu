import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:xiu_to_xiandi_tuixiu/models/disciple.dart';
import 'package:xiu_to_xiandi_tuixiu/services/zongmen_storage.dart';
import 'package:xiu_to_xiandi_tuixiu/services/player_storage.dart';
import 'package:xiu_to_xiandi_tuixiu/utils/number_format.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/sect_component.dart';
import '../../services/zongmen_diplomacy_service.dart';
import '../../services/zongmen_disciple_service.dart';
import '../common/toast_tip.dart';

class ZongmenDiplomacyDiscipleDialog extends StatefulWidget {
  final SectComponent enemySect;
  final VoidCallback? onDispatchFinished;

  const ZongmenDiplomacyDiscipleDialog({
    Key? key,
    required this.enemySect,
    this.onDispatchFinished,
  }) : super(key: key);

  @override
  State<ZongmenDiplomacyDiscipleDialog> createState() =>
      _ZongmenDiplomacyDiscipleDialogState();
}

class _ZongmenDiplomacyDiscipleDialogState
    extends State<ZongmenDiplomacyDiscipleDialog> {
  List<_DisciplePowerWrapper> _disciples = [];
  bool _loading = true;
  String? _selectedId;

  @override
  void initState() {
    super.initState();
    _loadDisciples();
  }

  Future<void> _loadDisciples() async {
    final list = await ZongmenStorage.loadDisciples();

    // 🌟打印每个弟子的房间信息
    for (final d in list) {
      debugPrint('[弟子] ${d.name} (${d.id}) assignedRoom: ${d.assignedRoom}');
    }

    final filtered = list.where((d) => d.assignedRoom == null).toList();

    final wrapped = filtered
        .map((d) => _DisciplePowerWrapper(
      disciple: d,
      power: ZongmenDiscipleService.calculatePower(d),
    ))
        .toList();

    wrapped.sort((a, b) => b.power.compareTo(a.power));

    setState(() {
      _disciples = wrapped;
      _loading = false;
    });
  }

  void _onDispatch() async {
    if (_selectedId == null) {
      ToastTip.show(context, '连一个弟子都不带？是想单挑宗主吗？🤨');
      return;
    }

    final selected = _disciples.firstWhere((d) => d.disciple.id == _selectedId);
    final maxPower = selected.power;

    if (maxPower < widget.enemySect.info.masterPower) {
      final tips = [
        "就这点战力？人家宗主一根小拇指都碾压你！🙄",
        "弟子战力太拉了，先回去修炼几年吧！⚡️",
        "你这是去讨伐，还是去送人头？🤦‍♂️",
        "战力太低，连看门的都打不过啊！😏",
        "别闹了，派这种战力是想笑死敌人吗？😂",
      ];
      final randomTip = (tips..shuffle()).first;
      ToastTip.show(context, randomTip);
      return;
    }

    // 🚀保存讨伐记录
    await _saveDispatch();

    // 🚀刷新宗门状态（立刻显示弟子）
    await widget.enemySect.refreshExpedition();

    ToastTip.show(context, '已派遣弟子出征！');

    // 🚀关闭弹窗
    Future.delayed(const Duration(milliseconds: 300), () {
      Navigator.pop(context);
      if (widget.onDispatchFinished != null) {
        widget.onDispatchFinished!();
      }
    });
  }

  Future<void> _saveDispatch() async {
    await ZongmenDiplomacyService.setSectExpedition(
      sectId: widget.enemySect.info.id,
      discipleId: _selectedId!,
    );
    // 再设置弟子的 assignedRoom
    await ZongmenStorage.setDiscipleAssignedRoom(_selectedId!, "expedition");
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // 🚀无论怎么关闭，都回调
        if (widget.onDispatchFinished != null) {
          widget.onDispatchFinished!();
        }
        return true;
      },
      child: Dialog(
        backgroundColor: const Color(0xFFFFF8E1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
        ),
        insetPadding: const EdgeInsets.all(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: _loading
              ? const SizedBox(
            height: 100,
            child: Center(child: CircularProgressIndicator()),
          )
              : Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "派遣弟子出征",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 400,
                width: 320,
                child: GridView.builder(
                  itemCount: _disciples.length,
                  gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 6,
                    crossAxisSpacing: 6,
                    childAspectRatio: 0.75,
                  ),
                  itemBuilder: (context, index) {
                    final d = _disciples[index];
                    final isSelected = _selectedId == d.disciple.id;

                    // 🌟 比较战力
                    final isStronger = d.power >= widget.enemySect.info.masterPower;
                    final powerColor = isStronger ? Colors.green : Colors.red;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            _selectedId = null;
                          } else {
                            _selectedId = d.disciple.id;
                          }
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isSelected
                                ? Colors.red
                                : Colors.black12,
                            width: 2,
                          ),
                        ),
                        child: Stack(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.all(4),
                                    child: Image.asset(
                                      d.disciple.imagePath,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(4),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        d.disciple.name,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        "${formatAnyNumber(d.power)} 战力",
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: powerColor, // 🌟这里用战力颜色
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            if (isSelected)
                              Positioned(
                                right: 4,
                                bottom: 4,
                                child: Container(
                                  decoration: const BoxDecoration(
                                    color: Colors.redAccent,
                                    shape: BoxShape.circle,
                                  ),
                                  padding: const EdgeInsets.all(2),
                                  child: const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: InkWell(
                  onTap: _onDispatch,
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

class _DisciplePowerWrapper {
  final Disciple disciple;
  final int power;

  _DisciplePowerWrapper({
    required this.disciple,
    required this.power,
  });
}
