import 'package:arcore_flutter_plugin/arcore_flutter_plugin.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as vmath;

import 'package:ghost_box/screens/home_screen.dart';
import 'package:ghost_box/theme/kawaii_theme.dart';

/// Minimal ARCore runtime probe.
///
/// Goal: confirm REAL ARCore actually runs on the device before we rebuild the
/// whole game in 3D. It shows ARCore's live plane detection (the real grid the
/// professor wants) and lets you tap a detected surface (your table) to anchor
/// a glowing 3D cube — the cursed box — to the real world.
class ArProbeScreen extends StatefulWidget {
  final CameraDescription? camera;

  const ArProbeScreen({super.key, required this.camera});

  @override
  State<ArProbeScreen> createState() => _ArProbeScreenState();
}

class _ArProbeScreenState extends State<ArProbeScreen> {
  ArCoreController? _arController;
  int _placed = 0;
  bool _planeFound = false;
  String _status = 'Mueve el celular despacio apuntando a tu mesa…';

  void _onArCoreViewCreated(ArCoreController controller) {
    _arController = controller;
    controller.onPlaneTap = _onPlaneTap;
    controller.onNodeTap = _onNodeTap;
    // Fires while ARCore is tracking surfaces -> proof the grid is live.
    controller.onPlaneDetected = (ArCorePlane plane) {
      if (!mounted || _planeFound) return;
      setState(() {
        _planeFound = true;
        _status = '✨ ¡Superficie detectada! Toca tu mesa para poner la caja 📦';
      });
    };
  }

  /// Tapped a detected plane: anchor a cube to the real-world hit pose.
  void _onPlaneTap(List<ArCoreHitTestResult> hits) {
    if (hits.isEmpty) return;
    final hit = hits.first;

    // A glowing gold cube ~15cm — stands in for the cursed box.
    final material = ArCoreMaterial(
      color: const Color(0xFFFFE066),
      reflectance: 0.5,
      roughness: 0.3,
    );
    final cube = ArCoreCube(
      materials: [material],
      size: vmath.Vector3(0.15, 0.15, 0.15),
    );
    final node = ArCoreNode(
      shape: cube,
      // hit.pose gives the real-world position/orientation on the surface.
      position: hit.pose.translation,
      rotation: hit.pose.rotation,
      name: 'caja_$_placed',
    );
    _arController?.addArCoreNodeWithAnchor(node);

    setState(() {
      _placed++;
      _status = 'Caja anclada a tu mesa ✅  (tócala, o pon otra)';
    });
  }

  void _onNodeTap(String name) {
    if (!mounted) return;
    setState(() => _status = '¡Tocaste la caja! 👻 ($name)');
  }

  @override
  void dispose() {
    _arController?.dispose();
    super.dispose();
  }

  void _goHome() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => HomeScreen(camera: widget.camera)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KawaiiColors.bgDark,
      body: Stack(
        children: [
          // Real ARCore view: camera feed + plane-detection dots (the grid).
          ArCoreView(
            onArCoreViewCreated: _onArCoreViewCreated,
            enableTapRecognizer: true,
            enableUpdateListener: true,
            enablePlaneRenderer: true,
          ),

          // Status card (top).
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: KawaiiColors.bgDark.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: KawaiiColors.softLavender.withValues(alpha: 0.4),
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    _status,
                    textAlign: TextAlign.center,
                    style: kawaiiBody(
                      fontSize: 15,
                      color: KawaiiColors.warmWhite,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Back to home (bottom).
          Positioned(
            left: 0,
            right: 0,
            bottom: 24,
            child: Center(
              child: KawaiiOutlinedButton(label: 'VOLVER', onTap: _goHome),
            ),
          ),
        ],
      ),
    );
  }
}
