import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:letrinhas/game/game_screen.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:letrinhas/game/scene.dart';
import 'package:letrinhas/game/sound.dart';
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

  void settle(SceneLogic l, [int frames = 100]) {
    for (var i = 0; i < frames; i++) {
      l.step(1 / 60);
    }
  }

  test('lógica: erro foge, 2 acertos pulam, 3º explode e entra a próxima', () {
    final l = makeLogic();
    settle(l);
    expect(l.s.phase, Phase.walking);
    // erro: foge para longe do dedo e continua na tela
    final before = l.s.pos;
    final finger = before + Offset(l.letterSize * 1.5, 0);
    expect(l.tap(finger), 'miss');
    expect(l.s.phase, Phase.fleeing);
    settle(l, 20);
    expect((l.s.pos - finger).distance, greaterThan((before - finger).distance));
    settle(l, 80);
    expect(l.s.phase, Phase.walking);
    expect(l.s.pos.dx, inInclusiveRange(0, size.width));
    expect(l.s.pos.dy, inInclusiveRange(0, size.height));
    // 1º e 2º acerto: pula para longe
    for (var hit = 1; hit <= 2; hit++) {
      final p0 = l.s.pos;
      expect(l.tap(l.s.pos), 'boing');
      settle(l, 70);
      expect(l.s.phase, Phase.walking);
      expect(l.s.hits, hit);
      expect((l.s.pos - p0).distance, greaterThan(l.letterSize));
    }
    // 3º acerto: explode
    expect(l.tap(l.s.pos), 'hit');
    final events = <String>[];
    for (var i = 0; i < 200; i++) {
      final ev = l.step(1 / 60);
      if (ev != null) events.add(ev);
    }
    expect(events, ['pop', 'next']);
    expect(l.s.info.letter, 'B');
    expect(l.s.hits, 0);
  });

  test('toque abaixo da letra (onde ficavam as estrelas) é erro', () {
    final l = makeLogic();
    settle(l);
    expect(l.tap(l.s.pos + Offset(0, l.letterSize * 0.62)), 'miss');
  });

  test('acertos mudam a cor da letra', () {
    final l = makeLogic();
    settle(l);
    final c0 = l.s.color;
    l.tap(l.s.pos);
    settle(l, 70);
    final c1 = l.s.color;
    l.tap(l.s.pos);
    settle(l, 70);
    final c2 = l.s.color;
    expect({c0, c1, c2}.length, 3);
  });

  test('música volta se parar com o app aberto', () {
    for (final st in [PlayerState.paused, PlayerState.stopped, PlayerState.completed]) {
      expect(shouldResumeMusic(state: st, musicOn: true, foreground: true), isTrue);
    }
    expect(shouldResumeMusic(state: PlayerState.playing, musicOn: true, foreground: true), isFalse);
    expect(shouldResumeMusic(state: PlayerState.paused, musicOn: false, foreground: true), isFalse);
    expect(shouldResumeMusic(state: PlayerState.paused, musicOn: true, foreground: false), isFalse);
    expect(mixContext.android.audioFocus, AndroidAudioFocus.none);
  });

  testWidgets('shot 1: A andando', (t) async {
    final l = makeLogic();
    settle(l, 150);
    l.s.look = const Offset(0.7, -0.4);
    l.s.hits = 1;
    await pumpScene(t, l);
    await expectLater(find.byType(GameScreen), matchesGoldenFile('../shots/01_letra_A_andando.png'));
  });

  testWidgets('shot 2: explosão', (t) async {
    final l = makeLogic();
    settle(l, 120);
    l.s.hits = 2;
    l.tap(l.s.pos);
    settle(l, 14 + 20);
    await pumpScene(t, l);
    await expectLater(find.byType(GameScreen), matchesGoldenFile('../shots/02_explosao_confete.png'));
  });

  testWidgets('shot 3: B entrando', (t) async {
    final l = makeLogic();
    l.s.index = 1;
    l.startEnter();
    settle(l, 30);
    l.s.look = const Offset(-0.8, 0);
    await pumpScene(t, l);
    await expectLater(find.byType(GameScreen), matchesGoldenFile('../shots/03_letra_B_entrando.png'));
  });

  testWidgets('shot 5: A fugindo assustada', (t) async {
    final l = makeLogic();
    settle(l, 120);
    l.tap(l.s.pos + Offset(l.letterSize * 1.4, l.letterSize * 0.3));
    settle(l, 10);
    await pumpScene(t, l);
    await expectLater(find.byType(GameScreen), matchesGoldenFile('../shots/05_letra_fugindo.png'));
  });

  testWidgets('shot 6: A pulando', (t) async {
    final l = makeLogic();
    settle(l, 120);
    l.tap(l.s.pos);
    settle(l, 14 + 20);
    await pumpScene(t, l);
    await expectLater(find.byType(GameScreen), matchesGoldenFile('../shots/06_letra_pulando.png'));
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
