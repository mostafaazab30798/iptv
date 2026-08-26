import 'dart:async';
import 'package:flutter/material.dart';
import 'package:iptv/app/theme/app_colors.dart';

/// Debounced buffering spinner that prevents UI flicker during momentary buffer fills.
class BufferingIndicator extends StatefulWidget {
  const BufferingIndicator({
    super.key,
    required this.isBuffering,
    this.debounceDuration = const Duration(milliseconds: 200),
  });

  final bool isBuffering;
  final Duration debounceDuration;

  @override
  State<BufferingIndicator> createState() => _BufferingIndicatorState();
}

class _BufferingIndicatorState extends State<BufferingIndicator> {
  Timer? _debounceTimer;
  bool _shouldShow = false;

  @override
  void initState() {
    super.initState();
    _handleBufferingChange(widget.isBuffering);
  }

  @override
  void didUpdateWidget(covariant BufferingIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isBuffering != widget.isBuffering) {
      _handleBufferingChange(widget.isBuffering);
    }
  }

  void _handleBufferingChange(bool isBuffering) {
    _debounceTimer?.cancel();
    if (isBuffering) {
      _debounceTimer = Timer(widget.debounceDuration, () {
        if (mounted) setState(() => _shouldShow = true);
      });
    } else {
      if (mounted) setState(() => _shouldShow = false);
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_shouldShow) return const SizedBox.shrink();

    return Center(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.65),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: const SizedBox(
          width: 36,
          height: 36,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.accent),
          ),
        ),
      ),
    );
  }
}
