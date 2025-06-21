import 'package:flutter/material.dart';
import 'package:xiu_to_xiandi_tuixiu/models/pill_blueprint.dart';
import 'package:xiu_to_xiandi_tuixiu/services/pill_blueprint_service.dart';

class SelectPillBlueprintButton extends StatelessWidget {
  final void Function(PillBlueprint blueprint) onSelected;
  final int currentSectLevel;
  final bool isDisabled; // ✅ 新增：是否禁用状态

  const SelectPillBlueprintButton({
    super.key,
    required this.onSelected,
    required this.currentSectLevel,
    this.isDisabled = false, // ✅ 默认允许点击
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isDisabled
          ? null
          : () async {
        final result = await showDialog<PillBlueprint>(
          context: context,
          builder: (_) => _PillBlueprintDialog(currentSectLevel: currentSectLevel),
        );
        if (result != null) {
          onSelected(result);
        }
      },
      child: Text(
        '选择丹方',
        style: TextStyle(
          fontSize: 14,
          color: isDisabled ? Colors.grey : Colors.white, // ✅ 灰色表示不可点击
          decoration: isDisabled ? null : TextDecoration.underline,
        ),
      ),
    );
  }
}

class _PillBlueprintDialog extends StatelessWidget {
  final int currentSectLevel;

  const _PillBlueprintDialog({required this.currentSectLevel});

  @override
  Widget build(BuildContext context) {
    final all = PillBlueprintService.generateAllBlueprints();
    final grouped = <int, List<PillBlueprint>>{};

    for (var bp in all) {
      grouped.putIfAbsent(bp.level, () => []).add(bp);
    }

    return FutureBuilder<Set<String>>(
      future: PillBlueprintService.getPillBlueprintKeys(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final ownedKeys = snapshot.data!;

        return Dialog(
          backgroundColor: const Color(0xFFE5D7B8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          insetPadding: const EdgeInsets.all(24),
          child: SizedBox(
            width: 360,
            height: 500,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: ListView(
                children: grouped.entries.map((entry) {
                  final level = entry.key;
                  final list = entry.value;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$level阶',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black,
                          fontFamily: 'ZcoolCangEr',
                        ),
                      ),
                      const SizedBox(height: 8),

                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: list.map((bp) {
                            final owned = ownedKeys.contains(bp.uniqueKey);
                            final levelTooHigh = bp.level > currentSectLevel;
                            final isDisabled = levelTooHigh || !owned;

                            return Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: GestureDetector(
                                onTap: isDisabled ? null : () => Navigator.pop(context, bp),
                                child: Opacity(
                                  opacity: isDisabled ? 0.3 : 1.0,
                                  child: Stack(
                                    alignment: Alignment.topRight,
                                    children: [
                                      Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Image.asset(
                                            'assets/images/${bp.iconPath}',
                                            width: 48,
                                            height: 48,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            bp.name,
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                              fontSize: 10,
                                              color: Colors.black,
                                              height: 1.2,
                                            ),
                                          ),
                                          Text(
                                            '${bp.typeLabel} +${bp.effectValue}',
                                            style: const TextStyle(
                                              fontSize: 9,
                                              color: Colors.black,
                                              height: 1.2,
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (levelTooHigh && owned)
                                        Positioned(
                                          right: 0,
                                          top: 0,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                            decoration: BoxDecoration(
                                              color: Colors.orange,
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: const Text(
                                              '已拥有',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 8,
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),

                      const SizedBox(height: 20),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        );
      },
    );
  }
}
