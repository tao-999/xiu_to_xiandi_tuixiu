import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  List<String> _availablePaths = [];

  @override
  void initState() {
    super.initState();

    _controller = PageController(
      initialPage: _inferInitialPage(),
    );

    _initAvailablePaths();

    _controller.addListener(() async {
      final page = _controller.page?.round() ?? 0;
      if (page != _currentPage) {
        setState(() {
          _currentPage = page;
        });

        final isLocked = page == 1 && widget.favorability < _unlockFavorability;
        if (isLocked) return;

        final newImagePath = _availablePaths[page];
        debugPrint('[SwipeablePortrait] 切换到立绘: $newImagePath');

        await ZongmenDiscipleService.setDisciplePortrait(widget.disciple.id, newImagePath);

        setState(() {
          widget.disciple.imagePath = newImagePath;
        });
      }
    });
  }

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

    // 如果末尾是 _数字，就去掉
    final underscore = base.lastIndexOf('_');
    if (underscore != -1) {
      final maybeNumber = base.substring(underscore + 1);
      if (int.tryParse(maybeNumber) != null) {
        base = base.substring(0, underscore);
      }
    }

    if (index == 0) {
      return '$base.$ext';
    } else {
      return '${base}_$index.$ext';
    }
  }

  Future<void> _initAvailablePaths() async {
    final List<String> exists = [];

    for (int i = 0;; i++) {
      final path = _getImagePath(i);

      try {
        await rootBundle.load(path);
        debugPrint('[SwipeablePortrait] 存在: $path');
        exists.add(path);
      } catch (_) {
        debugPrint('[SwipeablePortrait] 不存在: $path');
        // 遇到第一张不存在：保底放回
        if (i == 0 && exists.isEmpty) {
          exists.add(_getImagePath(0));
          debugPrint('[SwipeablePortrait] 全部不存在，默认保留: ${_getImagePath(0)}');
        }
        // 不管第几张，遇到不存在就跳出
        break;
      }
    }

    debugPrint('[SwipeablePortrait] 最终可用路径: $exists');

    if (mounted) {
      setState(() {
        _availablePaths = exists;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_availablePaths.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    debugPrint('[SwipeablePortrait] build: isHidden=${widget.isHidden}, availablePaths=${_availablePaths.length}');

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        final locked = _currentPage == 1 && widget.favorability < _unlockFavorability;
        if (locked) return;
        widget.onTap?.call();
      },
      child: PageView.builder(
        controller: _controller,
        itemCount: _availablePaths.length,
        physics: widget.isHidden && _availablePaths.length > 1
            ? const PageScrollPhysics()
            : const NeverScrollableScrollPhysics(),
        itemBuilder: (context, index) {
          final locked = index == 1 && widget.favorability < _unlockFavorability;

          return Stack(
            children: [
              Center(
                child: Image.asset(
                  _availablePaths[index],
                  fit: BoxFit.contain,
                  alignment: Alignment.topCenter,
                  color: locked ? Colors.grey : null,
                  colorBlendMode: locked ? BlendMode.saturation : null,
                ),
              ),
              if (locked)
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
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
                ),
            ],
          );
        },
      ),
    );
  }
}
