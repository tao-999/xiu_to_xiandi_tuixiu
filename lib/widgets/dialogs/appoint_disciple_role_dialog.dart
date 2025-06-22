import 'package:flutter/material.dart';

class AppointDiscipleRoleDialog extends StatelessWidget {
  final String discipleName;
  final String? currentRole;
  final void Function(String? selectedRole) onAppointed;

  const AppointDiscipleRoleDialog({
    super.key,
    required this.discipleName,
    required this.currentRole,
    required this.onAppointed,
  });

  @override
  Widget build(BuildContext context) {
    final roles = ['长老', '执事', '弟子'];

    Color? _getColor(String role) {
      switch (role) {
        case '长老':
          return Colors.redAccent;
        case '执事':
          return Colors.green;
        default:
          return Colors.black87;
      }
    }

    return AlertDialog(
      backgroundColor: const Color(0xFFFFF8DC), // ✅ 米黄色背景
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.zero, // ✅ 直角边框
      ),
      title: Text(
        '任命职位：$discipleName',
        style: const TextStyle(
          fontSize: 15,
          color: Colors.black87,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: roles.map((role) {
          final isSelected = (role == currentRole);
          return ListTile(
            title: Text(
              role,
              style: TextStyle(
                color: _getColor(role),
                fontSize: 13,
              ),
            ),
            trailing: isSelected
                ? const Icon(Icons.check, color: Colors.green)
                : null,
            onTap: () {
              Navigator.of(context).pop();
              onAppointed(role);
            },
          );
        }).toList(),
      ),
    );
  }
}
