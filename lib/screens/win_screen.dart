import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:ghost_box/theme/kawaii_theme.dart';
import 'package:ghost_box/screens/game_screen.dart';
import 'package:ghost_box/screens/home_screen.dart';

/// Victory screen: a happy ghost, a celebratory particle burst, the final
/// score, and replay / home actions.
class WinScreen extends StatefulWidget {
  final int score;
  final CameraDescription? camera;

  const WinScreen({super.key, required this.score, required this.camera});

  @override
  State<WinScreen> createState() => _WinScreenState();
}

class _WinScreenState extends State<WinScreen> with TickerProviderStateMixin {
  // Drives the one-shot-looking burst of 12 particles flying outward.
  late final AnimationController _burstCtrl;
  // Slow loop for the sparkle orbiting the ghost.
  late final AnimationController _sparkleCtrl;

  @override
  void initState() {
    super.initState();
    _burstCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
    _sparkleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _burstCtrl.dispose();
    _sparkleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      body: Container(
        // Win background gradient: deep purple -> bright purple.
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [KawaiiColors.bgDark, KawaiiColors.winEnd],
          ),
        ),
        child: SafeArea(
          child: Stack(
            fit: StackFit.expand,
            children: [
              // ---- Particle burst (centered) ----
              Center(
                child: AnimatedBuilder(
                  animation: _burstCtrl,
                  builder: (context, child) {
                    return Stack(
                      alignment: Alignment.center,
                      children: List.generate(12, (i) {
                        // 12 particles spread evenly around a full circle.
                        final angle = i * (2 * math.pi / 12);
                        // Particles travel out to ~42% of the shorter side.
                        final maxR = size.shortestSide * 0.42;
                        // Distance grows with the controller's progress.
                        final dist = _burstCtrl.value * maxR;
                        final colors = const [
                          KawaiiColors.primaryPink,
                          KawaiiColors.softLavender,
                          KawaiiColors.mintAccent,
                          KawaiiColors.boxGlow,
                        ];
                        return Align(
                          alignment: Alignment.center,
                          // Convert polar (angle, dist) to a cartesian offset.
                          child: Transform.translate(
                            offset: Offset(
                              math.cos(angle) * dist,
                              math.sin(angle) * dist,
                            ),
                            // Fade out as the particle reaches its max radius.
                            child: Opacity(
                              opacity: (1 - _burstCtrl.value).clamp(0.0, 1.0),
                              child: Container(
                                width: 14,
                                height: 14,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: colors[i % 4],
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    );
                  },
                ),
              ),

              // ---- Foreground content ----
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Happy ghost with a sparkle orbiting it.
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        const GhostImage(size: 120),
                        AnimatedBuilder(
                          animation: _sparkleCtrl,
                          builder: (context, child) {
                            // Sparkle orbits at radius 70 around the ghost.
                            final angle = _sparkleCtrl.value * 2 * math.pi;
                            return Transform.translate(
                              offset: Offset(
                                math.cos(angle) * 70,
                                math.sin(angle) * 70,
                              ),
                              child: child,
                            );
                          },
                          child: const Text(
                            '✨',
                            style: TextStyle(fontSize: 26),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'YOU DID IT! 💕',
                      textAlign: TextAlign.center,
                      style: kawaiiTitle(
                        fontSize: 44,
                        color: KawaiiColors.boxGlow,
                        shadowColor: KawaiiColors.primaryPink,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'The curse is sealed!',
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
                        fontSize: 56,
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
            ],
          ),
        ),
      ),
    );
  }
}
