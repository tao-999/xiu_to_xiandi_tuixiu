import 'package:flutter/material.dart';
import 'package:xiu_to_xiandi_tuixiu/models/disciple.dart';
import 'package:xiu_to_xiandi_tuixiu/services/zongmen_storage.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/back_button_overlay.dart';

class DiscipleListPage extends StatefulWidget {
  const DiscipleListPage({super.key});

  @override
  State<DiscipleListPage> createState() => _DiscipleListPageState();
}

class _DiscipleListPageState extends State<DiscipleListPage> {
  List<Disciple> disciples = [];

  @override
  void initState() {
    super.initState();
    _loadDisciples();
  }

  Future<void> _loadDisciples() async {
    final list = await ZongmenStorage.loadDisciples();
    setState(() => disciples = list);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0D0B),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                const Text(
                  "弟子管理",
                  style: TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: disciples.isEmpty
                      ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text("暂无弟子", style: TextStyle(color: Colors.white70)),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/recruit');
                          },
                          child: const Text("前往招募"),
                        ),
                      ],
                    ),
                  )
                      : ListView.builder(
                    itemCount: disciples.length,
                    itemBuilder: (context, index) {
                      final d = disciples[index];
                      return _buildDiscipleCard(d);
                    },
                  ),
                ),
              ],
            ),
          ),
          const BackButtonOverlay(),
        ],
      ),
    );
  }

  Widget _buildDiscipleCard(Disciple d) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: d.gender == "female" ? Colors.pinkAccent : Colors.blueGrey,
            child: Icon(
              d.gender == "female" ? Icons.female : Icons.male,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(d.name, style: const TextStyle(fontSize: 16, color: Colors.white)),
                const SizedBox(height: 4),
                Text("境界：${d.realm} / 资质：${d.aptitude}", style: const TextStyle(color: Colors.white70, fontSize: 12)),
                Text("特长：${d.specialty}", style: const TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, color: Colors.white),
            onPressed: () {
              // 预留跳转弟子详情页
            },
          )
        ],
      ),
    );
  }
}
