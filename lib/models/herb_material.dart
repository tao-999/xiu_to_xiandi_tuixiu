class HerbMaterial {
  final String id;           // 唯一 ID，例如 'youmingcao'
  final String name;         // 名称，例如 '幽冥草'
  final String imagePath;    // 图标路径
  final String description;  // 描述
  final int quantity;        // 拥有数量

  const HerbMaterial({
    required this.id,
    required this.name,
    required this.imagePath,
    required this.description,
    required this.quantity,
  });

  HerbMaterial copyWith({
    String? id,
    String? name,
    String? imagePath,
    String? description,
    int? quantity,
  }) {
    return HerbMaterial(
      id: id ?? this.id,
      name: name ?? this.name,
      imagePath: imagePath ?? this.imagePath,
      description: description ?? this.description,
      quantity: quantity ?? this.quantity,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'imagePath': imagePath,
      'description': description,
      'quantity': quantity,
    };
  }

  factory HerbMaterial.fromMap(Map<String, dynamic> map) {
    return HerbMaterial(
      id: map['id'],
      name: map['name'],
      imagePath: map['imagePath'],
      description: map['description'],
      quantity: map['quantity'],
    );
  }
}
