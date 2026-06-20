import 'package:flutter/material.dart';

/// Widget tạo hiệu ứng xuất hiện lần lượt (staggered entrance) cho các item
/// trong danh sách. Item đầu tiên hiện ngay, các item sau delay tăng dần.
///
/// Dùng chung cho Task List, Calendar, Projects,...
class StaggeredListEntry extends StatefulWidget {
  final Widget child;
  final int index;
  final Duration baseDelay;
  final Duration animationDuration;
  final bool isNewAddition;
  final bool disableEntranceAnimation;

  const StaggeredListEntry({
    super.key,
    required this.child,
    required this.index,
    this.baseDelay = const Duration(milliseconds: 50),
    this.animationDuration = const Duration(milliseconds: 350),
    this.isNewAddition = false,
    this.disableEntranceAnimation = false,
  });

  @override
  State<StaggeredListEntry> createState() => _StaggeredListEntryState();
}

class _StaggeredListEntryState extends State<StaggeredListEntry>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _sizeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _sizeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );

    if (widget.isNewAddition) {
      // If it's a new addition, play the expansion animation immediately
      if (mounted) _controller.forward();
    } else if (widget.disableEntranceAnimation) {
      // Skip the entrance animation entirely
      if (mounted) _controller.value = 1.0;
    } else {
      // Delay tăng dần theo index, tối đa 500ms delay
      final delay = Duration(
        milliseconds: (widget.index * widget.baseDelay.inMilliseconds).clamp(0, 500),
      );

      Future.delayed(delay, () {
        if (mounted) _controller.forward();
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
    if (widget.isNewAddition) {
      return SizeTransition(
        sizeFactor: _sizeAnimation,
        axis: Axis.vertical,
        axisAlignment: -1.0,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: widget.child,
        ),
      );
    } else {
      return FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: widget.child,
        ),
      );
    }
  }
}
