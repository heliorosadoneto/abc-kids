import 'dart:async';

import 'package:audioplayers/audioplayers.dart';

import '../theme/design_system.dart';

/// Áudio do jogo: vozes, efeitos e música de fundo com "ducking".
class GameSound {
  final _voice = AudioPlayer();
  final _word = AudioPlayer();
  final _fx = AudioPlayer();
  final _pop = AudioPlayer();
  final _music = AudioPlayer();
  bool soundOn = true;
  bool musicOn = true;
  bool _bg = false;
  Timer? _fade, _restore;
  double _vol = DS.musicVolume;

  Future<void> init(List<String> letters) async {
    final cache = AudioCache(prefix: 'assets/audio/');
    await cache.loadAll([
      'pop.mp3', 'efeito_A.mp3', 'musica.ogg',
      for (final l in letters) ...['letra_$l.mp3', 'palavra_$l.mp3'],
    ]);
    for (final p in [_voice, _word, _fx, _pop, _music]) {
      p.audioCache = cache;
    }
    await _pop.setPlayerMode(PlayerMode.lowLatency);
    await _music.setReleaseMode(ReleaseMode.loop);
    await _music.setVolume(_vol);
    if (musicOn) await _music.play(AssetSource('musica.ogg'), volume: _vol);
  }

  void _fadeTo(double target, Duration d) {
    _fade?.cancel();
    final start = _vol;
    const steps = 12;
    var i = 0;
    _fade = Timer.periodic(d ~/ steps, (t) {
      i++;
      _vol = start + (target - start) * (i / steps);
      _music.setVolume(_vol);
      if (i >= steps) t.cancel();
    });
  }

  void _duck(Duration hold) {
    _restore?.cancel();
    _fadeTo(DS.musicDucked, const Duration(milliseconds: 180));
    _restore = Timer(hold, () => _fadeTo(DS.musicVolume, const Duration(milliseconds: 900)));
  }

  void letter(String l) {
    if (!soundOn) return;
    _duck(const Duration(milliseconds: 4200));
    _voice.play(AssetSource('letra_$l.mp3'));
  }

  void explode(String l) {
    if (!soundOn) return;
    _pop.play(AssetSource('pop.mp3'));
    Timer(const Duration(milliseconds: 350), () {
      _word.play(AssetSource('palavra_$l.mp3'));
      if (l == 'A') _fx.play(AssetSource('efeito_A.mp3'), volume: 0.5);
    });
  }

  Future<void> setMusic(bool on) async {
    musicOn = on;
    if (on && !_bg) {
      await _music.play(AssetSource('musica.ogg'), volume: _vol);
    } else {
      await _music.pause();
    }
  }

  void background(bool bg) {
    _bg = bg;
    if (bg) {
      _music.pause();
      _voice.stop();
      _word.stop();
    } else if (musicOn) {
      _music.resume();
    }
  }

  void dispose() {
    _fade?.cancel();
    _restore?.cancel();
    for (final p in [_voice, _word, _fx, _pop, _music]) {
      p.dispose();
    }
  }
}
