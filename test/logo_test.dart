import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:letrinhas/logo.dart';

import 'shots_test.dart' show loadFonts;

Future<void> shot(WidgetTester t, Widget w, String path) async {
  await t.binding.setSurfaceSize(const Size(512, 512));
  t.view.physicalSize = const Size(512, 512);
  t.view.devicePixelRatio = 1;
  await t.pumpWidget(Directionality(textDirection: TextDirection.ltr, child: Align(alignment: Alignment.topLeft, child: RepaintBoundary(child: w))));
  await expectLater(find.byType(RepaintBoundary).first, matchesGoldenFile(path));
}

void main() {
  setUpAll(loadFonts);
  testWidgets('logo', (t) => shot(t, const LetrinhasLogo(), '../shots/logo.png'));
  testWidgets('logo quadrado', (t) => shot(t, const LetrinhasLogo(rounded: false), '../icon_src/full.png'));
  testWidgets('fundo', (t) => shot(t, const LetrinhasLogo(rounded: false, foreground: false), '../icon_src/bg.png'));
  // frente adaptativa: conteúdo reduzido para a zona segura (66%)
  testWidgets('frente', (t) => shot(t, const SizedBox(width: 512, height: 512, child: Center(child: LetrinhasLogo(size: 340, rounded: false, background: false))), '../icon_src/fg.png'));
}
