import 'package:flutter/material.dart';
import 'package:xiu_to_xiandi_tuixiu/models/disciple.dart';
import 'package:xiu_to_xiandi_tuixiu/services/disciple_storage.dart';
import 'package:xiu_to_xiandi_tuixiu/services/resources_storage.dart';
import 'package:xiu_to_xiandi_tuixiu/utils/number_format.dart';

import '../../services/zongmen_disciple_service.dart';

class AptitudeCharmDialog extends StatefulWidget {
  final Disciple disciple;
  final VoidCallback? onUpdated; // ✅ 外部刷新回调

  const AptitudeCharmDialog({
    super.key,
    required this.disciple,
    this.onUpdated,
  });

  @override
  State<AptitudeCharmDialog> createState() => _AptitudeCharmDialogState();
}

class _AptitudeCharmDialogState extends State<AptitudeCharmDialog> {
  late int currentAptitude;
  BigInt charmCount = BigInt.zero;
  int useCount = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    currentAptitude = widget.disciple.aptitude;
    _loadCharmCount();
  }

  Future<void> _loadCharmCount() async {
    charmCount = await ResourcesStorage.getValue('fateRecruitCharm');
    setState(() => isLoading = false);
  }

  void _changeCount(int delta) {
    setState(() {
      // 🚀去掉了上限判断
      useCount = (useCount + delta).clamp(0, charmCount.toInt());
    });
  }

  Future<void> _applyUpgrade() async {
    if (useCount == 0) return;

    await ResourcesStorage.subtract('fateRecruitCharm', BigInt.from(useCount));
    currentAptitude += useCount;
    widget.disciple.aptitude = currentAptitude;
    await DiscipleStorage.save(widget.disciple);

    // ✅ 这里直接刷新属性
    await ZongmenDiscipleService.syncAllRealmWithPlayer();

    widget.onUpdated?.call(); // ✅ 通知外部刷新
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      backgroundColor: const Color(0xFFFFF8E1),
      title: null,
      content: isLoading
          ? const SizedBox(height: 40, child: Center(child: CircularProgressIndicator()))
          : Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('当前资质：$currentAptitude',
              style: const TextStyle(fontSize: 12, fontFamily: 'ZcoolCangEr')),
          const SizedBox(height: 8),
          Text('可用资质券：${formatAnyNumber(charmCount)} 张',
              style: const TextStyle(fontSize: 12, fontFamily: 'ZcoolCangEr')),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: () => _changeCount(-1),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.black,
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(32, 32),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('-', style: TextStyle(fontSize: 14, fontFamily: 'ZcoolCangEr')),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  '$useCount',
                  style: const TextStyle(fontSize: 14, fontFamily: 'ZcoolCangEr'),
                ),
              ),
              TextButton(
                onPressed: () => _changeCount(1),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.black,
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(32, 32),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('+', style: TextStyle(fontSize: 20, fontFamily: 'ZcoolCangEr')),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '提升后资质：${currentAptitude + useCount}',
            style: const TextStyle(fontSize: 12, fontFamily: 'ZcoolCangEr'),
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GestureDetector(
            onTap: useCount > 0 ? _applyUpgrade : null,
            behavior: HitTestBehavior.opaque,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.upgrade, color: Colors.brown),
                SizedBox(width: 6),
                Text(
                  '提升资质',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.brown,
                    fontFamily: 'ZcoolCangEr',
                  ),
                ),
              ],
            ),
          ),
        )
      ],
    );
  }
}
