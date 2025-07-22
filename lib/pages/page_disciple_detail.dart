import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:xiu_to_xiandi_tuixiu/models/disciple.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/back_button_overlay.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/zongmen_disciple_info_panel.dart';
import '../widgets/components/swipeable_portrait.dart';

class DiscipleDetailPage extends StatefulWidget {
  final String discipleId;

  const DiscipleDetailPage({super.key, required this.discipleId});

  @override
  State<DiscipleDetailPage> createState() => _DiscipleDetailPageState();
}

class _DiscipleDetailPageState extends State<DiscipleDetailPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  Disciple? disciple;

  double _offsetY = 0.0;
  double _startDragY = 0;
  double _startOffsetY = 0.0;
  bool isHidden = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _loadDisciple();
  }

  Future<void> _loadDisciple() async {
    final box = Hive.box<Disciple>('disciples');
    final real = box.get(widget.discipleId);
    if (real != null) {
      setState(() {
        disciple = real;
      });
    }
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
    final d = disciple;
    final screenHeight = MediaQuery.of(context).size.height;

    final panelHeight = screenHeight * 0.5;
    final collapsedOffset = screenHeight * 0.5;
    final hiddenOffset = screenHeight;
    final maxRange = hiddenOffset - collapsedOffset;

    if (_offsetY == 0.0) {
      _offsetY = collapsedOffset;
    }

    final scale =
    (0.6 + ((_offsetY - collapsedOffset) / maxRange) * 0.6).clamp(0.6, 1.0);

    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: d == null
          ? const Center(child: CircularProgressIndicator())
          : GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          if (_offsetY != collapsedOffset) {
            animateTo(collapsedOffset);
            isHidden = false;
          }
        },
        child: Stack(
          children: [
            // 背景 + 立绘
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: screenHeight,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Image.asset(
                      'assets/images/bg_dizi_detail.webp',
                      fit: BoxFit.cover,
                      alignment: Alignment.topCenter,
                    ),
                  ),
                  SafeArea(
                    top: true,
                    bottom: false,
                    child: Transform.scale(
                      scale: scale,
                      alignment: Alignment.topCenter,
                      child: SwipeablePortrait(
                        imagePath: d.imagePath,
                        favorability: d.favorability,
                        disciple: d,
                        isHidden: isHidden,
                        onTap: () {
                          if (!isHidden) return;
                          animateTo(collapsedOffset);
                          isHidden = false;
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 拖动面板
            Positioned(
              top: _offsetY,
              left: 0,
              right: 0,
              height: panelHeight,
              child: GestureDetector(
                onPanStart: (details) {
                  _controller.stop();
                  _startDragY = details.globalPosition.dy;
                  _startOffsetY = _offsetY;
                },
                onPanUpdate: (details) {
                  final dy = details.globalPosition.dy - _startDragY;
                  final newOffset =
                  (_startOffsetY + dy).clamp(collapsedOffset, hiddenOffset);
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
                  ),
                  child: ZongmenDiscipleInfoPanel(
                    disciple: d,
                    onDiscipleChanged: (updated) {
                      setState(() {
                        disciple = updated;
                      });
                    },
                  ),
                ),
              ),
            ),

            if (!isHidden) const BackButtonOverlay(),
          ],
        ),
      ),
    );
  }
}
