import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// Registers a hit region where pointer gestures must not open the drawer.
///
/// Task list rows use [Slidable] instead; wrap sliders and similar controls.
class DrawerSwipeExclude extends StatefulWidget {
  final Widget child;

  const DrawerSwipeExclude({super.key, required this.child});

  @override
  State<DrawerSwipeExclude> createState() => _DrawerSwipeExcludeState();
}

class _DrawerSwipeExcludeState extends State<DrawerSwipeExclude> {
  final GlobalKey _regionKey = GlobalKey();
  bool _registered = false;
  _DrawerSwipeBodyState? _body;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _body = context.findAncestorStateOfType<_DrawerSwipeBodyState>();
    if (_registered || _body == null) return;
    _body!.registerRegion(_regionKey);
    _registered = true;
  }

  @override
  void dispose() {
    _body?.unregisterRegion(_regionKey);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(key: _regionKey, child: widget.child);
  }
}

/// Shared open-drawer heuristics for pointer-based and drag-based handlers.
class DrawerSwipeGesture {
  DrawerSwipeGesture._();

  /// Minimum rightward travel (logical px) for a deliberate horizontal swipe.
  static const double minHorizontalDistance = 56;

  /// Horizontal travel must exceed vertical by this factor (net displacement).
  static const double minDisplacementDominance = 2.5;

  /// Fast flick: minimum rightward velocity (logical px/s).
  static const double minFlickVelocity = 420;

  /// Flick velocity: |vx| must exceed |vy| by this factor.
  static const double minVelocityDominance = 2.0;

  /// Slow drag: enough horizontal travel with limited vertical drift.
  static const double slowSwipeMinDistance = 88;

  static const double slowSwipeMaxVerticalDrift = 36;

  static bool shouldOpen({
    required Offset delta,
    required Offset velocity,
  }) {
    final dx = delta.dx;
    final dy = delta.dy.abs();
    final vx = velocity.dx;
    final vy = velocity.dy.abs();

    if (dx <= 0) return false;

    final horizontalDominant =
        dx >= minHorizontalDistance && dx >= dy * minDisplacementDominance;

    final flick =
        vx >= minFlickVelocity &&
        vx > vy * minVelocityDominance &&
        dx >= minHorizontalDistance * 0.6;

    final slowDrag = dx >= slowSwipeMinDistance && dy <= slowSwipeMaxVerticalDrift;

    return horizontalDominant && (flick || slowDrag);
  }
}

/// Opens the scaffold drawer on a deliberate right-swipe anywhere on screen,
/// except when the swipe began inside a [DrawerSwipeExclude] region.
///
/// Uses a [Listener] instead of a full-screen [GestureDetector] so horizontal
/// controls (sliders, slidable rows) are not blocked in the gesture arena.
class DrawerSwipeBody extends StatefulWidget {
  final Widget child;

  const DrawerSwipeBody({super.key, required this.child});

  @override
  State<DrawerSwipeBody> createState() => _DrawerSwipeBodyState();
}

class _DrawerSwipeBodyState extends State<DrawerSwipeBody> {
  final Set<GlobalKey> _excludeRegions = {};
  final Map<int, bool> _pointerStartedInExclude = {};
  final Map<int, Offset> _pointerStartPositions = {};
  final Map<int, VelocityTracker> _velocityTrackers = {};

  void registerRegion(GlobalKey key) => _excludeRegions.add(key);

  void unregisterRegion(GlobalKey key) => _excludeRegions.remove(key);

  bool _isExcludedPosition(Offset globalPosition) {
    for (final key in _excludeRegions) {
      final context = key.currentContext;
      if (context == null) continue;
      final renderObject = context.findRenderObject();
      if (renderObject is! RenderBox || !renderObject.hasSize) continue;

      final topLeft = renderObject.localToGlobal(Offset.zero);
      final rect = topLeft & renderObject.size;
      if (rect.contains(globalPosition)) return true;
    }
    return false;
  }

  void _onPointerDown(PointerDownEvent event) {
    _pointerStartedInExclude[event.pointer] =
        _isExcludedPosition(event.position);
    _pointerStartPositions[event.pointer] = event.position;
    final tracker = VelocityTracker.withKind(event.kind);
    tracker.addPosition(event.timeStamp, event.position);
    _velocityTrackers[event.pointer] = tracker;
  }

  void _onPointerMove(PointerMoveEvent event) {
    _velocityTrackers[event.pointer]
        ?.addPosition(event.timeStamp, event.position);
  }

  void _clearPointer(int pointer) {
    _pointerStartedInExclude.remove(pointer);
    _pointerStartPositions.remove(pointer);
    _velocityTrackers.remove(pointer);
  }

  void _onPointerUp(PointerUpEvent event) {
    final startedInExclude =
        _pointerStartedInExclude.remove(event.pointer) ?? false;
    final start = _pointerStartPositions.remove(event.pointer);
    final tracker = _velocityTrackers.remove(event.pointer);
    if (startedInExclude || tracker == null || start == null) return;

    final delta = event.position - start;
    final velocity = tracker.getVelocity().pixelsPerSecond;

    if (DrawerSwipeGesture.shouldOpen(delta: delta, velocity: velocity)) {
      Scaffold.of(context).openDrawer();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _onPointerDown,
      onPointerMove: _onPointerMove,
      onPointerUp: _onPointerUp,
      onPointerCancel: (event) => _clearPointer(event.pointer),
      child: widget.child,
    );
  }
}

/// [GestureDetector] wrapper that uses the same drawer heuristics as [DrawerSwipeBody].
class DrawerSwipeGestureDetector extends StatefulWidget {
  final Widget child;

  const DrawerSwipeGestureDetector({super.key, required this.child});

  @override
  State<DrawerSwipeGestureDetector> createState() =>
      _DrawerSwipeGestureDetectorState();
}

class _DrawerSwipeGestureDetectorState extends State<DrawerSwipeGestureDetector> {
  Offset? _dragStart;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragStart: (details) {
        _dragStart = details.globalPosition;
      },
      onHorizontalDragEnd: (details) {
        final start = _dragStart;
        _dragStart = null;
        if (start == null) return;

        final delta = details.globalPosition - start;
        final velocity = details.velocity.pixelsPerSecond;

        if (DrawerSwipeGesture.shouldOpen(delta: delta, velocity: velocity)) {
          Scaffold.of(context).openDrawer();
        }
      },
      onHorizontalDragCancel: () => _dragStart = null,
      child: widget.child,
    );
  }
}
