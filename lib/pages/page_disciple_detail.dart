import 'package:flutter/material.dart';
import 'package:xiu_to_xiandi_tuixiu/models/disciple.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/back_button_overlay.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/zongmen_disciple_info_panel.dart';

import '../widgets/components/swipeable_portrait.dart';

class DiscipleDetailPage extends StatefulWidget {
  final Disciple disciple;

  const DiscipleDetailPage({super.key, required this.disciple});

  @override
  State<DiscipleDetailPage> createState() => _DiscipleDetailPageState();
}

class _DiscipleDetailPageState extends State<DiscipleDetailPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  late Disciple disciple;

  double _offsetY = 260.0;
  double _startDragY = 0;
  double _startOffsetY = 260.0;
  bool isHidden = false;

  static const double collapsedOffset = 260.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    disciple = widget.disciple; // 🌟 初始化
  }

  void animateTo(double targetOffset) {
    _animation = Tween<double>(begin: _offsetY, end: targetOffset).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    )..addListener(() {
      setState(() {
        _offsetY = _animation.value;
      });
    });

    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    final hiddenOffset = screenHeight;
    final maxRange = hiddenOffset - collapsedOffset;
    final scale =
    (0.6 + ((_offsetY - collapsedOffset) / maxRange) * 0.6).clamp(0.6, 1.0);

    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          if (_offsetY != collapsedOffset) {
            animateTo(collapsedOffset);
            isHidden = false;
          }
        },
        child: Stack(
          children: [
            // 背景立绘 + 缩放 + 避开刘海
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: screenHeight,
              child: Stack(
                children: [
                  // 🛏️ 全屏背景图（不需要 SafeArea）
                  Positioned.fill(
                    child: Image.asset(
                      'assets/images/bg_dizi_detail.webp',
                      fit: BoxFit.cover,
                      alignment: Alignment.topCenter,
                    ),
                  ),

                  // 🧍 立绘（需要避开刘海，用 SafeArea）
                  SafeArea(
                    top: true,
                    bottom: false,
                    child: Transform.scale(
                      scale: scale,
                      alignment: Alignment.topCenter,
                      child: SwipeablePortrait(
                        imagePath: disciple.imagePath,
                        favorability: disciple.favorability,
                        disciple: disciple,
                        isHidden: isHidden,
                        onTap: () {
                          if (!isHidden) return;

                          animateTo(collapsedOffset); // 让面板展开
                          isHidden = false;
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 拖动 info 面板
            Positioned(
              top: _offsetY,
              left: 0,
              right: 0,
              height: screenHeight,
              child: GestureDetector(
                onPanStart: (details) {
                  _controller.stop();
                  _startDragY = details.globalPosition.dy;
                  _startOffsetY = _offsetY;
                },
                onPanUpdate: (details) {
                  final dy = details.globalPosition.dy - _startDragY;
                  final newOffset = (_startOffsetY + dy)
                      .clamp(collapsedOffset, hiddenOffset);
                  setState(() {
                    _offsetY = newOffset;
                  });
                },
                onPanEnd: (details) {
                  final threshold = maxRange / 2;
                  if (_offsetY - collapsedOffset > threshold) {
                    animateTo(hiddenOffset);
                    isHidden = true;
                  } else {
                    animateTo(collapsedOffset);
                    isHidden = false;
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1D1A17).withOpacity(0.9),
                    borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: ZongmenDiscipleInfoPanel(
                    disciple: disciple,
                    onDiscipleChanged: (updated) {
                      setState(() {
                        disciple = updated;
                      });
                    },
                  ),
                ),
              ),
            ),

            // 返回按钮（隐藏时不显示）
            if (!isHidden) const BackButtonOverlay(),
          ],
        ),
      ),
    );
  }
}
