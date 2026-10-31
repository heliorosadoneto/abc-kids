import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../parent_gate.dart';
import '../theme/design_system.dart';
import 'scene.dart';
import 'sound.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key, this.logic, this.animate = true, this.audio = true});
  final SceneLogic? logic;
  final bool animate;
  final bool audio;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final SceneLogic logic = widget.logic ?? SceneLogic(SceneState());
  Ticker? _ticker;
  Duration _last = Duration.zero;
  bool _started = false;
  bool paused = false;
  GameSound? sound;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.audio) {
      sound = GameSound()..init();
    }
    if (widget.animate) {
      _ticker = createTicker(_tick)..start();
    }
  }

  void _tick(Duration d) {
    final dt = ((d - _last).inMicroseconds / 1e6).clamp(0.0, 0.05);
    _last = d;
    if (paused) return;
    final ev = logic.step(dt);
    if (ev == 'pop') sound?.pop();
    setState(() {});
  }

  void _onTap(TapDownDetails d) {
    if (paused) return;
    switch (logic.tap(d.localPosition)) {
      case 'boing':
        sound?.boing();
      case 'miss':
        sound?.whoosh();
    }
  }

  Future<void> _parentFlow() async {
    paused = true;
    final ok = await showDialog<bool>(
        context: context, barrierDismissible: false, barrierColor: DS.overlay, builder: (_) => const ParentGateDialog());
    if (ok == true && mounted) {
      final act = await showDialog<ParentAction>(
          context: context,
          barrierDismissible: false,
          barrierColor: DS.overlay,
          builder: (_) => ParentMenu(
                soundOn: sound?.effectsOn ?? true,
                onSound: (v) => sound?.effectsOn = v,
                musicOn: sound?.musicOn ?? true,
                onMusic: (v) => sound?.setMusic(v),
              ));
      if (act == ParentAction.exit) {
        await SystemNavigator.pop();
      }
    }
    paused = false;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    sound?.background(state != AppLifecycleState.resumed);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.dispose();
    sound?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: LayoutBuilder(builder: (context, c) {
          logic.area = c.biggest;
          if (!_started && widget.logic == null) {
            _started = true;
            logic.startEnter();
          }
          return Stack(children: [
            Positioned.fill(
              child: RawGestureDetector(
                behavior: HitTestBehavior.opaque,
                gestures: {
                  // Um dedo de cada vez: multitoque caótico é ignorado.
                  _SingleTap: GestureRecognizerFactoryWithHandlers<_SingleTap>(
                    () => _SingleTap(),
                    (r) => r.onTapDown = _onTap,
                  ),
                },
                child: RepaintBoundary(
                  child: CustomPaint(
                    painter: SkyPainter(logic.s.time),
                    foregroundPainter: LetterPainter(logic.s, logic.letterSize),
                    size: Size.infinite,
                  ),
                ),
              ),
            ),
            Positioned(top: 4, right: 4, child: ParentLock(onUnlocked: _parentFlow)),
          ]);
        }),
      ),
    );
  }
}

class _SingleTap extends TapGestureRecognizer {
  int? _active;
  @override
  void addAllowedPointer(PointerDownEvent event) {
    if (_active != null) return;
    _active = event.pointer;
    super.addAllowedPointer(event);
  }

  @override
  void didStopTrackingLastPointer(int pointer) {
    _active = null;
    super.didStopTrackingLastPointer(pointer);
  }
}
