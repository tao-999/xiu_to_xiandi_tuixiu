import 'package:flutter/material.dart';
import 'package:xiu_to_xiandi_tuixiu/models/refine_blueprint.dart';
import 'package:xiu_to_xiandi_tuixiu/data/all_refine_blueprints.dart';

class BlueprintDropdownSelector extends StatelessWidget {
  final List<RefineBlueprint> blueprintList;
  final RefineBlueprint? selected;
  final ValueChanged<RefineBlueprint> onSelected;
  final bool isDisabled;
  final int maxLevelAllowed; // ✅ 新增：最高允许炼制阶数

  const BlueprintDropdownSelector({
    super.key,
    required this.blueprintList,
    required this.selected,
    required this.onSelected,
    required this.maxLevelAllowed,
    this.isDisabled = false,
  });

  @override
  Widget build(BuildContext context) {
    if (blueprintList.isEmpty) {
      return const Text(
        '暂无可用图纸，请先前往图纸商店获取。',
        style: TextStyle(color: Colors.white60),
      );
    }

    final Map<BlueprintType, List<RefineBlueprint>> grouped = {};
    for (final b in blueprintList) {
      grouped.putIfAbsent(b.type, () => []).add(b);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: BlueprintType.values.map((type) {
            final list = grouped[type] ?? [];
            list.sort((a, b) => a.level.compareTo(b.level));
            final prefix = _getPrefix(type);

            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Label
                    Row(
                      children: [
                        Image.asset(
                          'assets/images/${list.first.iconPath ?? 'default_icon.png'}',
                          width: 16,
                          height: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          prefix,
                          style: TextStyle(
                            color: isDisabled ? Colors.grey : Colors.white,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),

                    // 下拉选择器
                    DropdownButtonHideUnderline(
                      child: DropdownButton<RefineBlueprint>(
                        value: selected?.type == type ? selected : null,
                        isExpanded: true,
                        dropdownColor: const Color(0xFF2E1C1C),
                        iconEnabledColor: isDisabled ? Colors.grey : Colors.white,
                        style: TextStyle(
                          color: isDisabled ? Colors.grey : Colors.white,
                          fontSize: 13,
                        ),
                        onChanged: isDisabled
                            ? null
                            : (val) {
                          if (val != null && val.level <= maxLevelAllowed) {
                            onSelected(val);
                          }
                        },
                        items: list.map((b) {
                          final isTooHigh = b.level > maxLevelAllowed;
                          return DropdownMenuItem(
                            value: b,
                            enabled: !isTooHigh,
                            child: Text(
                              '${b.level}阶',
                              style: TextStyle(
                                color: isTooHigh ? Colors.grey : Colors.white,
                              ),
                            ),
                          );
                        }).toList(),
                        selectedItemBuilder: (context) {
                          return list.map((b) {
                            final isTooHigh = b.level > maxLevelAllowed;
                            return Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                '${b.level}阶',
                                style: TextStyle(
                                  color: isTooHigh ? Colors.grey : Colors.white,
                                ),
                              ),
                            );
                          }).toList();
                        },
                        hint: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '请选择',
                            style: TextStyle(
                              color: isDisabled ? Colors.grey : Colors.white38,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // 下划线
                    Divider(
                      color: isDisabled ? Colors.grey : Colors.deepOrange,
                      height: 8,
                      thickness: 1,
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        if (isDisabled)
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Text(
              '请先派遣弟子驻守炼器房后再选择图纸',
              style: TextStyle(color: Colors.redAccent, fontSize: 12),
            ),
          ),
      ],
    );
  }

  String _getPrefix(BlueprintType type) {
    final info = blueprintInfoMap[type];
    return info != null && info.isNotEmpty ? info.first['prefix'] ?? type.name : type.name;
  }
}
