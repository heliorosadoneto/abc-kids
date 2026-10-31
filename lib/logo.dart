import 'package:flutter/material.dart';

import 'game/scene.dart';
import 'theme/design_system.dart';

/// Logo do app: "ABC" brilhante com olhinhos.
class LetrinhasLogo extends StatelessWidget {
  const LetrinhasLogo({super.key, this.size = 512, this.background = true, this.foreground = true, this.rounded = true});
  final double size;
  final bool background, foreground, rounded;

  SceneState _st(int i, Offset pos, Offset look) => SceneState()
    ..index = i
    ..phase = Phase.walking
    ..showHits = false
    ..phaseT = 0
    ..pos = pos
    ..look = look;

  @override
  Widget build(BuildContext context) {
    final s = size;
    Widget content = Stack(children: [
      if (background) ...[
        Positioned.fill(child: CustomPaint(painter: SkyPainter(3))),
      ],
      if (foreground) ...[
        Positioned.fill(child: CustomPaint(painter: LetterPainter(_st(2, Offset(s * 0.77, s * 0.52), const Offset(-0.6, -0.3)), s * 0.40))),
        Positioned.fill(child: CustomPaint(painter: LetterPainter(_st(1, Offset(s * 0.51, s * 0.50), const Offset(0, -0.5)), s * 0.40))),
        Positioned.fill(child: CustomPaint(painter: LetterPainter(_st(0, Offset(s * 0.25, s * 0.52), const Offset(0.6, -0.3)), s * 0.40))),
        Positioned.fill(child: CustomPaint(painter: _Dots(s))),
      ],
    ]);
    if (rounded) content = ClipRRect(borderRadius: BorderRadius.circular(s * 0.22), child: content);
    return SizedBox(width: s, height: s, child: content);
  }
}

class _Dots extends CustomPainter {
  _Dots(this.s);
  final double s;
  @override
  void paint(Canvas canvas, Size size) {
    const dots = [(0.18, 0.18, 2), (0.84, 0.20, 5), (0.14, 0.84, 9), (0.86, 0.84, 13), (0.52, 0.14, 22), (0.50, 0.88, 17)];
    for (final (x, y, c) in dots) {
      canvas.drawCircle(Offset(x * s, y * s), s * 0.028, Paint()..color = DS.letterColor(c));
      canvas.drawCircle(Offset((x - 0.008) * s, (y - 0.008) * s), s * 0.008, Paint()..color = DS.white.withValues(alpha: 0.7));
    }
  }

  @override
  bool shouldRepaint(_Dots old) => false;
}
