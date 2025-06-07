class Pill {
  final String name;       // 丹药名称，如“凝气丹”
  final int grade;         // 品阶（1~9）
  int quantity;            // 当前拥有数量
  final String usage;      // 用途描述，如“用于筑基期修士提升灵力”
  final List<String> requirements; // 炼制要求：原料或条件

  Pill({
    required this.name,
    required this.grade,
    required this.quantity,
    required this.usage,
    required this.requirements,
  });

  factory Pill.fromMap(Map<String, dynamic> map) {
    return Pill(
      name: map['name'],
      grade: map['grade'],
      quantity: map['quantity'],
      usage: map['usage'],
      requirements: List<String>.from(map['requirements']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'grade': grade,
      'quantity': quantity,
      'usage': usage,
      'requirements': requirements,
    };
  }
}
