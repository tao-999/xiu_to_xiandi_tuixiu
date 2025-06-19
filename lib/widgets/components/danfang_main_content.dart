import 'package:flutter/material.dart';
import 'package:xiu_to_xiandi_tuixiu/models/pill_blueprint.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/alchemy_material_selector.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/danfang_header.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/select_pill_blueprint.dart';
import '../effects/five_star_danfang_array.dart';

class DanfangMainContent extends StatefulWidget {
  final int level;
  final GlobalKey<FiveStarAlchemyArrayState> arrayKey;

  const DanfangMainContent({
    super.key,
    required this.level,
    required this.arrayKey,
  });

  @override
  State<DanfangMainContent> createState() => _DanfangMainContentState();
}

class _DanfangMainContentState extends State<DanfangMainContent> {
  PillBlueprint? _selectedBlueprint;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40),
          DanfangHeader(level: widget.level),
          const SizedBox(height: 24),

          // ✅ 选择丹方按钮
          SelectPillBlueprintButton(
            currentSectLevel: widget.level,
            onSelected: (blueprint) {
              setState(() {
                _selectedBlueprint = blueprint;
              });
            },
          ),

          const SizedBox(height: 24),

          // ✅ 居中的五角星 + 中央丹方图标
          Center(
            child: SizedBox(
              width: 300, // 可根据大小微调
              height: 300,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  FiveStarAlchemyArray(
                    key: widget.arrayKey,
                    radius: 150,
                    bigDanluSize: 200,
                    smallDanluSize: 100,
                  ),
                  if (_selectedBlueprint != null)
                    Image.asset(
                      'assets/images/${_selectedBlueprint!.iconPath}',
                      width: 64,
                      height: 64,
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          AlchemyMaterialSelector(selectedBlueprint: _selectedBlueprint),

          const SizedBox(height: 64),
        ],
      ),
    );
  }
}
