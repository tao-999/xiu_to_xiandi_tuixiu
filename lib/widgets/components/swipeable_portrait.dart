import 'package:flutter/material.dart';
import 'package:xiu_to_xiandi_tuixiu/services/zongmen_disciple_service.dart';

import '../../models/disciple.dart';

class SwipeablePortrait extends StatefulWidget {
  final String imagePath; // 初始路径，仅用于第一帧
  final int favorability;
  final bool isHidden;
  final Disciple disciple;
  final VoidCallback? onTap;

  const SwipeablePortrait({
    Key? key,
    required this.imagePath,
    required this.favorability,
    required this.isHidden,
    required this.disciple,
    this.onTap,
  }) : super(key: key);

  @override
  State<SwipeablePortrait> createState() => _SwipeablePortraitState();
}

class _SwipeablePortraitState extends State<SwipeablePortrait> {
  static const int _unlockFavorability = 1000;

  late final PageController _controller;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController(
      initialPage: _inferInitialPage(),
    );

    _controller.addListener(() async {
      final page = _controller.page?.round() ?? 0;
      if (page != _currentPage) {
        setState(() {
          _currentPage = page;
        });

        final isLocked = page == 1 && widget.favorability < _unlockFavorability;
        if (isLocked) return;

        final newImagePath = _getImagePath(page);

        // 🖼️ 直接更新数据库
        await ZongmenDiscipleService.setDisciplePortrait(widget.disciple.id, newImagePath);

        // 🖼️ 同时更新内存
        setState(() {
          widget.disciple.imagePath = newImagePath;
        });
      }
    });
  }

  /// 推断初始页
  int _inferInitialPage() {
    final ext = widget.imagePath.split('.').last;
    if (widget.imagePath.contains('_1.$ext')) {
      return 1;
    }
    return 0;
  }

  String _getImagePath(int index) {
    final path = widget.imagePath;
    final dotIndex = path.lastIndexOf('.');
    if (dotIndex == -1) return path;

    final ext = path.substring(dotIndex + 1);
    var base = path.substring(0, dotIndex);

    if (base.endsWith('_1')) {
      base = base.substring(0, base.length - 2);
    }

    if (index == 0) {
      return '$base.$ext';
    } else {
      return '${base}_1.$ext';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        final locked = _currentPage == 1 && widget.favorability < _unlockFavorability;
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
          final locked = index == 1 && widget.favorability < _unlockFavorability;
          return Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(_getImagePath(index)),
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
                Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Text(
                    '好感度$_unlockFavorability解锁 🔒',
                    style: const TextStyle(
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
