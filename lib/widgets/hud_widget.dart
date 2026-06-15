import 'package:flutter/material.dart';
import 'package:ghost_box/theme/kawaii_theme.dart';

/// Top heads-up display card shown during play.
///
/// Stateless: it owns no controllers or timers and simply renders the score,
/// remaining time and current point multiplier handed to it by [GameScreen].
class HudWidget extends StatelessWidget {
  final int score;
  final int timeLeft;
  final int multiplier;
  final int maxTime;

  const HudWidget({
    super.key,
    required this.score,
    this.timeLeft = 0,
    this.multiplier = 1,
    this.maxTime = 90,
  });

  /// Timer colour shifts from calm lavender -> pink -> red as time drains.
  /// Guard against a zero [maxTime] so the ratio never divides by zero.
  Color get _timerColor {
    final double ratio = maxTime == 0 ? 0.0 : timeLeft / maxTime;
    if (ratio > 0.5) return KawaiiColors.softLavender;
    if (ratio > 0.2) return KawaiiColors.primaryPink;
    return const Color(0xFFFF5470); // urgent red
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: KawaiiColors.bgDark.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: KawaiiColors.softLavender.withValues(alpha: 0.35),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: KawaiiColors.outline.withValues(alpha: 0.5),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // LEFT: score with a little ghost glyph.
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '\u{1F47B} $score',
                style: kawaiiBody(
                  fontSize: 20,
                  color: KawaiiColors.primaryPink,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          // CENTER: seconds remaining, colour-coded by urgency.
          Expanded(
            child: Align(
              alignment: Alignment.center,
              child: Text(
                timeLeft.toString(),
                style: kawaiiTitle(
                  fontSize: 26,
                  color: _timerColor,
                  shadowColor: KawaiiColors.outline,
                ),
              ),
            ),
          ),
          // RIGHT: mint multiplier badge.
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: KawaiiColors.mintAccent.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: KawaiiColors.mintAccent.withValues(alpha: 0.6),
                  ),
                ),
                child: Text(
                  'x$multiplier',
                  style: kawaiiBody(
                    fontSize: 16,
                    color: KawaiiColors.mintAccent,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
