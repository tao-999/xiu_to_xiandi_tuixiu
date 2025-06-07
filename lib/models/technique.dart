class Technique {
  final String name;         // 名称，如“玄冥真诀”
  final int grade;           // 品阶：1~9品
  int quantity;              // 拥有该功法的数量（比如副本掉落来的副本卷轴）
  final String usage;        // 用途描述，如“可供金丹期修士修炼，提升御火能力”
  final List<String> requirements; // 修炼要求，如“火灵根”、“真气十重”、“心法基础”

  Technique({
    required this.name,
    required this.grade,
    required this.quantity,
    required this.usage,
    required this.requirements,
  });

  factory Technique.fromMap(Map<String, dynamic> map) {
    return Technique(
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
