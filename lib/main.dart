import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'game/game_screen.dart';
import 'theme/design_system.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  WakelockPlus.enable();
  runApp(const LetrinhasApp());
}

class LetrinhasApp extends StatelessWidget {
  const LetrinhasApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'abc-kids',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(fontFamily: DS.fontFamily, colorSchemeSeed: DS.accent),
        home: const GameScreen(),
      );
}
