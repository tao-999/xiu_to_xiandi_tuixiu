import 'package:flutter/material.dart';
import 'package:xiu_to_xiandi_tuixiu/services/resources_storage.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/back_button_overlay.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/beibao_grid_view.dart';
import 'package:xiu_to_xiandi_tuixiu/data/beibao_resource_config.dart';

import '../services/refine_blueprint_service.dart';

class BeibaoPage extends StatefulWidget {
  const BeibaoPage({super.key});

  @override
  State<BeibaoPage> createState() => _BeibaoPageState();
}

class _BeibaoPageState extends State<BeibaoPage> {
  List<BeibaoItem> items = [];

  @override
  void initState() {
    super.initState();
    _loadResources();
  }

  Future<void> _loadResources() async {
    List<BeibaoItem> newItems = [];

    // 🔹 先加载通用资源（灵石、招募券等）
    for (final config in beibaoResourceList) {
      final quantity = await ResourcesStorage.getValue(config.field);
      newItems.add(BeibaoItem(
        name: config.name,
        imagePath: config.imagePath,
        quantity: quantity,
        description: config.description,
      ));
    }

    setState(() {
      items = newItems;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/bg_beibao.webp',
              fit: BoxFit.cover,
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: BeibaoGridView(items: items),
          ),
          const BackButtonOverlay(),
        ],
      ),
    );
  }
}
