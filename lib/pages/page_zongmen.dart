// lib/pages/page_zongmen.dart

import 'package:flutter/material.dart';
import 'package:xiu_to_xiandi_tuixiu/models/zongmen.dart';
import 'package:xiu_to_xiandi_tuixiu/models/disciple.dart';
import 'package:xiu_to_xiandi_tuixiu/services/zongmen_storage.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/back_button_overlay.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/create_zongmen_card.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/zongmen_quick_menu.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/zongmen_header_widget.dart';

import '../services/resources_storage.dart';
import '../services/zongmen_disciple_service.dart';
import '../utils/number_format.dart';
import '../widgets/common/toast_tip.dart';

class ZongmenPage extends StatefulWidget {
  const ZongmenPage({super.key});

  @override
  State<ZongmenPage> createState() => _ZongmenPageState();
}

class _ZongmenPageState extends State<ZongmenPage> {
  Zongmen? zongmen;
  List<Disciple> disciples = [];
  bool _checkingZongmen = true;
  bool _showCreateCard = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final stored = await ZongmenStorage.loadZongmen();
    if (stored == null) {
      setState(() {
        _showCreateCard = true;
        _checkingZongmen = false;
      });
    } else {
      final list = await ZongmenStorage.loadDisciples();
      setState(() {
        zongmen = stored;
        disciples = list;
        _checkingZongmen = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingZongmen) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.orangeAccent)),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F0D0B),
      body: Stack(
        children: [
          // 背景图及遮罩
          Positioned.fill(
            child: Image.asset(
              'assets/images/bg_zongmen_shiwaitaoyuan.webp',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(color: Colors.black.withOpacity(0.35)),
          ),

          // 宗门内容
          if (zongmen != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  // 宗门名 + 等级 + 经验进度
                  ZongmenHeaderWidget(
                    zongmen: zongmen!,
                    onUpgrade: () async {
                      final required = ZongmenStorage.requiredStones(zongmen!.sectLevel);
                      final res = await ResourcesStorage.load();
                      final has = res.spiritStoneLow;

                      final canUpgrade = has.compareTo(required) >= 0;

                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          backgroundColor: const Color(0xFFFFF8DC),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                          contentPadding: const EdgeInsets.all(16),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // 顶部标题行
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(Icons.auto_awesome, color: Colors.orangeAccent, size: 20),
                                  SizedBox(width: 6),
                                  Text(
                                    '升级宗门',
                                    style: TextStyle(
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              // 内容区
                              Text.rich(
                                TextSpan(
                                  style: const TextStyle(fontSize: 14, color: Colors.black),
                                  children: [
                                    const TextSpan(
                                        text: '需要消耗',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                    TextSpan(
                                      text: '${formatAnyNumber(required)} 下品灵石\n',
                                      style: TextStyle(color: canUpgrade ? Colors.green : Colors.red, fontSize: 10),
                                    ),
                                    TextSpan(
                                      text: '（当前拥有：${formatAnyNumber(has)}）',
                                      style: TextStyle(fontSize: 10),
                                    ),
                                  ],
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              // 底部确认区域
                              GestureDetector(
                                onTap: canUpgrade
                                    ? () => Navigator.of(context).pop(true)
                                    : null,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.upgrade,
                                      color: canUpgrade ? Colors.blue : Colors.grey,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '升级宗门',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: canUpgrade ? Colors.blue : Colors.grey,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        )
                      );

                      if (confirmed == true) {
                        final newZongmen = await ZongmenStorage.upgradeSectLevel(zongmen!);
                        setState(() {
                          zongmen = newZongmen;
                        });

                        // 🚀 升级成功提示
                        ToastTip.show(context, '✨宗门升级成功！');
                      }
                    },
                  ),
                  const SizedBox(height: 200),
                  // 快捷菜单
                  const ZongmenQuickMenu(),
                ],
              ),
            ),

          // 首次创建弹窗
          if (_showCreateCard)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.5),
                child: CreateZongmenCard(
                  onConfirm: (name) async {
                    final newZongmen = Zongmen(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      name: name,
                      founderName: '你自己',
                      emblemPath: 'assets/images/emblem_default.png',
                      specialization: '未知',
                    );
                    await ZongmenStorage.saveZongmen(newZongmen);
                    final list = await ZongmenStorage.loadDisciples();
                    setState(() {
                      zongmen = newZongmen;
                      disciples = list;
                      _showCreateCard = false;
                    });
                  },
                ),
              ),
            ),

          // 返回按钮
          const BackButtonOverlay(),
        ],
      ),
    );
  }

  Widget _buildZongmenInfoCard() {
    return Container(
      child: Text(
        "弟子数量：${disciples.length}",
        style: _infoStyle(),
      ),
    );
  }

  TextStyle _infoStyle() {
    return const TextStyle(
      fontSize: 14,
      color: Colors.white70,
      fontFamily: 'ZcoolCangEr',
    );
  }
}
