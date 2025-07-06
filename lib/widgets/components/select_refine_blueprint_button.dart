import 'package:flutter/material.dart';
import 'package:xiu_to_xiandi_tuixiu/models/refine_blueprint.dart';
import 'package:xiu_to_xiandi_tuixiu/services/refine_blueprint_service.dart';
import 'package:xiu_to_xiandi_tuixiu/services/resources_storage.dart';

class SelectRefineBlueprintButton extends StatelessWidget {
  final void Function(RefineBlueprint blueprint) onSelected;
  final RefineBlueprint? selected;
  final int maxLevelAllowed;
  final bool isDisabled;

  const SelectRefineBlueprintButton({
    super.key,
    required this.onSelected,
    required this.selected,
    required this.maxLevelAllowed,
    this.isDisabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isDisabled
          ? null
          : () async {
        final result = await showDialog<RefineBlueprint>(
          context: context,
          builder: (_) => _RefineBlueprintDialog(
            maxLevelAllowed: maxLevelAllowed,
          ),
        );
        if (result != null) {
          onSelected(result);
        }
      },
      child: Text(
        selected != null
            ? '已选：${selected!.level}阶 ${selected!.typeLabel}'
            : '选择装备',
        style: TextStyle(
          fontSize: 14,
          color: isDisabled ? Colors.grey : Colors.white,
          decoration: isDisabled ? null : TextDecoration.underline,
        ),
      ),
    );
  }
}

class _RefineBlueprintDialog extends StatefulWidget {
  final int maxLevelAllowed;

  const _RefineBlueprintDialog({
    required this.maxLevelAllowed,
  });

  @override
  State<_RefineBlueprintDialog> createState() => _RefineBlueprintDialogState();
}

class _RefineBlueprintDialogState extends State<_RefineBlueprintDialog> {
  late Future<Set<String>> _ownedKeysFuture;

  @override
  void initState() {
    super.initState();
    _ownedKeysFuture = ResourcesStorage.getBlueprintKeys();
  }

  @override
  Widget build(BuildContext context) {
    final all = RefineBlueprintService.generateAllBlueprints();
    final grouped = <int, List<RefineBlueprint>>{};
    for (var bp in all) {
      grouped.putIfAbsent(bp.level, () => []).add(bp);
    }

    return FutureBuilder<Set<String>>(
      future: _ownedKeysFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final ownedKeys = snapshot.data!;

        return Dialog(
          backgroundColor: const Color(0xFFE5D7B8), // ✅米黄色
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero), // ✅直角
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
                            final key = '${bp.type.name}-${bp.level}';
                            final isOwned = ownedKeys.contains(key);
                            final meta = RefineBlueprintService.getEffectMeta(bp);

                            // ✅逻辑：只要拥有就能点
                            final isDisabled = !isOwned;

                            return Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: GestureDetector(
                                onTap: isDisabled
                                    ? null
                                    : () {
                                  if (bp.level > widget.maxLevelAllowed) {
                                    // 阶数过高，弹窗提示
                                    showDialog(
                                      context: context,
                                      builder: (_) => Dialog(
                                        backgroundColor: const Color(0xFFE5D7B8),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.zero,
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(16),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                '啧啧~此蓝图高贵得很，需要 ${bp.level} 阶才能驾驭！\n快去提升宗门等级，解锁神器吧！',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.black,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  } else {
                                    Navigator.pop(context, bp);
                                  }
                                },
                                child: Opacity(
                                  opacity: isDisabled ? 0.3 : 1.0,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Image.asset(
                                        'assets/images/${bp.iconPath ?? 'default_icon.png'}',
                                        width: 48,
                                        height: 48,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        bp.name,
                                        style: const TextStyle(fontSize: 10, color: Colors.black),
                                      ),
                                      Text(
                                        '${meta['type']} +${meta['value']}%',
                                        style: const TextStyle(fontSize: 9, color: Colors.black),
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