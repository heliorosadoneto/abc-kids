import 'dart:math';

import 'package:flutter/material.dart';

import '../theme/design_system.dart';
import 'words.dart';

enum Phase { entering, walking, squish, exploding }

class Particle {
  Particle(this.pos, this.vel, this.color, this.shape, this.size, this.spin);
  Offset pos;
  Offset vel;
  final Color color;
  final ParticleShape shape;
  final double size;
  final double spin;
}

/// Estado puro da cena (sem timers) — facilita testes e screenshots.
class SceneState {
  int index = 0;
  Phase phase = Phase.entering;
  Offset pos = Offset.zero;
  Offset vel = const Offset(70, 50);
  double phaseT = 0; // segundos na fase atual
  double time = 0; // tempo global
  Offset look = Offset.zero; // direção do olhar (-1..1)
  double blink = 0; // 0 aberto, 1 fechado
  Offset enterFrom = Offset.zero;
  List<Particle> particles = [];
  Offset explodeAt = Offset.zero;

  LetterInfo get info => letters[index % letters.length];
  Color get color => DS.letterColor(index);
}

/// Pinta o céu com nuvens e bolhas flutuantes.
class SkyPainter extends CustomPainter {
  SkyPainter(this.t);
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final r = Offset.zero & size;
    canvas.drawRect(r, Paint()..shader = DS.skyGradient.createShader(r));
    final cloud = Paint()..color = DS.cloud;
    for (var i = 0; i < 4; i++) {
      final w = size.width;
      final x = ((i * 0.31 + t * 0.012 * (1 + i * 0.3)) % 1.3 - 0.15) * w;
      final y = size.height * (0.1 + i * 0.2);
      final s = 40.0 + i * 12;
      for (final o in [const Offset(0, 0), const Offset(1, -0.5), const Offset(2, 0), const Offset(1, 0.2)]) {
        canvas.drawCircle(Offset(x + o.dx * s * 0.8, y + o.dy * s * 0.8), s * 0.75, cloud);
      }
    }
    final b = Paint()..color = DS.bubble;
    final ring = Paint()
      ..color = DS.white.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (var i = 0; i < 9; i++) {
      final x = size.width * ((i * 0.137 + 0.05) % 1) + sin(t * 0.6 + i) * 12;
      final y = size.height * (1 - ((t * 0.03 + i * 0.113) % 1.1));
      final rr = 10.0 + (i % 4) * 8;
      canvas.drawCircle(Offset(x, y), rr, b);
      canvas.drawCircle(Offset(x, y), rr, ring);
      canvas.drawCircle(Offset(x - rr * 0.35, y - rr * 0.35), rr * 0.2, Paint()..color = DS.white.withValues(alpha: 0.8));
    }
  }

  @override
  bool shouldRepaint(SkyPainter old) => old.t != t;
}

/// Pinta a letra, olhos e partículas.
class LetterPainter extends CustomPainter {
  LetterPainter(this.s, this.letterSize);
  final SceneState s;
  final double letterSize;

  @override
  void paint(Canvas canvas, Size size) {
    if (s.phase != Phase.exploding || s.phaseT < 0.12) _drawLetter(canvas);
    _drawParticles(canvas);
    if (s.phase == Phase.exploding) _drawEmoji(canvas, size);
  }

  void _drawEmoji(Canvas canvas, Size size) {
    final t = (s.phaseT / 1.0).clamp(0.0, 1.0);
    final scale = DS.springIn.transform(t);
    final tp = TextPainter(
      text: TextSpan(text: letters[s.index % letters.length].emoji, style: TextStyle(fontSize: letterSize * 0.85 * scale, fontFamilyFallback: const ['NotoColorEmoji'])),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, s.explodeAt - Offset(tp.width / 2, tp.height / 2 + letterSize * 0.1));
  }

  void _drawLetter(Canvas canvas) {
    final c = s.color;
    // Squish / wobble
    double sx = 1, sy = 1, rot = 0, hop = 0;
    switch (s.phase) {
      case Phase.walking:
      case Phase.entering:
        final w = s.time * 7;
        rot = sin(w) * 0.08;
        hop = -sin(w).abs() * letterSize * 0.06;
        sy = 1 - sin(w).abs() * 0.04;
        sx = 1 + sin(w).abs() * 0.03;
      case Phase.squish:
        // espreme e pulsa enquanto a letra é falada
        final q = sin((s.phaseT / 0.32).clamp(0.0, 1.0) * pi) + 0.25 * sin(s.phaseT * 14).abs();
        sx = 1 + q * 0.28;
        sy = 1 - q * 0.25;
      case Phase.exploding:
        final g = 1 + s.phaseT * 3;
        sx = sy = g;
    }
    canvas.save();
    canvas.translate(s.pos.dx, s.pos.dy + hop);
    // sombra no chão
    canvas.drawOval(
      Rect.fromCenter(center: Offset(0, letterSize * 0.5 - hop), width: letterSize * 0.7, height: letterSize * 0.12),
      Paint()
        ..color = DS.softShadowColor
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    canvas.rotate(rot);
    canvas.scale(sx, sy);

    final style = DS.display(letterSize);
    TextPainter tp(Paint fg) => TextPainter(
          text: TextSpan(text: s.info.letter, style: style.copyWith(foreground: fg)),
          textDirection: TextDirection.ltr,
        )..layout();
    final base = tp(Paint());
    final o = Offset(-base.width / 2, -base.height / 2);
    final rect = o & Size(base.width, base.height);

    // sombra suave
    tp(Paint()
          ..color = DS.softShadowColor
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, DS.softShadowBlur / 2))
        .paint(canvas, o + const Offset(0, 10));
    // contorno escuro grosso
    tp(Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = letterSize * 0.07
          ..strokeJoin = StrokeJoin.round
          ..color = DS.dark(c))
        .paint(canvas, o);
    // corpo com degradê (efeito 3D)
    tp(Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [DS.light(c), c, DS.dark(c)],
            stops: const [0, 0.5, 1],
          ).createShader(rect))
        .paint(canvas, o);
    // brilho
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(rect.left, rect.top, rect.width, rect.height * 0.42));
    tp(Paint()..color = DS.white.withValues(alpha: 0.35)).paint(canvas, o + const Offset(-2, -3));
    canvas.restore();

    // No "B" os olhos ficam menores e no topo, sem tapar os buracos.
    final isB = s.info.letter == 'B';
    _drawEyes(canvas, isB ? Offset(-letterSize * 0.04, -letterSize * 0.27) : Offset(0, -letterSize * 0.05),
        ratio: isB ? DS.eyeRatio * 0.68 : DS.eyeRatio);
    canvas.restore();
  }

  void _drawEyes(Canvas canvas, Offset center, {double ratio = DS.eyeRatio}) {
    final r = letterSize * ratio;
    for (final dx in [-r * 1.15, r * 1.15]) {
      final c = center + Offset(dx, 0);
      canvas.drawCircle(c + const Offset(0, 3), r, Paint()..color = DS.softShadowColor);
      canvas.drawCircle(c, r, Paint()..color = DS.eyeWhite);
      canvas.drawCircle(
          c,
          r,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = r * 0.16
            ..color = DS.eyeOutline);
      final p = c + s.look * r * 0.7;
      canvas.drawCircle(p, r * 0.48, Paint()..color = DS.pupil);
      canvas.drawCircle(p + Offset(-r * 0.17, -r * 0.17), r * 0.16, Paint()..color = DS.eyeShine);
      if (s.blink > 0) {
        canvas.save();
        canvas.clipPath(Path()..addOval(Rect.fromCircle(center: c, radius: r)));
        canvas.drawRect(
            Rect.fromLTWH(c.dx - r, c.dy - r, r * 2, r * 2 * s.blink), Paint()..color = s.color);
        canvas.restore();
      }
    }
  }

  void _drawParticles(Canvas canvas) {
    final fade = (1 - s.phaseT / 1.1).clamp(0.0, 1.0);
    for (final p in s.particles) {
      final paint = Paint()..color = p.color.withValues(alpha: fade);
      canvas.save();
      canvas.translate(p.pos.dx, p.pos.dy);
      canvas.rotate(p.spin * s.phaseT);
      switch (p.shape) {
        case ParticleShape.circle:
          canvas.drawCircle(Offset.zero, p.size / 2, paint);
        case ParticleShape.square:
          canvas.drawRRect(
              RRect.fromRectAndRadius(Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.6),
                  const Radius.circular(3)),
              paint);
        case ParticleShape.star:
          canvas.drawPath(_star(p.size / 2), paint);
        case ParticleShape.heart:
          canvas.drawPath(_heart(p.size), paint);
      }
      canvas.restore();
    }
  }

  static Path _star(double r) {
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final rr = i.isEven ? r : r * 0.45;
      final a = -pi / 2 + i * pi / 5;
      final pt = Offset(cos(a) * rr, sin(a) * rr);
      i == 0 ? path.moveTo(pt.dx, pt.dy) : path.lineTo(pt.dx, pt.dy);
    }
    return path..close();
  }

  static Path _heart(double s) {
    final h = s / 2;
    return Path()
      ..moveTo(0, h * 0.8)
      ..cubicTo(-h * 1.4, -h * 0.2, -h * 0.5, -h * 1.2, 0, -h * 0.4)
      ..cubicTo(h * 0.5, -h * 1.2, h * 1.4, -h * 0.2, 0, h * 0.8)
      ..close();
  }

  @override
  bool shouldRepaint(LetterPainter old) => true;
}

/// Lógica da simulação (avança o estado por dt segundos).
class SceneLogic {
  SceneLogic(this.s, {int seed = 7}) : rnd = Random(seed);
  final SceneState s;
  final Random rnd;
  Size area = const Size(800, 400);
  double get letterSize => min(area.width, area.height) * 0.47;
  double _nextBlink = 2;
  double _nextLook = 1;
  Offset _lookTarget = Offset.zero;

  void startEnter() {
    s.phase = Phase.entering;
    s.phaseT = 0;
    s.particles = [];
    final half = letterSize * 0.6;
    final side = s.index % 4;
    s.enterFrom = switch (side) {
      0 => Offset(-half, area.height / 2),
      1 => Offset(area.width + half, area.height / 2),
      2 => Offset(area.width / 2, -half),
      _ => Offset(area.width / 2, area.height + half),
    };
    s.pos = s.enterFrom;
    final a = rnd.nextDouble() * pi * 2;
    s.vel = Offset(cos(a), sin(a)) * 60;
  }

  /// Retorna true se o toque acertou a letra.
  bool tap(Offset p) {
    if (s.phase != Phase.walking && s.phase != Phase.entering) return false;
    if ((p - s.pos).distance > letterSize * 1.35) return false;
    s.phase = Phase.squish;
    s.phaseT = 0;
    return true;
  }

  void explode() {
    s.phase = Phase.exploding;
    s.phaseT = 0;
    s.explodeAt = s.pos;
    s.particles = List.generate(DS.particleCount, (i) {
      final a = rnd.nextDouble() * pi * 2;
      final sp = 250 + rnd.nextDouble() * 550;
      return Particle(
        s.pos,
        Offset(cos(a), sin(a) - 0.4) * sp,
        DS.letterColor(rnd.nextInt(26)),
        DS.particleShapes[rnd.nextInt(DS.particleShapes.length)],
        12 + rnd.nextDouble() * 18,
        (rnd.nextDouble() - 0.5) * 10,
      );
    });
  }

  /// Avança. Retorna evento: 'pop' quando explode, 'next' quando nova letra entra.
  String? step(double dt) {
    s.time += dt;
    s.phaseT += dt;
    String? ev;
    // olhar e piscar
    _nextLook -= dt;
    if (_nextLook <= 0) {
      _lookTarget = Offset(rnd.nextDouble() * 2 - 1, rnd.nextDouble() * 2 - 1);
      _nextLook = 0.8 + rnd.nextDouble() * 1.5;
    }
    s.look = Offset.lerp(s.look, _lookTarget, min(1, dt * 6))!;
    _nextBlink -= dt;
    if (_nextBlink <= 0) {
      final bt = -_nextBlink;
      s.blink = bt < 0.07 ? bt / 0.07 : max(0, 1 - (bt - 0.07) / 0.07);
      if (bt > 0.14) {
        s.blink = 0;
        _nextBlink = 2 + rnd.nextDouble() * 3;
      }
    }
    switch (s.phase) {
      case Phase.entering:
        final t = (s.phaseT / (DS.enterDuration.inMilliseconds / 1000)).clamp(0.0, 1.0);
        final target = Offset(area.width / 2, area.height / 2);
        s.pos = Offset.lerp(s.enterFrom, target, Curves.easeOutCubic.transform(t))!;
        if (t >= 1) {
          s.phase = Phase.walking;
          s.phaseT = 0;
        }
      case Phase.walking:
        s.pos += s.vel * dt;
        final m = letterSize * 0.5;
        if (s.pos.dx < m || s.pos.dx > area.width - m) {
          s.vel = Offset(-s.vel.dx, s.vel.dy);
          s.pos = Offset(s.pos.dx.clamp(m, area.width - m), s.pos.dy);
        }
        if (s.pos.dy < m || s.pos.dy > area.height - m) {
          s.vel = Offset(s.vel.dx, -s.vel.dy);
          s.pos = Offset(s.pos.dx, s.pos.dy.clamp(m, area.height - m));
        }
      case Phase.squish:
        if (s.phaseT >= DS.squishDuration.inMilliseconds / 1000) {
          explode();
          ev = 'pop';
        }
      case Phase.exploding:
        for (final p in s.particles) {
          p.vel += const Offset(0, DS.particleGravity) * dt;
          p.pos += p.vel * dt;
        }
        if (s.phaseT >= DS.explodeHold) {
          s.index = (s.index + 1) % letters.length;
          startEnter();
          ev = 'next';
        }
    }
    return ev;
  }
}
