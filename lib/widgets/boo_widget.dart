import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:ghost_box/theme/kawaii_theme.dart';

/// The cute floating ghost "Boo".
///
/// Boo gently bobs up and down (sine wave), repositions himself to a random
/// spot every couple of seconds, and pops + flashes pink when tapped. Tapping
/// also makes him immediately dart to a new location, so the player has to keep
/// chasing him.
///
/// Returns an [AnimatedPositioned], so this widget is meant to live directly
/// inside the [Stack] of the GameScreen.
class BooWidget extends StatefulWidget {
  const BooWidget({super.key, required this.onTapBoo});

  final VoidCallback onTapBoo;

  @override
  State<BooWidget> createState() => _BooWidgetState();
}

class _BooWidgetState extends State<BooWidget> with TickerProviderStateMixin {
  // Vertical sine bob: one full cycle every 2s, looping forever.
  late final AnimationController _bobCtrl;
  // Quick "pop" on tap (scale up then back down).
  late final AnimationController _scaleCtrl;
  late final Animation<double> _scale;

  late double _left;
  late double _top;
  Timer? _moveTimer; // periodically relocates Boo
  bool _tapped = false; // true during the brief pink flash
  bool _placed = false; // guards one-time placement in didChangeDependencies
  Size _area = Size.zero; // available play area
  double _topInset = 0; // status bar / notch height, so Boo clears the HUD
  final math.Random _rng = math.Random();

  static const double _booSize = 100;

  @override
  void initState() {
    super.initState();
    _bobCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _scaleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    // Pops to 1.3x then back to 1.0x (driven manually on tap).
    _scale = Tween<double>(begin: 1.0, end: 1.3).animate(_scaleCtrl);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Keep the play-area metrics fresh (insets can change), then place Boo
    // once and start relocating him every 2.5s.
    final mq = MediaQuery.of(context);
    _area = mq.size;
    _topInset = mq.padding.top;
    if (!_placed) {
      _placed = true;
      _randomize();
      _moveTimer = Timer.periodic(
        const Duration(milliseconds: 2500),
        (_) => _moveTo(),
      );
    }
  }

  /// Pick a fresh random position inside the play area, leaving a margin clear
  /// of the HUD (top) and any bottom controls.
  void _randomize() {
    const double pad = 16; // side padding
    // Clear the HUD: status-bar/notch inset + the HUD card height.
    final double topMargin = _topInset + 120;
    const double bottomMargin = 120; // keep clear of bottom UI

    // math.max guards against negative ranges on very small screens, so
    // _rng.nextDouble() is always fed a non-negative span.
    final double maxLeft =
        math.max(pad, _area.width - _booSize - pad);
    final double maxTop =
        math.max(topMargin, _area.height - _booSize - bottomMargin);

    _left = pad + _rng.nextDouble() * (maxLeft - pad);
    _top = topMargin + _rng.nextDouble() * (maxTop - topMargin);
  }

  /// Relocate Boo (used by the timer and on tap). Guarded with `mounted`
  /// because it can fire from an async Timer callback.
  void _moveTo() {
    if (!mounted) return;
    setState(_randomize);
  }

  void _onTap() {
    widget.onTapBoo();
    _moveTo(); // Boo jumps to a new spot the instant he's tapped.
    setState(() => _tapped = true);
    // Pop up to 1.3x (100ms), then back to 1.0x (100ms), then clear the flash.
    // Guard before reverse() so it never runs after dispose() (Boo can be
    // removed mid-pop when the game ends or Boos are rebuilt).
    _scaleCtrl.forward(from: 0).then((_) async {
      if (!mounted) return;
      await _scaleCtrl.reverse();
      if (mounted) setState(() => _tapped = false);
    });
  }

  @override
  void dispose() {
    _moveTimer?.cancel();
    _bobCtrl.dispose();
    _scaleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeInOutCubic,
      left: _left,
      top: _top,
      width: _booSize,
      height: _booSize,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _onTap,
        child: AnimatedBuilder(
          animation: Listenable.merge([_bobCtrl, _scaleCtrl]),
          builder: (context, _) {
            // Sine bob: amplitude 12px, period 2s (one _bobCtrl cycle).
            final dy = math.sin(_bobCtrl.value * 2 * math.pi) * 12;
            return Transform.translate(
              offset: Offset(0, dy),
              child: Transform.scale(
                scale: _scale.value,
                child: GhostImage(
                  size: _booSize,
                  tint: _tapped ? KawaiiColors.primaryPink : null,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
