import 'dart:async';
import 'package:flutter/material.dart';

class TypewriterTextSwitcher extends StatefulWidget {
  final List<String> lines;
  final Duration switchDuration;
  final TextStyle? style;

  const TypewriterTextSwitcher({
    super.key,
    required this.lines,
    this.switchDuration = const Duration(seconds: 4),
    this.style,
  });

  @override
  State<TypewriterTextSwitcher> createState() => _TypewriterTextSwitcherState();
}

class _TypewriterTextSwitcherState extends State<TypewriterTextSwitcher> {
  int _currentLineIndex = 0;
  String _displayedText = '';
  Timer? _switchTimer;
  Timer? _typingTimer;
  int _charIndex = 0;

  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    _startTyping();
  }

  @override
  void dispose() {
    _disposed = true;
    _switchTimer?.cancel();
    _typingTimer?.cancel();
    super.dispose();
  }

  void _safeSetState(VoidCallback fn) {
    if (!_disposed && mounted) {
      setState(fn);
    }
  }

  void _startTyping() {
    _charIndex = 0;
    _displayedText = '';
    final line = widget.lines[_currentLineIndex];

    _typingTimer?.cancel();
    _typingTimer = Timer.periodic(const Duration(milliseconds: 40), (timer) {
      if (_disposed || !mounted) {
        timer.cancel();
        return;
      }

      if (_charIndex >= line.length) {
        timer.cancel();
        _scheduleNextLine();
        return;
      }

      _safeSetState(() {
        _displayedText += line[_charIndex];
      });

      _charIndex++;
    });
  }

  void _scheduleNextLine() {
    _switchTimer?.cancel();
    _switchTimer = Timer(widget.switchDuration, () {
      if (_disposed || !mounted) return;

      _safeSetState(() {
        _currentLineIndex = (_currentLineIndex + 1) % widget.lines.length;
      });
      _startTyping();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _displayedText,
      style: widget.style,
      textAlign: TextAlign.center,
    );
  }
}
