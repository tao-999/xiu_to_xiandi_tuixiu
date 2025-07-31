import 'dart:async';
import 'package:flutter/material.dart';
import 'package:xiu_to_xiandi_tuixiu/utils/xianji_calendar.dart';

class XiuxianEraLabel extends StatefulWidget {
  const XiuxianEraLabel({super.key});

  @override
  State<XiuxianEraLabel> createState() => _XiuxianEraLabelState();
}

class _XiuxianEraLabelState extends State<XiuxianEraLabel> {
  String displayText = '';
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _refreshLabel();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _refreshLabel());
  }

  Future<void> _refreshLabel() async {
    final text = await XianjiCalendar.currentYear();
    if (mounted) {
      setState(() {
        displayText = text;
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      displayText,
      style: const TextStyle(
        color: Colors.black,
        fontSize: 12,
      ),
    );
  }
}
