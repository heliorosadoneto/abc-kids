import 'dart:math';

import 'package:flutter/material.dart';

import 'theme/design_system.dart';

/// Cadeado no canto: só abre com toque longo de 1,5 s (anel enchendo).
class ParentLock extends StatefulWidget {
  const ParentLock({super.key, required this.onUnlocked, this.debugProgress});
  final VoidCallback onUnlocked;
  final double? debugProgress;

  @override
  State<ParentLock> createState() => _ParentLockState();
}

class _ParentLockState extends State<ParentLock> with SingleTickerProviderStateMixin {
  late final AnimationController c = AnimationController(vsync: this, duration: DS.parentHold)
    ..addStatusListener((st) {
      if (st == AnimationStatus.completed) {
        c.value = 0;
        widget.onUnlocked();
      }
    });

  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => c.forward(from: 0),
      onTapUp: (_) => c.reverse(),
      onTapCancel: () => c.reverse(),
      child: SizedBox(
        width: 64,
        height: 64,
        child: AnimatedBuilder(
          animation: c,
          builder: (_, _) {
            final v = widget.debugProgress ?? c.value;
            return Stack(alignment: Alignment.center, children: [
              SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  value: v,
                  strokeWidth: 4,
                  color: DS.accent,
                  backgroundColor: v > 0 ? DS.white.withValues(alpha: 0.4) : Colors.transparent,
                ),
              ),
              Icon(Icons.lock_rounded, size: 20, color: DS.ink.withValues(alpha: v > 0 ? 0.8 : 0.25)),
            ]);
          },
        ),
      ),
    );
  }
}

/// Desafio de soma para adultos.
class ParentGateDialog extends StatefulWidget {
  const ParentGateDialog({super.key, this.seed});
  final int? seed;

  @override
  State<ParentGateDialog> createState() => _ParentGateDialogState();
}

class _ParentGateDialogState extends State<ParentGateDialog> {
  late final Random r = Random(widget.seed);
  late int a = 2 + r.nextInt(5), b = 2 + r.nextInt(5);
  late List<int> options = _options();
  bool wrong = false;

  List<int> _options() {
    final s = {a + b};
    while (s.length < 4) {
      s.add(4 + r.nextInt(9));
    }
    return s.toList()..shuffle(r);
  }

  @override
  Widget build(BuildContext context) {
    return _Card(children: [
      Text('Área dos pais', style: DS.display(26)),
      const SizedBox(height: 8),
      Text(wrong ? 'Ops! Tente de novo' : 'Quanto é', style: DS.display(18, color: DS.ink.withValues(alpha: 0.6))),
      const SizedBox(height: 4),
      Text('$a + $b = ?', style: DS.display(52, color: DS.accent)),
      const SizedBox(height: 16),
      Wrap(spacing: 12, runSpacing: 12, alignment: WrapAlignment.center, children: [
        for (final (i, o) in options.indexed)
          _BigButton(
            label: '$o',
            color: DS.letterColor(i * 5 + 2),
            onTap: () {
              if (o == a + b) {
                Navigator.of(context).pop(true);
              } else {
                setState(() {
                  wrong = true;
                  a = 2 + r.nextInt(5);
                  b = 2 + r.nextInt(5);
                  options = _options();
                });
              }
            },
          ),
      ]),
      const SizedBox(height: 10),
      TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text('Voltar', style: DS.display(18))),
    ]);
  }
}

enum ParentAction { exit, resume }

class ParentMenu extends StatefulWidget {
  const ParentMenu({super.key, required this.soundOn, required this.onSound, required this.musicOn, required this.onMusic});
  final bool soundOn, musicOn;
  final ValueChanged<bool> onSound, onMusic;
  @override
  State<ParentMenu> createState() => _ParentMenuState();
}

class _ParentMenuState extends State<ParentMenu> {
  late bool sound = widget.soundOn;
  late bool music = widget.musicOn;
  @override
  Widget build(BuildContext context) {
    return _Card(children: [
      Text('Menu dos pais', style: DS.display(26)),
      const SizedBox(height: 16),
      _BigButton(label: 'Continuar', color: DS.letterColor(4), wide: true, onTap: () => Navigator.pop(context, ParentAction.resume)),
      const SizedBox(height: 12),
      _BigButton(
        label: music ? 'Música: ligada' : 'Música: desligada',
        color: DS.letterColor(9),
        wide: true,
        onTap: () {
          setState(() => music = !music);
          widget.onMusic(music);
        },
      ),
      const SizedBox(height: 12),
      _BigButton(
        label: sound ? 'Efeitos: ligados' : 'Efeitos: desligados',
        color: DS.letterColor(7),
        wide: true,
        onTap: () {
          setState(() => sound = !sound);
          widget.onSound(sound);
        },
      ),
      const SizedBox(height: 12),
      _BigButton(label: 'Sair', color: DS.letterColor(0), wide: true, onTap: () => Navigator.pop(context, ParentAction.exit)),
    ]);
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 340,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: DS.card,
            borderRadius: BorderRadius.circular(32),
            boxShadow: const [BoxShadow(color: DS.softShadowColor, blurRadius: 30, offset: Offset(0, 12))],
          ),
          child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: children)),
        ),
      ),
    );
  }
}

class _BigButton extends StatelessWidget {
  const _BigButton({required this.label, required this.color, required this.onTap, this.wide = false});
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool wide;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: wide ? double.infinity : 64,
        height: 64,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [DS.light(color), color]),
          borderRadius: BorderRadius.circular(22),
          border: Border(bottom: BorderSide(color: DS.dark(color), width: 5)),
        ),
        child: Text(label, style: DS.display(wide ? 24 : 30, color: DS.white)),
      ),
    );
  }
}
