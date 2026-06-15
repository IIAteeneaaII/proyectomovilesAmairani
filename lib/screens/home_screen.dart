import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import 'package:ghost_box/screens/game_screen.dart';
import 'package:ghost_box/screens/ar_probe_screen.dart';
import 'package:ghost_box/theme/kawaii_theme.dart';

/// Home / title screen. Shows the game name, a floating background ghost and a
/// pulsing START button that launches the [GameScreen].
class HomeScreen extends StatefulWidget {
  final CameraDescription? camera;

  const HomeScreen({super.key, required this.camera});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  // Single controller drives the gentle vertical bob of the background ghost.
  late final AnimationController _bobCtrl;

  @override
  void initState() {
    super.initState();
    _bobCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _bobCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    // Background ghost: ~40% of width, capped so it never dominates big screens.
    final ghostSize = math.min(size.width * 0.4, 150.0);
    // Title scales with width but is capped for tablets / landscape.
    final titleSize = math.min(size.width * 0.16, 64.0);

    return Scaffold(
      body: Container(
        // Vertical kawaii gradient backdrop (deep purple -> lighter purple).
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [KawaiiColors.bgDark, KawaiiColors.bgDark2],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // --- Floating background ghost (behind the content) ---
              Align(
                alignment: const Alignment(0, -0.45),
                child: AnimatedBuilder(
                  animation: _bobCtrl,
                  builder: (context, child) {
                    // Sine bob: value 0..1 -> 0..2pi so the ghost rises and
                    // falls smoothly by +/-14px over one full loop.
                    final dy = math.sin(_bobCtrl.value * 2 * math.pi) * 14;
                    return Transform.translate(
                      offset: Offset(0, dy),
                      child: child,
                    );
                  },
                  child: GhostImage(size: ghostSize, opacity: 0.6),
                ),
              ),

              // --- Foreground content ---
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'GHOST BOX',
                      textAlign: TextAlign.center,
                      style: kawaiiTitle(
                        fontSize: titleSize,
                        color: KawaiiColors.boxGlow,
                        shadowColor: KawaiiColors.primaryPink,
                      ),
                    ),
                    Text(
                      '✨ Cute Curse ✨',
                      textAlign: TextAlign.center,
                      style: kawaiiBody(
                        fontSize: 22,
                        color: KawaiiColors.softLavender,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'A cursed box appeared in your world...\n'
                      'only YOU can seal it! \u{1F47B}\u{1F495}',
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      style: kawaiiBody(
                        fontSize: 16,
                        color: KawaiiColors.warmWhite,
                      ),
                    ),
                    const SizedBox(height: 40),
                    KawaiiPillButton(
                      label: 'START',
                      pulse: true,
                      onTap: () => Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => GameScreen(camera: widget.camera),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Real-ARCore mode (anchors the box to a real surface).
                    KawaiiOutlinedButton(
                      label: '📦 Probar AR',
                      onTap: () => Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ArProbeScreen(camera: widget.camera),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // --- Bottom credit ---
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    'tap boo, seal the box, save the world \u{1F338}',
                    textAlign: TextAlign.center,
                    style: kawaiiBody(
                      fontSize: 13,
                      color: KawaiiColors.softLavender,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
