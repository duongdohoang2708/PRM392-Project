import 'package:flutter/material.dart';

const Duration kAppStaggeredBaseDelay = Duration(milliseconds: 65);
const Duration kAppStaggeredAnimationDuration = Duration(milliseconds: 400);
const Duration kAppStaggeredNewItemDuration = Duration(milliseconds: 500);
const int kAppStaggeredMaxDelayMs = 800;
const Offset kAppStaggeredSlideBegin = Offset(0, -0.4);

/// Widget tạo hiệu ứng xuất hiện lần lượt (staggered entrance) cho các item
/// trong danh sách. Item đầu tiên hiện ngay, các item sau delay tăng dần.
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
    this.baseDelay = kAppStaggeredBaseDelay,
    this.animationDuration = kAppStaggeredAnimationDuration,
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
  bool? _isNewAddition;

  @override
  void initState() {
    super.initState();
    _isNewAddition = widget.isNewAddition;
    _controller = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );

    if (widget.isNewAddition) {
      _sizeAnimation = CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOutCubic),
      );
      _fadeAnimation = CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      );
    } else {
      _sizeAnimation = CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      );
      _fadeAnimation = CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      );
    }

    _slideAnimation = Tween<Offset>(
      begin: kAppStaggeredSlideBegin,
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    if (widget.isNewAddition) {
      _controller.duration = kAppStaggeredNewItemDuration;
      if (mounted) _controller.forward();
    } else if (widget.disableEntranceAnimation) {
      if (mounted) _controller.value = 1.0;
    } else {
      final delay = Duration(
        milliseconds: (widget.index * widget.baseDelay.inMilliseconds).clamp(
          0,
          kAppStaggeredMaxDelayMs,
        ),
      );

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Future.delayed(delay, () {
          if (mounted) _controller.forward();
        });
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
    final isNew = _isNewAddition ?? widget.isNewAddition;
    _isNewAddition = isNew;

    if (isNew) {
      return SizeTransition(
        sizeFactor: _sizeAnimation,
        axis: Axis.vertical,
        axisAlignment: -1.0,
        child: FadeTransition(opacity: _fadeAnimation, child: widget.child),
      );
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(position: _slideAnimation, child: widget.child),
    );
  }
}
