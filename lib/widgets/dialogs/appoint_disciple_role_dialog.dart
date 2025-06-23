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
        final sectExp = zongmen?.sectExp ?? 0;
        final sectLevel = ZongmenStorage.calcSectLevel(sectExp);

        final groupedMap = <String, List<Disciple>>{};
        for (final d in disciples) {
          final role = d.role ?? '弟子';
          (groupedMap[role] ??= []).add(d);
        }

        // ✅ 提取要展示的角色（不包括宗主）
        final List<SectRole> roles = SectRoleLimits.roles.values
            .where((r) => r.name != '宗主')
            .toList();

        // ✅ 始终将“弟子”放到最后
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
              final isSelected =
                  (role == currentRole) || (role == '弟子' && currentRole == null);
              final isFull = SectRoleLimits.isRoleFull(role, groupedMap, sectLevel);

              return ListTile(
                title: Text(
                  role,
                  style: TextStyle(
                    color: isFull && !isSelected
                        ? Colors.grey
                        : SectRoleLimits.getRoleColor(role),
                    fontSize: 13,
                  ),
                ),
                trailing: isSelected
                    ? const Icon(Icons.check, color: Colors.green)
                    : null,
                enabled: !isFull || isSelected,
                onTap: () {
                  if (!isSelected && isFull) {
                    ToastTip.show(context, '⚠️ $role 已满员');
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
