import 'package:flutter/material.dart';
import 'package:xiu_to_xiandi_tuixiu/models/disciple.dart';
import 'package:xiu_to_xiandi_tuixiu/services/zongmen_storage.dart';
import 'package:xiu_to_xiandi_tuixiu/utils/sect_role_limits.dart';

import '../../models/zongmen.dart';
import '../common/toast_tip.dart';

class AppointDiscipleRoleDialog extends StatelessWidget {
  final String discipleName;
  final String? currentRole;
  final String? currentRealm;
  final void Function(String? selectedRole) onAppointed;

  const AppointDiscipleRoleDialog({
    super.key,
    required this.discipleName,
    required this.currentRole,
    required this.onAppointed,
    required this.currentRealm,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Future.wait([
        ZongmenStorage.loadDisciples(),
        ZongmenStorage.loadZongmen(),
      ]),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final disciples = snapshot.data![0] as List<Disciple>;
        final Zongmen? zongmen = snapshot.data![1] as Zongmen?;
        final sectLevel = zongmen?.sectLevel ?? 1;

        final groupedMap = <String, List<Disciple>>{};
        for (final d in disciples) {
          final role = d.role ?? '弟子';
          (groupedMap[role] ??= []).add(d);
        }

        final List<SectRole> roles = SectRoleLimits.roles.values
            .where((r) => r.name != '宗主')
            .toList();

        roles.sort((a, b) {
          if (a.name == '弟子') return 1;
          if (b.name == '弟子') return -1;
          return 0;
        });

        return AlertDialog(
          backgroundColor: const Color(0xFFFFF8DC),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.zero,
          ),
          title: Text(
            '$discipleName · $currentRealm',
            style: const TextStyle(
              fontSize: 15,
              color: Colors.black87,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: roles.map((roleObj) {
              final role = roleObj.name;
              final count = groupedMap[role]?.length ?? 0;
              final max = SectRoleLimits.getMax(role, sectLevel);
              final isSelected =
                  (role == currentRole) || (role == '弟子' && currentRole == null);

              // ✅ 简洁判断逻辑
              bool isEnabled;
              if (role == '弟子') {
                isEnabled = true;
              } else if (role == '长老' || role == '执事') {
                isEnabled = sectLevel >= 2 && (count < max || isSelected);
              } else {
                isEnabled = count < max || isSelected;
              }

              final isDisabled = !isEnabled;
              final roleColor = isDisabled
                  ? Colors.grey
                  : SectRoleLimits.getRoleColor(role);

              return ListTile(
                title: Text(
                  isDisabled && (role == '长老' || role == '执事') && sectLevel < 2
                      ? '$role（需宗门2级）'
                      : role,
                  style: TextStyle(
                    color: roleColor,
                    fontSize: 13,
                  ),
                ),
                trailing: isSelected
                    ? const Icon(Icons.check, color: Colors.green)
                    : null,
                enabled: isEnabled,
                onTap: () {
                  if (!isEnabled) {
                    if ((role == '长老' || role == '执事') && sectLevel < 2) {
                      ToastTip.show(context, '⚠️ $role 需宗门等级达到2级才能任命');
                    } else {
                      ToastTip.show(context, '⚠️ $role 已满员');
                    }
                    return;
                  }

                  Navigator.of(context).pop();
                  onAppointed(role == '弟子' ? null : role);
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }
}
