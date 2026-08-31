import 'dart:async';
import 'package:flutter/material.dart';
import 'package:iptv/app/theme/app_colors.dart';

/// Debounced buffering spinner and non-intrusive reconnecting HUD.
class BufferingIndicator extends StatefulWidget {
  const BufferingIndicator({
    super.key,
    required this.isBuffering,
    this.statusMessage,
    this.debounceDuration = const Duration(milliseconds: 200),
  });

  final bool isBuffering;
  final String? statusMessage;
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
    _handleBufferingChange(widget.isBuffering, immediate: widget.statusMessage != null);
  }

  @override
  void didUpdateWidget(covariant BufferingIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isBuffering != widget.isBuffering ||
        oldWidget.statusMessage != widget.statusMessage) {
      _handleBufferingChange(widget.isBuffering, immediate: widget.statusMessage != null);
    }
  }

  void _handleBufferingChange(bool isBuffering, {bool immediate = false}) {
    _debounceTimer?.cancel();
    if (isBuffering) {
      if (immediate) {
        if (mounted) setState(() => _shouldShow = true);
      } else {
        _debounceTimer = Timer(widget.debounceDuration, () {
          if (mounted) setState(() => _shouldShow = true);
        });
      }
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

    final message = widget.statusMessage;

    return Center(
      child: Container(
        padding: message != null
            ? const EdgeInsets.symmetric(horizontal: 20, vertical: 14)
            : const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.75),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: message != null
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.accent),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              )
            : const SizedBox(
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
