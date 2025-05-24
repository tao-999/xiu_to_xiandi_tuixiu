import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/charts/polygon_radar_chart.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/effects/xiuxian_particle_background.dart';
import 'package:xiu_to_xiandi_tuixiu/pages/page_root.dart';
import 'package:uuid/uuid.dart';

class CreateRolePage extends StatefulWidget {
  const CreateRolePage({super.key});

  @override
  State<CreateRolePage> createState() => _CreateRolePageState();
}

class _CreateRolePageState extends State<CreateRolePage> {
  String nickname = "";
  String gender = "male";
  String bio = "";

  int gold = 6;
  int wood = 6;
  int water = 6;
  int fire = 6;
  int earth = 6;

  final int maxTotal = 30;

  int get currentTotal => gold + wood + water + fire + earth;

  Future<void> _saveRoleData() async {
    final uuid = Uuid();
    final String playerId = uuid.v4();
    final prefs = await SharedPreferences.getInstance();
    final Map<String, dynamic> player = {
      'playerId': playerId,
      'nickname': nickname,
      'gender': gender,
      'bio': bio,
      'gold': gold,
      'wood': wood,
      'water': water,
      'fire': fire,
      'earth': earth,
      'createdAt': DateTime.now().toIso8601String(), // ✅ 创建时间字段
    };
    await prefs.setString('playerData', jsonEncode(player));
  }

  void _updateValue(String element, int value) {
    setState(() {
      switch (element) {
        case '金':
          gold = value;
          break;
        case '木':
          wood = value;
          break;
        case '水':
          water = value;
          break;
        case '火':
          fire = value;
          break;
        case '土':
          earth = value;
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/images/bg_xiuxian.png"),
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
              ),
            ),
          ),
          Container(color: Colors.white.withOpacity(0.4)),
          SizedBox(
            width: double.infinity,
            height: MediaQuery.of(context).size.height,
            child: const XiuxianParticleBackground(),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("灵魂投放 · 创建角色", style: TextStyle(fontSize: 20, color: Colors.black)),
                  const SizedBox(height: 16),
                  TextField(
                    onChanged: (value) => setState(() => nickname = value),
                    decoration: const InputDecoration(labelText: "修士道号", labelStyle: TextStyle(color: Colors.black)),
                    style: const TextStyle(color: Colors.black),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text("性别：", style: TextStyle(color: Colors.black)),
                      Radio(
                        value: "male",
                        groupValue: gender,
                        activeColor: Colors.teal,
                        onChanged: (value) => setState(() => gender = value!),
                      ),
                      const Text("男", style: TextStyle(color: Colors.black)),
                      Radio(
                        value: "female",
                        groupValue: gender,
                        activeColor: Colors.teal,
                        onChanged: (value) => setState(() => gender = value!),
                      ),
                      const Text("女", style: TextStyle(color: Colors.black)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    onChanged: (value) => setState(() => bio = value),
                    decoration: const InputDecoration(labelText: "道心宣言（可空）", labelStyle: TextStyle(color: Colors.black45)),
                    style: const TextStyle(color: Colors.black),
                  ),
                  const SizedBox(height: 12),
                  const Text("五行天赋分配（总点数上限：30）", style: TextStyle(color: Colors.black)),
                  const SizedBox(height: 6),
                  Text(
                    "剩余点数：${maxTotal - currentTotal}",
                    style: TextStyle(
                      color: (maxTotal - currentTotal) < 0 ? Colors.red : Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ...["金", "木", "水", "火", "土"].map((e) {
                    int current = {
                      '金': gold,
                      '木': wood,
                      '水': water,
                      '火': fire,
                      '土': earth,
                    }[e]!;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("$e：$current", style: const TextStyle(color: Colors.black)),
                        Slider(
                          min: 0,
                          max: 15,
                          divisions: 15,
                          activeColor: Colors.teal,
                          inactiveColor: Colors.teal.shade100,
                          label: current.toString(),
                          value: current.toDouble(),
                          onChanged: (val) {
                            if (currentTotal - current + val.toInt() <= maxTotal) {
                              _updateValue(e, val.toInt());
                            }
                          },
                        ),
                      ],
                    );
                  }),
                  const SizedBox(height: 12),
                  Center(
                    child: SizedBox(
                      width: 240,
                      height: 240,
                      child: PolygonRadarChart(
                        values: [gold, wood, water, fire, earth],
                        labels: ['金', '木', '水', '火', '土'],
                        max: 15,
                        strokeColor: Colors.black87,
                        fillColor: Colors.teal.withOpacity(0.2),
                        labelStyle: const TextStyle(fontSize: 14, color: Colors.black),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal.shade600,
                        foregroundColor: Colors.white,
                        elevation: 4,
                      ),
                      onPressed: () async {
                        if (nickname.trim().isEmpty) return;
                        await _saveRoleData();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("角色 $nickname 创建完成！")),
                        );
                        await Future.delayed(const Duration(seconds: 1));
                        if (!mounted) return;
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (context) => const XiudiRoot()),
                              (route) => false,
                        );
                      },
                      child: const Text("确认启灵"),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
