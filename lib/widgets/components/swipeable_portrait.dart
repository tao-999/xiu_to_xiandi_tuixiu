import 'package:flutter/material.dart';
import 'package:xiu_to_xiandi_tuixiu/services/portrait_selection_service.dart';

class SwipeablePortrait extends StatefulWidget {
  final String imagePath;
  final int favorability;
  final bool isHidden;
  final String discipleId;
  final VoidCallback? onTap;

  const SwipeablePortrait({
    Key? key,
    required this.imagePath,
    required this.favorability,
    required this.isHidden,
    required this.discipleId,
    this.onTap,
  }) : super(key: key);

  @override
  State<SwipeablePortrait> createState() => _SwipeablePortraitState();
}

class _SwipeablePortraitState extends State<SwipeablePortrait> {
  late final PageController _controller;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController(initialPage: 0);
    _loadSelection();
    _controller.addListener(() {
      final page = _controller.page?.round() ?? 0;
      if (page != _currentPage) {
        setState(() {
          _currentPage = page;
        });
        final isLocked = page == 1 && widget.favorability < 10;
        if (!isLocked) {
          PortraitSelectionService.saveSelection(widget.discipleId, page);
        }
      }
    });
  }

  Future<void> _loadSelection() async {
    final index = await PortraitSelectionService.getSelection(widget.discipleId);
    final isLocked = index == 1 && widget.favorability < 10;
    _controller.jumpToPage(isLocked ? 0 : index);
    setState(() {
      _currentPage = isLocked ? 0 : index;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String getImagePath(int index) {
    if (index == 0) return widget.imagePath;
    final ext = widget.imagePath.split('.').last;
    final withoutExt =
    widget.imagePath.substring(0, widget.imagePath.length - ext.length - 1);
    return '${withoutExt}_$index.$ext';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        final locked = _currentPage == 1 && widget.favorability < 10;
        if (locked) return;
        if (widget.onTap != null) widget.onTap!();
      },
      child: PageView.builder(
        physics: widget.isHidden
            ? const PageScrollPhysics()
            : const NeverScrollableScrollPhysics(),
        controller: _controller,
        itemCount: 2,
        itemBuilder: (context, index) {
          final locked = index == 1 && widget.favorability < 10;
          return Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(getImagePath(index)),
                fit: BoxFit.contain,
                alignment: Alignment.topCenter,
                colorFilter: locked
                    ? const ColorFilter.mode(
                    Colors.grey, BlendMode.saturation)
                    : null,
              ),
            ),
            child: locked
                ? Column(
              children: [
                const Spacer(),
                const Padding(
                  padding: EdgeInsets.only(bottom: 24),
                  child: Text(
                    "好感度10解锁 🔒",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            )
                : null,
          );
        },
      ),
    );
  }
}
