import 'package:flutter/material.dart';
import 'package:xiu_to_xiandi_tuixiu/models/pill_blueprint.dart';
import 'package:xiu_to_xiandi_tuixiu/services/pill_blueprint_service.dart';

class SelectPillBlueprintButton extends StatelessWidget {
  final void Function(PillBlueprint blueprint) onSelected;
  final int currentSectLevel;

  const SelectPillBlueprintButton({
    super.key,
    required this.onSelected,
    required this.currentSectLevel,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () async {
        final result = await showDialog<PillBlueprint>(
          context: context,
          builder: (_) => _PillBlueprintDialog(currentSectLevel: currentSectLevel),
        );
        if (result != null) {
          onSelected(result);
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFE5D7B8),
        foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      child: const Text('选择丹方'),
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

                      /// ✅ 横向滚动处理
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: list.map((bp) {
                            final notOwned = !ownedKeys.contains(bp.uniqueKey);
                            final levelTooHigh = bp.level > currentSectLevel;
                            final isDisabled = levelTooHigh || notOwned;

                            String? hint;
                            if (levelTooHigh) {
                              hint = '（未解锁）';
                            } else if (notOwned) {
                              hint = '（未拥有）';
                            }

                            return Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: GestureDetector(
                                onTap: isDisabled ? null : () => Navigator.pop(context, bp),
                                child: Opacity(
                                  opacity: isDisabled ? 0.3 : 1.0,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Image.asset(
                                        'assets/images/${bp.iconPath}',
                                        width: 48,
                                        height: 48,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        bp.name + (hint ?? ''),
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: Colors.black,
                                          height: 1.2,
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
