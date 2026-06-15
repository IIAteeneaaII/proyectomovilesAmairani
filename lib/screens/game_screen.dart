import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import 'package:ghost_box/theme/kawaii_theme.dart';
import 'package:ghost_box/game/game_controller.dart';
import 'package:ghost_box/widgets/boo_widget.dart';
import 'package:ghost_box/widgets/cursed_box_widget.dart';
import 'package:ghost_box/widgets/hud_widget.dart';
import 'package:ghost_box/screens/win_screen.dart';
import 'package:ghost_box/screens/lose_screen.dart';

/// The main gameplay screen: live camera feed behind a layer of kawaii
/// elements (the cursed box, floating Boos, HUD). All rules live in
/// [GameController]; this screen only wires the camera, listens for the
/// game-over transition, and renders.
class GameScreen extends StatefulWidget {
  final CameraDescription? camera;

  const GameScreen({super.key, required this.camera});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with WidgetsBindingObserver {
  late final GameController controller;
  CameraController? _camController;
  bool _cameraReady = false;
  bool _cameraError = false;
  bool _initializing = false;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    controller = GameController();
    controller.addListener(_onGameChange);
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  /// Bring the camera up. On success, start the game (once).
  Future<void> _initCamera() async {
    if (widget.camera == null) {
      setState(() {
        _cameraError = true;
      });
      return;
    }
    setState(() {
      _initializing = true;
      _cameraError = false;
    });
    try {
      final c = CameraController(
        widget.camera!,
        ResolutionPreset.high,
        enableAudio: false,
      );
      await c.initialize();
      _camController = c;
      if (!mounted) return;
      setState(() {
        _cameraReady = true;
        _initializing = false;
      });
      if (!controller.isRunning && !controller.isOver) controller.start();
    } on CameraException catch (_) {
      if (!mounted) return;
      setState(() {
        _cameraError = true;
        _initializing = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _cameraError = true;
        _initializing = false;
      });
    }
  }

  /// Reacts to controller notifications: when the game ends, navigate once.
  void _onGameChange() {
    if (controller.isOver && !_navigated && mounted) {
      _navigated = true;
      final win = controller.isWin;
      final score = controller.score;
      // Navigate after the current frame so we never push during a
      // notifyListeners() (i.e. mid-build).
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => win
                ? WinScreen(score: score, camera: widget.camera)
                : LoseScreen(score: score, camera: widget.camera),
          ),
        );
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Camera + game-clock lifecycle. Handle resume FIRST and unconditionally:
    // the camera was disposed (and nulled) on background, so a guard on a
    // non-null controller would make this branch dead code.
    if (state == AppLifecycleState.resumed) {
      controller.resume(); // un-pause the countdown (no-op if game is over)
      if (!_cameraError && _camController == null) _initCamera();
      return;
    }
    // Backgrounded: pause the clock so time can't drain while hidden, and
    // release the camera. inactive/paused/hidden are all "not visible".
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      controller.pause();
      final cam = _camController;
      if (cam != null) {
        cam.dispose();
        // setState so build drops to the "warming up" branch instead of
        // painting a now-disposed camera texture.
        if (mounted) {
          setState(() {
            _camController = null;
            _cameraReady = false;
          });
        } else {
          _camController = null;
          _cameraReady = false;
        }
      }
    }
  }

  /// Retry button on the error card.
  void _retry() {
    setState(() {
      _cameraError = false;
      _cameraReady = false;
    });
    _initCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    controller.removeListener(_onGameChange);
    controller.dispose();
    _camController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    // ---- Camera permission / hardware error: cute error card ----
    if (_cameraError) {
      return Scaffold(
        backgroundColor: KawaiiColors.bgDark,
        body: Center(
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: size.width * 0.1),
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
            decoration: BoxDecoration(
              color: KawaiiColors.bgDark2,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: KawaiiColors.softLavender, width: 2),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('👻', style: kawaiiTitle(fontSize: 64)),
                const SizedBox(height: 16),
                Text(
                  "Boo can't see you! 👻\nCamera permission needed",
                  textAlign: TextAlign.center,
                  style: kawaiiBody(
                    fontSize: 18,
                    color: KawaiiColors.softLavender,
                  ),
                ),
                const SizedBox(height: 28),
                KawaiiPillButton(label: 'RETRY', onTap: _retry),
              ],
            ),
          ),
        ),
      );
    }

    // ---- Camera still warming up ----
    if (_initializing || !_cameraReady || _camController == null) {
      return Scaffold(
        backgroundColor: KawaiiColors.bgDark,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                valueColor:
                    AlwaysStoppedAnimation<Color>(KawaiiColors.primaryPink),
              ),
              const SizedBox(height: 20),
              Text(
                'Summoning Boo...',
                style: kawaiiBody(
                  fontSize: 18,
                  color: KawaiiColors.softLavender,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // ---- Live gameplay ----
    // The sensor is landscape while the app is portrait, so previewSize's
    // width/height are swapped relative to the screen. Feeding the swapped
    // values into a FittedBox(cover) makes the feed fill the screen without
    // stretching.
    final preview = _camController!.value.previewSize;
    final previewW = preview?.height ?? size.width;
    final previewH = preview?.width ?? size.height;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Camera preview, scaled to cover the whole screen.
          SizedBox.expand(
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: previewW,
                height: previewH,
                child: CameraPreview(_camController!),
              ),
            ),
          ),

          // Subtle dark wash so the bright kawaii elements pop; ignores
          // pointers so taps reach the box / Boos beneath it.
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                color: KawaiiColors.bgDark.withValues(alpha: 0.25),
              ),
            ),
          ),

          // The interactive kawaii layer, rebuilt on every game change.
          Positioned.fill(
            child: ListenableBuilder(
              listenable: controller,
              builder: (context, _) => Stack(
                children: [
                  Center(
                    child: CursedBoxWidget(
                      sealProgress: controller.sealProgress,
                      onTapBox: controller.tapBox,
                    ),
                  ),
                  // One BooWidget per active Boo; stable keys so existing
                  // Boos keep their own animation state as new ones spawn.
                  ...List.generate(
                    controller.booCount,
                    (i) => BooWidget(
                      key: ValueKey('boo_$i'),
                      onTapBoo: controller.tapBoo,
                    ),
                  ),
                  if (controller.showCombo)
                    Align(
                      alignment: const Alignment(0, -0.45),
                      child: IgnorePointer(
                        child: Text(
                          'COMBO x2! 💕',
                          style: kawaiiTitle(
                            fontSize: 30,
                            color: KawaiiColors.primaryPink,
                            shadowColor: KawaiiColors.boxGlow,
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: HudWidget(
                          score: controller.score,
                          timeLeft: controller.timeLeft,
                          multiplier: controller.multiplier,
                          maxTime: GameController.gameDurationSeconds,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
