import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vector_math/vector_math_64.dart' as vmath;
import 'my_game.dart';

void main() {
  // Set the preferred orientations before running the app
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeRight,
    DeviceOrientation.landscapeLeft,
  ]).then((_) {
    // Set the app to full screen mode
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    runApp(MyApp());
  });
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: GestureDetector(
          onPanUpdate: (details) {
            // Convert Offset to Vector2 and update player position based on gesture
            MyGame.instance
                .movePlayer(vmath.Vector2(details.delta.dx, details.delta.dy));
          },
          child: RawKeyboardListener(
            focusNode: FocusNode(),
            autofocus: true,
            onKey: (RawKeyEvent event) {
              if (event is RawKeyDownEvent) {
                if (event.logicalKey == LogicalKeyboardKey.space) {
                  // Access the game instance and call shootFireball
                  MyGame.instance.shootFireball();
                }
              }
            },
            child: GameWidget(game: MyGame.instance),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            // Access the game instance and call shootFireball
            MyGame.instance.shootFireball();
          },
          child: Icon(Icons.fireplace), // You can use any icon you prefer
        ),
      ),
    );
  }
}
