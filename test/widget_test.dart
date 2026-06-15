// Smoke test for GHOST BOX. Builds the real root widget with no camera
// (as on a device that denies/has no camera) and verifies the home screen
// renders its title.

import 'package:flutter_test/flutter_test.dart';

import 'package:ghost_box/main.dart';

void main() {
  testWidgets('Home screen shows the GHOST BOX title', (tester) async {
    // camera: null -> emulator / permission-denied path; the app still boots
    // to HomeScreen.
    await tester.pumpWidget(const GhostBoxApp(camera: null));
    await tester.pump();

    expect(find.text('GHOST BOX'), findsOneWidget);
    expect(find.text('✨ Cute Curse ✨'), findsOneWidget);
  });
}
