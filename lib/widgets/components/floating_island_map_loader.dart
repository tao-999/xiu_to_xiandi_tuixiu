import 'dart:math';
import 'package:flutter/material.dart';
import 'package:xiu_to_xiandi_tuixiu/services/floating_island_storage.dart';

class FloatingIslandMapLoader extends StatefulWidget {
  final void Function(int seed) onSeedReady;

  const FloatingIslandMapLoader({
    super.key,
    required this.onSeedReady,
  });

  @override
  State<FloatingIslandMapLoader> createState() => _FloatingIslandMapLoaderState();
}

class _FloatingIslandMapLoaderState extends State<FloatingIslandMapLoader> {
  bool _loading = true;
  bool _showInput = false;
  int _seed = 0;

  static const int _maxSeed = 2147483647;

  @override
  void initState() {
    super.initState();
    _loadOrPrepareSeed();
  }

  Future<void> _loadOrPrepareSeed() async {
    int? storedSeed = await FloatingIslandStorage.getSeed();
    if (storedSeed != null) {
      widget.onSeedReady(storedSeed);
      setState(() {
        _loading = false;
      });
    } else {
      setState(() {
        _showInput = true;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_showInput) {
      return Positioned.fill(
        child: Stack(
          children: [
            // 🌟 背景图片
            Positioned.fill(
              child: Image.asset(
                'assets/images/floating_island_bg.webp',
                fit: BoxFit.cover,
              ),
            ),

            // 🌟 半透明遮罩
            Positioned.fill(
              child: Container(
                color: Colors.black54,
              ),
            ),

            // 🌟 中心对话框
            Center(
              child: Container(
                width: 320,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8DC),
                  borderRadius: BorderRadius.zero,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      '「唤醒浮空仙岛」',
                      style: TextStyle(
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '点骰子生成你的幸运数字。',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 🌟 显示当前数字
                    if (_seed > 0)
                      Text(
                        _seed.toString(),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    else
                      const Text(
                        '还没有数字',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),

                    const SizedBox(height: 12),

                    // 🌟 随机骰子按钮
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _seed = Random().nextInt(_maxSeed - 1) + 1;
                        });
                      },
                      child: const Icon(
                        Icons.casino,
                        size: 32,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // 🌟 确认启程
                    Center(
                      child: GestureDetector(
                        onTap: () async {
                          if (_seed == 0) {
                            return;
                          }

                          // 收起键盘（虽然没输入框，但保险）
                          FocusScope.of(context).unfocus();

                          // 稍微等一下
                          await Future.delayed(const Duration(milliseconds: 300));

                          await FloatingIslandStorage.saveSeed(_seed);
                          widget.onSeedReady(_seed);

                          setState(() {
                            _showInput = false;
                          });
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.sailing),
                            SizedBox(width: 4),
                            Text(
                              '确认启程',
                              style: TextStyle(
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
