import 'dart:async';

import 'package:audioplayers/audioplayers.dart';

import '../theme/design_system.dart';

/// Áudio do jogo: efeitos (pop, boing, fuga) e música de fundo.
class GameSound {
  final _pop = AudioPlayer();
  final _boing = AudioPlayer();
  final _whoosh = AudioPlayer();
  final _music = AudioPlayer();
  bool effectsOn = true;
  bool musicOn = true;
  bool _bg = false;
  Timer? _fade, _restore;
  double _vol = DS.musicVolume;

  List<AudioPlayer> get _all => [_pop, _boing, _whoosh, _music];

  Future<void> init() async {
    final cache = AudioCache(prefix: 'assets/audio/');
    await cache.loadAll(['pop.mp3', 'boing.mp3', 'whoosh.mp3', 'musica.ogg']);
    for (final p in _all) {
      p.audioCache = cache;
    }
    for (final p in [_pop, _boing, _whoosh]) {
      await p.setPlayerMode(PlayerMode.lowLatency);
    }
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

  /// Abaixa a música um instante para o efeito aparecer.
  void _duck() {
    _restore?.cancel();
    _fadeTo(DS.musicDucked, const Duration(milliseconds: 120));
    _restore = Timer(const Duration(milliseconds: 900), () => _fadeTo(DS.musicVolume, const Duration(milliseconds: 800)));
  }

  void _play(AudioPlayer p, String f) {
    if (!effectsOn) return;
    _duck();
    p.play(AssetSource(f));
  }

  void pop() => _play(_pop, 'pop.mp3');
  void boing() => _play(_boing, 'boing.mp3');
  void whoosh() => _play(_whoosh, 'whoosh.mp3');

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
    } else if (musicOn) {
      _music.resume();
    }
  }

  void dispose() {
    _fade?.cancel();
    _restore?.cancel();
    for (final p in _all) {
      p.dispose();
    }
  }
}
