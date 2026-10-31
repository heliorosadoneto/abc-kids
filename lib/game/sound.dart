import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import '../theme/design_system.dart';

/// Contexto de áudio que NÃO pede foco no Android: efeitos e música tocam
/// juntos, sem um pausar o outro.
final AudioContext mixContext = AudioContext(
  android: const AudioContextAndroid(
    audioFocus: AndroidAudioFocus.none,
    usageType: AndroidUsageType.game,
    contentType: AndroidContentType.music,
    stayAwake: false,
    isSpeakerphoneOn: false,
  ),
  iOS: AudioContextIOS(category: AVAudioSessionCategory.ambient), // ambient já mistura com outros sons
);

/// Regra do "guardião" da música: deve voltar a tocar?
@visibleForTesting
bool shouldResumeMusic({required PlayerState state, required bool musicOn, required bool foreground}) =>
    musicOn && foreground && state != PlayerState.playing && state != PlayerState.disposed;

/// Áudio do jogo: efeitos curtos (pop, boing, fuga) e música de fundo contínua.
class GameSound {
  final _pop = AudioPlayer();
  final _boing = AudioPlayer();
  final _whoosh = AudioPlayer();
  final _music = AudioPlayer();
  bool effectsOn = true;
  bool musicOn = true;
  bool _bg = false;
  Timer? _guard;

  List<AudioPlayer> get _all => [_pop, _boing, _whoosh, _music];

  Future<void> init() async {
    await AudioPlayer.global.setAudioContext(mixContext);
    final cache = AudioCache(prefix: 'assets/audio/');
    await cache.loadAll(['pop.mp3', 'boing.mp3', 'whoosh.mp3', 'musica.ogg']);
    for (final p in _all) {
      p.audioCache = cache;
      await p.setAudioContext(mixContext);
    }
    for (final p in [_pop, _boing, _whoosh]) {
      await p.setReleaseMode(ReleaseMode.stop);
    }
    await _music.setReleaseMode(ReleaseMode.loop);
    await _music.setVolume(DS.musicVolume);
    // Se a música parar por qualquer motivo (foco, erro), volta sozinha.
    _music.onPlayerStateChanged.listen((_) => _keepMusic());
    _guard = Timer.periodic(const Duration(seconds: 2), (_) => _keepMusic());
    await _startMusic();
  }

  Future<void> _startMusic() async {
    if (!musicOn || _bg) return;
    await _music.setVolume(DS.musicVolume);
    await _music.play(AssetSource('musica.ogg'), volume: DS.musicVolume, ctx: mixContext);
  }

  void _keepMusic() {
    if (shouldResumeMusic(state: _music.state, musicOn: musicOn, foreground: !_bg)) {
      _music.state == PlayerState.paused ? _music.resume() : _startMusic();
    }
  }

  void _play(AudioPlayer p, String f) {
    if (!effectsOn) return;
    p.play(AssetSource(f), ctx: mixContext);
  }

  void pop() => _play(_pop, 'pop.mp3');
  void boing() => _play(_boing, 'boing.mp3');
  void whoosh() => _play(_whoosh, 'whoosh.mp3');

  Future<void> setMusic(bool on) async {
    musicOn = on;
    on ? await _startMusic() : await _music.pause();
  }

  void background(bool bg) {
    _bg = bg;
    if (bg) {
      _music.pause();
    } else {
      _keepMusic();
    }
  }

  void dispose() {
    _guard?.cancel();
    for (final p in _all) {
      p.dispose();
    }
  }
}
