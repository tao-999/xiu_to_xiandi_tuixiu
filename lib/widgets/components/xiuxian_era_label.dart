// lib/widgets/components/xiuxian_era_label.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:xiu_to_xiandi_tuixiu/utils/xianji_calendar.dart';
import 'package:xiu_to_xiandi_tuixiu/services/player_storage.dart';

class XiuxianEraLabel extends StatefulWidget {
  const XiuxianEraLabel({super.key});

  @override
  State<XiuxianEraLabel> createState() => _XiuxianEraLabelState();
}

class _XiuxianEraLabelState extends State<XiuxianEraLabel>
    with WidgetsBindingObserver {
  String _displayText = '';
  Timer? _timer;
  int? _createdAtSec; // 玩家创建时间（秒）

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initAndSchedule();
  }

  Future<void> _initAndSchedule() async {
    // 1) 取玩家 createdAt（兼容毫秒/秒）
    final p = await PlayerStorage.getPlayer();
    if (p?.createdAt is int) {
      final raw = p!.createdAt as int;
      _createdAtSec = raw > 1000000000000 ? raw ~/ 1000 : raw;
    } else {
      _createdAtSec = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    }

    // 2) 立刻刷新一次
    await _refreshLabel();

    // 3) 安排下一次在“修真日边界”触发
    _scheduleNextTick();
  }

  Future<void> _refreshLabel() async {
    final text = await XianjiCalendar.currentYear();
    if (!mounted) return;
    setState(() => _displayText = text);
  }

  void _scheduleNextTick() {
    _timer?.cancel();

    final created = _createdAtSec;
    final dayLen = XianjiCalendar.IMMORTAL_SECONDS_PER_DAY;
    if (created == null || dayLen <= 0) {
      // 兜底：1秒心跳
      _timer = Timer(const Duration(seconds: 1), _onTick);
      return;
    }

    final nowSec = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final diff = nowSec - created;
    final mod = diff % dayLen;
    int remain = dayLen - mod;         // 距离下一个“修真日”边界的秒数
    if (remain <= 0) remain = 1;

    // 给点余量，避免边界抖动（+20ms）
    final dur = Duration(milliseconds: remain * 1000 + 20);
    _timer = Timer(dur, _onTick);
  }

  Future<void> _onTick() async {
    await _refreshLabel();
    _scheduleNextTick(); // 继续预约下一天
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // 前后台切换时，重置一次，防止系统休眠后错过边界
    if (state == AppLifecycleState.resumed) {
      _timer?.cancel();
      _refreshLabel();
      _scheduleNextTick();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _displayText,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 10,
      ),
    );
  }
}
