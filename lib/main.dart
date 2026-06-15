import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:ghost_box/screens/home_screen.dart';
import 'package:ghost_box/theme/kawaii_theme.dart';

/// App entry point.
///
/// We grab the first available camera up front so it can be threaded down to
/// every screen (Home/Game/Win/Lose) for the AR feed. `availableCameras` is
/// wrapped in a try/catch so emulators / devices without a camera still launch
/// — `camera` simply stays null and [GameScreen] shows its own error card.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Kawaii-horror is designed for one-handed vertical play: lock to portrait.
  await SystemChrome.setPreferredOrientations(
    const [DeviceOrientation.portraitUp],
  );

  CameraDescription? camera;
  try {
    final cams = await availableCameras();
    if (cams.isNotEmpty) camera = cams.first;
  } catch (_) {
    camera = null;
  }

  runApp(GhostBoxApp(camera: camera));
}

/// Root widget. Holds the (possibly null) camera and wires up the dark
/// kawaii-horror theme before handing off to [HomeScreen].
class GhostBoxApp extends StatelessWidget {
  final CameraDescription? camera;

  const GhostBoxApp({super.key, required this.camera});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'GHOST BOX',
      theme: ThemeData(
        scaffoldBackgroundColor: KawaiiColors.bgDark,
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      home: HomeScreen(camera: camera),
    );
  }
}
