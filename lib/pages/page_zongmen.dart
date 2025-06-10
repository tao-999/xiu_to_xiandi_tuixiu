// lib/pages/page_zongmen.dart

import 'package:flutter/material.dart';
import 'package:xiu_to_xiandi_tuixiu/models/zongmen.dart';
import 'package:xiu_to_xiandi_tuixiu/models/disciple.dart';
import 'package:xiu_to_xiandi_tuixiu/services/zongmen_storage.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/back_button_overlay.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/create_zongmen_card.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/zongmen_quick_menu.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/zongmen_header_widget.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/zongmen_resource_bar.dart';

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
                  ZongmenHeaderWidget(zongmen: zongmen!),
                  const SizedBox(height: 24),
                  // 弟子数量卡片
                  _buildZongmenInfoCard(),
                  const SizedBox(height: 16),
                  // 资源条
                  ZongmenResourceBar(zongmen: zongmen!),
                  const SizedBox(height: 16),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.brown.shade200.withOpacity(0.25),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Text(
        "弟子数量：${disciples.length}",
        style: _infoStyle(),
      ),
    );
  }

  TextStyle _infoStyle() {
    return const TextStyle(
      fontSize: 16,
      color: Colors.white70,
      fontFamily: 'ZcoolCangEr',
    );
  }
}
