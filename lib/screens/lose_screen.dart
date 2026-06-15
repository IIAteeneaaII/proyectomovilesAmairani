import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import 'package:ghost_box/theme/kawaii_theme.dart';
import 'package:ghost_box/screens/game_screen.dart';
import 'package:ghost_box/screens/home_screen.dart';

/// Defeat screen: shown when the 90s timer ran out before the box was sealed.
/// Boo "won", so the ghost gives a gentle taunting shake.
class LoseScreen extends StatefulWidget {
  final int score;
  final CameraDescription? camera;

  const LoseScreen({super.key, required this.score, required this.camera});

  @override
  State<LoseScreen> createState() => _LoseScreenState();
}

class _LoseScreenState extends State<LoseScreen>
    with SingleTickerProviderStateMixin {
  // Drives the ghost's gentle horizontal shake (a slow back-and-forth).
  late final AnimationController _shakeCtrl;

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _shakeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Sizes/spacing derived from the viewport rather than hardcoded.
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      body: Container(
        width: size.width,
        height: size.height,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [KawaiiColors.bgDark, KawaiiColors.loseEnd],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Ghost with a gentle horizontal shake. sin() maps the 0..1
                // controller value across a full cycle, giving a smooth
                // left-right sway of +/- 6px.
                AnimatedBuilder(
                  animation: _shakeCtrl,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(
                        math.sin(_shakeCtrl.value * 2 * math.pi) * 6,
                        0,
                      ),
                      child: child,
                    );
                  },
                  child: const GhostImage(size: 120),
                ),
                const SizedBox(height: 24),
                Text(
                  'BOO WON... 👻',
                  textAlign: TextAlign.center,
                  style: kawaiiTitle(
                    fontSize: 40,
                    color: KawaiiColors.primaryPink,
                    shadowColor: KawaiiColors.outline,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'The box remains cursed...',
                  textAlign: TextAlign.center,
                  style: kawaiiBody(
                    fontSize: 18,
                    color: KawaiiColors.softLavender,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Score',
                  textAlign: TextAlign.center,
                  style: kawaiiBody(
                    fontSize: 16,
                    color: KawaiiColors.warmWhite,
                  ),
                ),
                Text(
                  widget.score.toString(),
                  textAlign: TextAlign.center,
                  style: kawaiiTitle(
                    fontSize: 52,
                    color: KawaiiColors.primaryPink,
                    shadowColor: KawaiiColors.boxGlow,
                  ),
                ),
                const SizedBox(height: 30),
                KawaiiPillButton(
                  label: 'PLAY AGAIN',
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => GameScreen(camera: widget.camera),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 14),
                KawaiiOutlinedButton(
                  label: 'HOME',
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => HomeScreen(camera: widget.camera),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
