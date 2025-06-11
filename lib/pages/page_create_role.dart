import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import 'package:xiu_to_xiandi_tuixiu/widgets/charts/polygon_radar_chart.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/effects/xiuxian_particle_background.dart';
import 'package:xiu_to_xiandi_tuixiu/pages/page_root.dart';
import 'package:xiu_to_xiandi_tuixiu/models/character.dart';
import 'package:xiu_to_xiandi_tuixiu/utils/name_generator.dart'; // 👈 引入名字生成器
import 'package:xiu_to_xiandi_tuixiu/widgets/components/fantasy_radio_box.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/fancy_name_input.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/five_element_slider_group.dart';
import 'package:xiu_to_xiandi_tuixiu/models/resources.dart';

import '../services/cultivation_tracker.dart';
import '../widgets/common/toast_tip.dart';

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

  @override
  void initState() {
    super.initState();
    nickname = NameGenerator.generate(isMale: gender == 'male'); // 👈 初始化时生成骚名
  }

  Future<Character> _saveRoleData() async {
    final uuid = Uuid();
    final String playerId = uuid.v4();
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    final character = Character(
      id: playerId,
      name: nickname,
      gender: gender,
      career: '散修',
      cultivation: BigInt.zero,
      baseHp: 100,
      extraHp: 0,
      baseAtk: 20,
      extraAtk: 0,
      baseDef: 10,
      extraDef: 0,
      atkSpeed: 1.0,
      critRate: 0.05,
      critDamage: 0.5,
      dodgeRate: 0.05,
      lifeSteal: 0.0,
      breakArmorRate: 0.0,
      luckRate: 0.05,
      comboRate: 0.1,
      evilAura: 0.0,
      weakAura: 0.0,
      corrosionAura: 0.0,
      cultivationEfficiency: 1.0,
      elements: {
        'gold': gold,
        'wood': wood,
        'water': water,
        'fire': fire,
        'earth': earth,
      },
      technique: '无',
      resources: Resources(),
      createdAt: now,
    );


    await prefs.setString('playerData', jsonEncode(character.toJson()));

    return character; // ✅ 返回这份角色
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
                image: AssetImage("assets/images/bg_xiuxian.webp"),
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
              ),
            ),
          ),
          Container(color: Colors.white.withOpacity(0.4)),
          const XiuxianParticleBackground(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("灵魂投放 · 创建角色", style: TextStyle(fontSize: 20, color: Colors.black)),
                  const SizedBox(height: 16),

                  /// 昵称输入 + 随机按钮
                  FancyNameInput(
                    value: nickname,
                    onChanged: (val) => setState(() => nickname = val),
                    onRandom: () => setState(() => nickname = NameGenerator.generate(isMale: gender == 'male')),
                  ),

                  const SizedBox(height: 12),

                  /// 性别选择
                  FantasyRadioGroup(
                    groupLabel: "性别：",
                    selected: gender, // 这里一定是 "male" 或 "female"
                    options: ["male", "female"],
                    onChanged: (val) => setState(() => gender = val),
                  ),

                  const SizedBox(height: 12),

                  /// 五行分配
                  WuxingAllocationPanel(
                    gold: gold,
                    wood: wood,
                    water: water,
                    fire: fire,
                    earth: earth,
                    onValueChanged: _updateValue,
                  ),

                  /// 雷达图展示
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

                  /// 启灵按钮
                  Center(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal.shade600,
                        foregroundColor: Colors.white,
                        elevation: 4,
                      ),
                      onPressed: () async {
                        if (nickname.trim().isEmpty) return;
                        final character = await _saveRoleData(); // ✅ 获取新角色
                        await CultivationTracker.initWithPlayer(character); // ✅ 启动修为系统
                        CultivationTracker.startGlobalTick();

                        ToastTip.show(context, "角色 $nickname 创建完成！");
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
