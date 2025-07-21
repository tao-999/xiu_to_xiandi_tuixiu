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

    // 先用 0 初始化，等加载完路径再跳转
    _controller = PageController(initialPage: 0);

    _initAvailablePaths();

    _controller.addListener(() async {
      final page = _controller.page?.round() ?? 0;
      if (page != _currentPage) {
        setState(() {
          _currentPage = page;
        });

        final requiredFavorability = page * _unlockFavorability;
        final isLocked = widget.favorability < requiredFavorability;
        if (isLocked) return;

        final newImagePath = _availablePaths[page];
        debugPrint('[SwipeablePortrait] 切换到立绘: $newImagePath');

        await ZongmenDiscipleService.setDisciplePortrait(
          widget.disciple.id,
          newImagePath,
        );

        setState(() {
          widget.disciple.imagePath = newImagePath;
        });
      }
    });
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
        if (i == 0 && exists.isEmpty) {
          exists.add(_getImagePath(0));
          debugPrint('[SwipeablePortrait] 全部不存在，默认保留: ${_getImagePath(0)}');
        }
        break;
      }
    }

    debugPrint('[SwipeablePortrait] 最终可用路径: $exists');

    if (mounted) {
      final initIndex = exists.indexOf(widget.imagePath);
      final targetIndex = initIndex >= 0 ? initIndex : 0;

      setState(() {
        _availablePaths = exists;
        _currentPage = targetIndex;
      });

      // 🌟 初始化后跳转到正确页
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _controller.jumpToPage(targetIndex);
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
        final requiredFavorability = _currentPage * _unlockFavorability;
        final locked = widget.favorability < requiredFavorability;
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
          final requiredFavorability = index * _unlockFavorability;
          final locked = widget.favorability < requiredFavorability;

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
                      '好感度$requiredFavorability解锁 🔒',
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
