import 'package:flutter/material.dart';
import 'package:xiu_to_xiandi_tuixiu/models/disciple.dart';

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
        final imagePath = d.imagePath;

        return SlideTransition(
          position: _animations[index],
          child: Container(
            width: 60,
            height: 350, // ✅ 高度固定为 350
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: imagePath.isNotEmpty
                  ? Image.asset(imagePath, fit: BoxFit.cover)
                  : const SizedBox.shrink(),
            ),
          ),
        );
      }).toList(),
    );
  }
}
