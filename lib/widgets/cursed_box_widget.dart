import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:ghost_box/theme/kawaii_theme.dart';

/// The glowing isometric cursed box that Boo is guarding.
///
/// It pulses a warm aura ([_glowCtrl]), three sparkle stars orbit it
/// ([_orbitCtrl]), and it gives a quick horizontal shake each time the player
/// taps it ([_shakeCtrl]). Below the box sits the seal-progress bar driven by
/// [sealProgress] (0..1) supplied by the game controller.
class CursedBoxWidget extends StatefulWidget {
  final double sealProgress; // 0..1, from GameController.sealProgress
  final VoidCallback onTapBox;

  const CursedBoxWidget({
    super.key,
    required this.sealProgress,
    required this.onTapBox,
  });

  @override
  State<CursedBoxWidget> createState() => _CursedBoxWidgetState();
}

class _CursedBoxWidgetState extends State<CursedBoxWidget>
    with TickerProviderStateMixin {
  late final AnimationController _glowCtrl; // pulsing aura
  late final AnimationController _orbitCtrl; // star orbit
  late final AnimationController _shakeCtrl; // one-shot tap shake

  @override
  void initState() {
    super.initState();
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _orbitCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
    // 240ms == 3 shake cycles * 80ms each.
    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    );
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    _orbitCtrl.dispose();
    _shakeCtrl.dispose();
    super.dispose();
  }

  void _onTap() {
    widget.onTapBox();
    _shakeCtrl.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    // Box scales with screen width but is capped so it never dominates.
    final boxSize = math.min(size.width * 0.42, 170.0);
    // Generous stack so the glow + orbiting stars have room around the box.
    final stackSize = boxSize * 2;
    final starFont = boxSize * 0.16;
    final clampedProgress = widget.sealProgress.clamp(0.0, 1.0);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ---- The box + glow + orbiting stars, with the tap shake applied ----
        AnimatedBuilder(
          animation: _shakeCtrl,
          builder: (context, child) {
            // Shake: 3 full sine cycles over the 240ms run, +/-5px horizontal.
            final dx =
                math.sin(_shakeCtrl.value * 3 * 2 * math.pi) * 5.0;
            return Transform.translate(
              offset: Offset(dx, 0),
              child: child,
            );
          },
          child: SizedBox(
            width: stackSize,
            height: stackSize,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // 1) Pulsing magical aura behind the box.
                AnimatedBuilder(
                  animation: _glowCtrl,
                  builder: (context, _) {
                    // Spread breathes between 10 and 25 px every 1.5s.
                    final spread =
                        ui.lerpDouble(10, 25, _glowCtrl.value)!;
                    final blur = ui.lerpDouble(18, 34, _glowCtrl.value)!;
                    return Container(
                      width: boxSize,
                      height: boxSize,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: KawaiiColors.boxGlow
                                .withValues(alpha: 0.75),
                            blurRadius: blur,
                            spreadRadius: spread,
                          ),
                        ],
                      ),
                    );
                  },
                ),

                // 2) The isometric box itself (tappable to seal it).
                GestureDetector(
                  onTap: _onTap,
                  child: CustomPaint(
                    size: Size.square(boxSize),
                    painter: _CursedBoxPainter(),
                  ),
                ),

                // 3) Three sparkle stars orbiting the box.
                AnimatedBuilder(
                  animation: _orbitCtrl,
                  builder: (context, _) {
                    final r = boxSize * 0.72; // orbit radius
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        for (int i = 0; i < 3; i++)
                          Builder(builder: (_) {
                            // Evenly space the 3 stars 120 degrees apart and
                            // sweep them around the circle over time.
                            final angle = _orbitCtrl.value * 2 * math.pi +
                                i * (2 * math.pi / 3);
                            // polar -> cartesian for the orbit position.
                            return Transform.translate(
                              offset: Offset(
                                math.cos(angle) * r,
                                math.sin(angle) * r,
                              ),
                              child: Text(
                                '✨', // sparkles emoji
                                style: TextStyle(fontSize: starFont),
                              ),
                            );
                          }),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 28),

        // ---- Seal progress bar ----
        SizedBox(
          width: size.width * 0.62,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Seal ${(widget.sealProgress * 100).round()}%',
                style: kawaiiBody(
                  fontSize: 13,
                  color: KawaiiColors.warmWhite,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                height: 20,
                decoration: BoxDecoration(
                  color: KawaiiColors.bgDark.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: KawaiiColors.softLavender.withValues(alpha: 0.4),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: clampedProgress),
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                    builder: (context, value, _) {
                      return FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: value,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                KawaiiColors.primaryPink,
                                KawaiiColors.boxGlow,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Paints a cute isometric cursed box with three visible rounded faces plus a
/// pink heart "seal" on the top face. All geometry is derived from [size] so
/// it scales with the box.
class _CursedBoxPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // ---- Isometric anchor points ----
    // We build a chunky cube: the top is a rhombus (diamond), and the two
    // lower quads are the left and right faces. Heights/widths are fractions
    // of the canvas so the whole thing stays inside [size].
    final cx = w * 0.5; // horizontal centre
    final topY = h * 0.06; // apex of the top rhombus
    final midY = h * 0.46; // front-corner vertex where the faces meet
    final shoulderY = h * 0.30; // left/right top corners of the rhombus
    final bottomY = h * 0.86; // bottom of the side faces
    final leftX = w * 0.10;
    final rightX = w * 0.90;

    // Small rounding amount applied at each corner via quadratic beziers.
    final round = w * 0.04;

    // ---- TOP face (rhombus): apex(top), right shoulder, front, left shoulder.
    final top = _roundedPoly(
      [
        Offset(cx, topY), // top apex
        Offset(rightX, shoulderY), // right shoulder
        Offset(cx, midY), // front centre
        Offset(leftX, shoulderY), // left shoulder
      ],
      round,
    );

    // ---- LEFT face: left shoulder, front, front-bottom, left-bottom.
    final left = _roundedPoly(
      [
        Offset(leftX, shoulderY),
        Offset(cx, midY),
        Offset(cx, bottomY),
        Offset(leftX, bottomY - (midY - shoulderY)),
      ],
      round,
    );

    // ---- RIGHT face: front, right shoulder, right-bottom, front-bottom.
    final right = _roundedPoly(
      [
        Offset(cx, midY),
        Offset(rightX, shoulderY),
        Offset(rightX, bottomY - (midY - shoulderY)),
        Offset(cx, bottomY),
      ],
      round,
    );

    final outline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.018
      ..color = KawaiiColors.outline;

    // Draw faces back-to-front-ish: sides first, then the bright top on top.
    canvas.drawPath(left, Paint()..color = KawaiiColors.boxLeft);
    canvas.drawPath(left, outline);
    canvas.drawPath(right, Paint()..color = KawaiiColors.boxRight);
    canvas.drawPath(right, outline);
    canvas.drawPath(top, Paint()..color = KawaiiColors.boxGlow);
    canvas.drawPath(top, outline);

    // ---- Heart seal centred on the top face ----
    // The top face centre sits midway between the apex and the front vertex.
    final heartCenter = Offset(cx, (topY + midY) / 2);
    final heartSize = w * 0.32;
    canvas.drawPath(
      _heartPath(heartCenter, heartSize),
      Paint()..color = KawaiiColors.primaryPink,
    );
  }

  /// Builds a closed polygon path whose corners are softened with quadratic
  /// beziers. [pts] are the sharp vertices in order; [r] is the rounding
  /// radius pulled back along each edge.
  Path _roundedPoly(List<Offset> pts, double r) {
    final path = Path();
    final n = pts.length;
    for (int i = 0; i < n; i++) {
      final prev = pts[(i - 1 + n) % n];
      final curr = pts[i];
      final next = pts[(i + 1) % n];

      // Points pulled back from the corner toward the neighbouring vertices.
      final toPrev = _shorten(curr, prev, r);
      final toNext = _shorten(curr, next, r);

      if (i == 0) {
        path.moveTo(toPrev.dx, toPrev.dy);
      } else {
        path.lineTo(toPrev.dx, toPrev.dy);
      }
      // Round the corner using the sharp vertex as the control point.
      path.quadraticBezierTo(curr.dx, curr.dy, toNext.dx, toNext.dy);
    }
    path.close();
    return path;
  }

  /// A point [dist] away from [from] heading toward [to].
  Offset _shorten(Offset from, Offset to, double dist) {
    final dx = to.dx - from.dx;
    final dy = to.dy - from.dy;
    final len = math.sqrt(dx * dx + dy * dy);
    if (len == 0) return from;
    final t = (dist / len).clamp(0.0, 0.5);
    return Offset(from.dx + dx * t, from.dy + dy * t);
  }

  /// A symmetric heart centred at [c], roughly [s] wide/tall. Two top lobes are
  /// formed with cubic curves meeting at a dip, then the sides sweep down to a
  /// bottom point.
  Path _heartPath(Offset c, double s) {
    final path = Path();
    final topDip = c.dy - s * 0.10; // the notch between the two lobes
    final bottom = c.dy + s * 0.45; // the pointed tip
    final halfW = s * 0.5;

    path.moveTo(c.dx, topDip);
    // Left lobe -> down to the bottom tip.
    path.cubicTo(
      c.dx - halfW * 0.2, c.dy - s * 0.55, // pull up over the left lobe
      c.dx - halfW * 1.1, c.dy - s * 0.10, // round the outer left
      c.dx, bottom, // sweep to the tip
    );
    // Bottom tip -> up around the right lobe back to the dip.
    path.cubicTo(
      c.dx + halfW * 1.1, c.dy - s * 0.10, // round the outer right
      c.dx + halfW * 0.2, c.dy - s * 0.55, // pull up over the right lobe
      c.dx, topDip, // back to the notch
    );
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant _CursedBoxPainter oldDelegate) => false;
}
