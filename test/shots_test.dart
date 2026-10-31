import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:letrinhas/game/game_screen.dart';
import 'package:letrinhas/game/scene.dart';
import 'package:letrinhas/parent_gate.dart';
import 'package:letrinhas/theme/design_system.dart';

Future<void> loadFonts() async {
  final f = FontLoader(DS.fontFamily)
    ..addFont(Future.value(ByteData.sublistView(File('assets/fonts/Fredoka.ttf').readAsBytesSync())));
  await f.load();
  final icons = File('${Platform.environment['HOME']}/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf');
  final m = FontLoader('MaterialIcons')..addFont(Future.value(ByteData.sublistView(icons.readAsBytesSync())));
  await m.load();
  final emoji = File('/usr/share/fonts/truetype/noto/NotoColorEmoji.ttf');
  if (emoji.existsSync()) {
    final e = FontLoader('NotoColorEmoji')..addFont(Future.value(ByteData.sublistView(emoji.readAsBytesSync())));
    await e.load();
  }
}

const size = Size(1600, 720); // paisagem ~ moto g9 plus

SceneLogic makeLogic() {
  final l = SceneLogic(SceneState(), seed: 3)..area = size;
  l.startEnter();
  return l;
}

Future<void> pumpScene(WidgetTester t, SceneLogic l) async {
  await t.binding.setSurfaceSize(size);
  t.view.physicalSize = size;
  t.view.devicePixelRatio = 1;
  await t.pumpWidget(MaterialApp(
      debugShowCheckedModeBanner: false,
      home: GameScreen(logic: l, animate: false, audio: false)));
}

void main() {
  setUpAll(loadFonts);

  test('lógica: toque acerta, explode e entra a próxima letra', () {
    final l = makeLogic();
    for (var i = 0; i < 100; i++) {
      l.step(1 / 60);
    }
    expect(l.s.phase, Phase.walking);
    expect(l.tap(l.s.pos + const Offset(2000, 0)), isFalse);
    expect(l.tap(l.s.pos + Offset(l.letterSize * 0.6, 0)), isTrue);
    String? ev;
    final events = <String>[];
    for (var i = 0; i < 300; i++) {
      ev = l.step(1 / 60);
      if (ev != null) events.add(ev);
    }
    expect(events, ['pop', 'next']);
    expect(l.s.info.letter, 'B');
  });

  testWidgets('shot 1: A andando', (t) async {
    final l = makeLogic();
    for (var i = 0; i < 150; i++) {
      l.step(1 / 60);
    }
    l.s.look = const Offset(0.7, -0.4);
    await pumpScene(t, l);
    await expectLater(find.byType(GameScreen), matchesGoldenFile('../shots/01_letra_A_andando.png'));
  });

  testWidgets('shot 2: explosão', (t) async {
    final l = makeLogic();
    for (var i = 0; i < 120; i++) {
      l.step(1 / 60);
    }
    l.tap(l.s.pos);
    for (var i = 0; i < 66 + 22; i++) {
      l.step(1 / 60);
    }
    await pumpScene(t, l);
    await expectLater(find.byType(GameScreen), matchesGoldenFile('../shots/02_explosao_confete.png'));
  });

  testWidgets('shot 3: B entrando', (t) async {
    final l = makeLogic();
    l.s.index = 1;
    l.startEnter();
    for (var i = 0; i < 30; i++) {
      l.step(1 / 60);
    }
    l.s.look = const Offset(-0.8, 0);
    await pumpScene(t, l);
    await expectLater(find.byType(GameScreen), matchesGoldenFile('../shots/03_letra_B_entrando.png'));
  });

  testWidgets('shot 4: porta dos pais', (t) async {
    final l = makeLogic();
    for (var i = 0; i < 150; i++) {
      l.step(1 / 60);
    }
    await pumpScene(t, l);
    await t.pumpWidget(MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Stack(children: [
        GameScreen(logic: l, animate: false, audio: false),
        const Positioned.fill(child: ColoredBox(color: DS.overlay)),
        const ParentGateDialog(seed: 1),
        Positioned(top: 4, right: 4, child: ParentLock(onUnlocked: () {}, debugProgress: 1)),
      ]),
    ));
    await expectLater(find.byType(Stack).first, matchesGoldenFile('../shots/04_porta_dos_pais.png'));
  });

  testWidgets('toque curto no cadeado não abre nada', (t) async {
    var opened = false;
    await t.pumpWidget(MaterialApp(home: Scaffold(body: ParentLock(onUnlocked: () => opened = true))));
    await t.tap(find.byType(ParentLock));
    await t.pump(const Duration(seconds: 4));
    expect(opened, isFalse);
    // segurar 1 s ainda não abre
    final g0 = await t.startGesture(t.getCenter(find.byType(ParentLock)));
    for (var i = 0; i < 10; i++) {
      await t.pump(const Duration(milliseconds: 100));
    }
    await g0.up();
    await t.pump(const Duration(seconds: 2));
    expect(opened, isFalse);
    final g = await t.startGesture(t.getCenter(find.byType(ParentLock)));
    for (var i = 0; i < 20; i++) {
      await t.pump(const Duration(milliseconds: 100));
    }
    expect(opened, isTrue);
    await g.up();
  });
}
