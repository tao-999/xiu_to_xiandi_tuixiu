import 'package:flutter/material.dart';

class ZongmenPage extends StatefulWidget {
  const ZongmenPage({super.key});

  @override
  State<ZongmenPage> createState() => _ZongmenPageState();
}

class _ZongmenPageState extends State<ZongmenPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.account_balance, size: 48, color: Colors.amber),
              SizedBox(height: 16),
              Text(
                '宗门大殿',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 12),
              Text(
                '你可在此查看宗门建设、发布任务、晋升职位\n（后续将开放灵石捐献、功勋兑换、宗主权限等功能）',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
