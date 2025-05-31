import 'package:flutter/material.dart';
import 'package:xiu_to_xiandi_tuixiu/models/disciple.dart';
import 'package:xiu_to_xiandi_tuixiu/utils/aptitude_color_util.dart';

class RecruitCardWidget extends StatefulWidget {
  final List<Disciple> disciples;
  final VoidCallback? onDismiss;

  const RecruitCardWidget({
    super.key,
    required this.disciples,
    this.onDismiss,
  });

  @override
  State<RecruitCardWidget> createState() => _RecruitCardWidgetState();
}

class _RecruitCardWidgetState extends State<RecruitCardWidget>
    with TickerProviderStateMixin {
  late final List<AnimationController> _controllers;
  late final List<Animation<Offset>> _animations;
  final Duration _staggerDuration = const Duration(milliseconds: 100);

  bool _isAnimating = true; // 🧠 动画期间锁定，防止误点关闭

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(widget.disciples.length, (index) {
      return AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600),
      );
    });

    final screenWidth = MediaQueryData.fromWindow(WidgetsBinding.instance.window).size.width;
    final offsetX = screenWidth / 50.0; // 远一点，飞出骚感足

    _animations = _controllers.map((controller) {
      return Tween<Offset>(
        begin: Offset(offsetX, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: Curves.easeOutBack,
      ));
    }).toList();

    _startStaggeredAnimations();
  }

  void _startStaggeredAnimations() async {
    for (int i = 0; i < _controllers.length; i++) {
      await Future.delayed(_staggerDuration);
      _controllers[i].forward();
    }
    setState(() {
      _isAnimating = false; // ✅ 动画完毕，解除锁
    });
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _close() {
    if (_isAnimating) return; // 🚫 动画中不允许关闭
    if (widget.onDismiss != null) widget.onDismiss!();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final disciples = widget.disciples.take(10).toList();
    final List<Disciple> firstRow = (disciples.length > 5 ? disciples.sublist(0, 5) : disciples).cast<Disciple>();
    final List<Disciple> secondRow = (disciples.length > 5 ? disciples.sublist(5) : []).cast<Disciple>();

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _close,
      child: Scaffold(
        backgroundColor: Colors.black.withOpacity(0.6),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildCardRow(firstRow, 0),
              const SizedBox(height: 16),
              if (secondRow.isNotEmpty) _buildCardRow(secondRow, 5),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardRow(List<Disciple> row, int offsetIndex) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: row.asMap().entries.map((entry) {
        final index = entry.key + offsetIndex;
        final d = entry.value;

        return SlideTransition(
          position: _animations[index],
          child: Container(
            width: 60,
            height: 350,
            margin: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              color: AptitudeColorUtil.getBackgroundColor(d.aptitude),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                if (d.aptitude >= 81)
                  BoxShadow(
                    color: Colors.amberAccent.withOpacity(0.8), // SSR 发光
                    blurRadius: 12,
                    spreadRadius: 4,
                  ),
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 6,
                  spreadRadius: 1,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // 🌄 修士立绘图（全屏填充）
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: d.imagePath.isNotEmpty
                      ? Image.asset(
                    d.imagePath,
                    fit: BoxFit.cover,
                    width: 60,
                    height: 350,
                  )
                      : Container(
                    width: 60,
                    height: 350,
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.person, size: 36, color: Colors.grey),
                  ),
                ),

                // 🌀 资质圆圈（右上角贴边）
                Positioned(
                  top: -6,
                  right: -6,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AptitudeColorUtil.getBackgroundColor(d.aptitude),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.black87, width: 1.5),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${d.aptitude}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.black, // 黑色字体更清晰
                      ),
                    ),
                  ),
                ),

                // 🌟 SSR 贴纸（可选）
                if (d.aptitude >= 81)
                  Positioned(
                    bottom: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade800,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'SSR',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
