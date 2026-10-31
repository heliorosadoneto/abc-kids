
import 'package:flutter/animation.dart';
import 'package:flutter/painting.dart';

/// Sistema de design central do Letrinhas.
class DS {
  DS._();

  // ---------- Tipografia ----------
  static const fontFamily = 'Fredoka'; // OFL, incluída em assets/fonts

  static TextStyle display(double size, {Color color = ink}) => TextStyle(
        fontFamily: fontFamily,
        fontSize: size,
        fontWeight: FontWeight.w700,
        color: color,
        height: 1.0,
      );

  // ---------- Paleta base ----------
  static const ink = Color(0xFF3A3357);
  static const white = Color(0xFFFFFFFF);
  static const skyTop = Color(0xFFBFE6FF);
  static const skyMid = Color(0xFFE6DBFF);
  static const skyBottom = Color(0xFFFFE3EE);
  static const cloud = Color(0xCCFFFFFF);
  static const bubble = Color(0x55FFFFFF);
  static const overlay = Color(0x993A3357);
  static const card = Color(0xFFFFFBF5);
  static const accent = Color(0xFFFF7EA8);

  static const skyGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [skyTop, skyMid, skyBottom],
    stops: [0, 0.55, 1],
  );

  /// Uma cor viva-mas-suave por letra (A..Z).
  static const letterColors = <Color>[
    Color(0xFFFF6B6B), Color(0xFFFFA94D), Color(0xFFFFD43B), Color(0xFF8CE99A),
    Color(0xFF4DD4AC), Color(0xFF66D9E8), Color(0xFF4DABF7), Color(0xFF748FFC),
    Color(0xFF9775FA), Color(0xFFDA77F2), Color(0xFFF783AC), Color(0xFFFF8787),
    Color(0xFFFFB86B), Color(0xFFC0EB75), Color(0xFF63E6BE), Color(0xFF3BC9DB),
    Color(0xFF5C9DFF), Color(0xFFB197FC), Color(0xFFE599F7), Color(0xFFFF922B),
    Color(0xFF94D82D), Color(0xFF20C997), Color(0xFF339AF0), Color(0xFF845EF7),
    Color(0xFFF06595), Color(0xFFFCC419),
  ];

  static Color letterColor(int i) => letterColors[i % letterColors.length];

  /// Versão clara (brilho) e escura (sombra/contorno) da cor da letra.
  static Color light(Color c) => Color.lerp(c, white, 0.55)!;
  static Color dark(Color c) =>
      Color.lerp(c, const Color(0xFF2B1F4A), 0.35)!;

  // ---------- Sombras ----------
  static const softShadowColor = Color(0x332B1F4A);
  static const softShadowOffset = Offset(0, 14);
  static const softShadowBlur = 18.0;

  // ---------- Animação ----------
  static const springIn = Curves.elasticOut;
  static const squish = Curves.easeOutBack;
  static const gentle = Curves.easeInOutSine;
  static const explodeHold = 1.6; // s: confete antes da próxima letra
  static const squishTime = 0.22; // s: espremida ao ser tocada
  static const hopTime = 0.75; // s: pulo para longe
  static const fleeTime = 0.9; // s: corrida de susto
  static const fleeSpeed = 1100.0; // px/s no início da fuga
  static const walkSpeed = 60.0; // px/s passeando
  static const hitRadius = 1.2; // área de toque em relação ao tamanho da letra
  static const hitOn = Color(0xFFFFC94D);
  static const hitOff = Color(0x55FFFFFF);
  static const musicVolume = 0.15;
  static const musicDucked = 0.04;
  static const explodeDuration = Duration(milliseconds: 1100);
  static const enterDuration = Duration(milliseconds: 1400);
  static const blinkDuration = Duration(milliseconds: 140);
  static const parentHold = Duration(milliseconds: 1500);

  // ---------- Partículas ----------
  static const particleCount = 70;
  static const particleGravity = 900.0; // px/s²
  static const particleShapes = ParticleShape.values;

  // ---------- Olhos ----------
  static const eyeWhite = white;
  static const eyeOutline = ink;
  static const pupil = Color(0xFF231C3A);
  static const eyeShine = white;
  static const eyeRatio = 0.13; // raio do olho em relação ao tamanho da letra
}

enum ParticleShape { circle, star, heart, square }
