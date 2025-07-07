// lib/models/favorability_item.dart

class FavorabilityItem {
  final String assetPath;
  final int favorValue;
  final String name; // 🌟 新增

  const FavorabilityItem({
    required this.assetPath,
    required this.favorValue,
    required this.name,
  });
}
