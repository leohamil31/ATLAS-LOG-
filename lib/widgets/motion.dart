/// Primitivas de movimento do ATLAS LOG.
///
/// Sem dependências externas: tudo construído sobre AnimationController e
/// widgets implícitos do Flutter, respeitando prefers-reduced-motion.
library;

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../core/theme.dart';

// ---------------------------------------------------------------------------
// Entrada: fade + slide (+ escala opcional) com atraso escalonado
// ---------------------------------------------------------------------------

/// Anima o filho uma única vez ao ser montado.
///
/// O atraso é embutido na própria animação (Interval), então não cria Timers
/// — seguro para widget tests e para reconstruções frequentes do store.
class FadeSlideIn extends StatefulWidget {
  const FadeSlideIn({
    super.key,
    required this.child,
    this.index = 0,
    this.delay,
    this.duration = AtlasMotion.entrance,
    this.offset = const Offset(0, 14),
    this.scale = 1,
  });

  final Widget child;

  /// Posição na lista; vira atraso de 45 ms por item (limitado).
  final int index;

  /// Atraso explícito (sobrepõe [index]).
  final Duration? delay;
  final Duration duration;

  /// Deslocamento inicial em pixels lógicos.
  final Offset offset;

  /// Escala inicial (1 = sem escala).
  final double scale;

  static const _step = 45;
  static const _maxDelay = 360;

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  AnimationController? _c;
  late Animation<double> _t;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_c != null) return;
    final delayMs =
        widget.delay?.inMilliseconds ??
        math.min(widget.index * FadeSlideIn._step, FadeSlideIn._maxDelay);
    final runMs = widget.duration.inMilliseconds;
    final total = delayMs + runMs;
    _c = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: total),
    );
    _t = CurvedAnimation(
      parent: _c!,
      curve: Interval(
        total == 0 ? 0 : delayMs / total,
        1,
        curve: AtlasMotion.enter,
      ),
    );
    if (context.reduceMotion || total == 0) {
      _c!.value = 1;
    } else {
      _c!.forward();
    }
  }

  @override
  void dispose() {
    _c?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _t,
      child: widget.child,
      builder: (context, child) {
        final v = _t.value;
        if (v >= 1) return child!;
        final inv = 1 - v;
        Widget result = Transform.translate(
          offset: widget.offset * inv,
          child: child,
        );
        if (widget.scale != 1) {
          result = Transform.scale(
            scale: widget.scale + (1 - widget.scale) * v,
            child: result,
          );
        }
        return Opacity(opacity: v.clamp(0.0, 1.0), child: result);
      },
    );
  }
}

/// Envolve cada filho de uma lista em [FadeSlideIn] com atraso crescente.
///
/// Mantém a `key` do filho no wrapper, então itens com `ValueKey` (ex.: id do
/// pedido) só animam quando realmente entram na lista.
List<Widget> staggered(List<Widget> children, {int start = 0}) => [
  for (var i = 0; i < children.length; i++)
    FadeSlideIn(
      key: children[i].key,
      index: start + i,
      child: children[i],
    ),
];

// ---------------------------------------------------------------------------
// Feedback de toque: escala ao pressionar
// ---------------------------------------------------------------------------

/// Reduz levemente a escala enquanto pressionado (feedback tátil visual).
class PressScale extends StatefulWidget {
  const PressScale({
    super.key,
    required this.child,
    this.pressedScale = 0.97,
    this.enabled = true,
  });

  final Widget child;
  final double pressedScale;
  final bool enabled;

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  bool _down = false;

  void _set(bool v) {
    if (_down != v && mounted) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: widget.enabled ? (_) => _set(true) : null,
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: AnimatedScale(
        scale: _down ? widget.pressedScale : 1,
        duration: AtlasMotion.of(context, AtlasMotion.instant),
        curve: AtlasMotion.standard,
        child: widget.child,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Fundo ambiente
// ---------------------------------------------------------------------------

/// Gradiente "mesh" estático atrás de todo o app. É o que dá sentido ao
/// vidro: as superfícies translúcidas deixam a cor passar levemente.
class AtlasBackdrop extends StatelessWidget {
  const AtlasBackdrop({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.ac;
    final a = c.dark ? 0.22 : 0.10;
    return DecoratedBox(
      decoration: BoxDecoration(color: c.bg),
      child: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: RepaintBoundary(
                child: CustomPaint(
                  painter: _MeshPainter(
                    c.accent2.withValues(alpha: a),
                    c.accent3.withValues(alpha: a * 0.85),
                    const Color(0xFF06B6D4).withValues(alpha: a * 0.6),
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(child: child),
        ],
      ),
    );
  }
}

class _MeshPainter extends CustomPainter {
  _MeshPainter(this.a, this.b, this.c);

  final Color a;
  final Color b;
  final Color c;

  void _blob(Canvas canvas, Offset center, double radius, Color color) {
    final paint = Paint()
      ..shader = ui.Gradient.radial(center, radius, [
        color,
        color.withValues(alpha: 0),
      ]);
    canvas.drawCircle(center, radius, paint);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final m = math.max(size.width, size.height);
    _blob(canvas, Offset(size.width * 0.08, size.height * 0.02), m * 0.55, a);
    _blob(canvas, Offset(size.width * 0.95, size.height * 0.18), m * 0.45, b);
    _blob(canvas, Offset(size.width * 0.6, size.height * 1.05), m * 0.5, c);
  }

  @override
  bool shouldRepaint(_MeshPainter old) =>
      old.a != a || old.b != b || old.c != c;
}

// ---------------------------------------------------------------------------
// Diálogos com entrada/saída animadas
// ---------------------------------------------------------------------------

/// Substituto de `showDialog` com:
/// * fundo desfocado (blur) que acompanha a animação;
/// * entrada fade + scale + leve subida, saída mais rápida;
/// * mesma assinatura básica (`context`, `builder`, `barrierDismissible`).
Future<T?> showAtlasDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
}) {
  final c = context.ac;
  final reduce = context.reduceMotion;
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: c.shadow.withValues(alpha: c.dark ? 0.55 : 0.22),
    transitionDuration: reduce ? Duration.zero : AtlasMotion.base,
    pageBuilder: (ctx, _, _) => builder(ctx),
    transitionBuilder: (ctx, animation, _, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: AtlasMotion.enter,
        reverseCurve: AtlasMotion.exit,
      );
      return Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: curved,
                builder: (_, _) => BackdropFilter(
                  filter: ui.ImageFilter.blur(
                    sigmaX: 6 * curved.value,
                    sigmaY: 6 * curved.value,
                  ),
                  child: const SizedBox.expand(),
                ),
              ),
            ),
          ),
          FadeTransition(
            opacity: curved,
            child: ScaleTransition(
              scale: Tween(begin: 0.94, end: 1.0).animate(curved),
              child: SlideTransition(
                position: Tween(
                  begin: const Offset(0, 0.02),
                  end: Offset.zero,
                ).animate(curved),
                child: child,
              ),
            ),
          ),
        ],
      );
    },
  );
}

// ---------------------------------------------------------------------------
// Troca de páginas com profundidade
// ---------------------------------------------------------------------------

/// Troca de conteúdo com sensação de profundidade:
/// * a página nova sobe 16 px, cresce de 98,5% e aparece;
/// * a antiga recua para 97% e some mais rápido (não disputa atenção).
///
/// Use no lugar de um AnimatedSwitcher genérico. [pageKey] identifica a
/// página atual (ex.: o nome da aba).
class AtlasPageSwitcher extends StatelessWidget {
  const AtlasPageSwitcher({
    super.key,
    required this.pageKey,
    required this.child,
  });

  final Object pageKey;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final current = ValueKey(pageKey);
    return AnimatedSwitcher(
      duration: AtlasMotion.of(context, AtlasMotion.slow),
      reverseDuration: AtlasMotion.of(context, AtlasMotion.fast),
      switchInCurve: AtlasMotion.enter,
      switchOutCurve: AtlasMotion.exit,
      transitionBuilder: (child, animation) {
        final incoming = child.key == current;
        if (incoming) {
          return FadeTransition(
            opacity: animation,
            child: AnimatedBuilder(
              animation: animation,
              child: child,
              builder: (_, c) => Transform.translate(
                offset: Offset(0, 16 * (1 - animation.value)),
                child: Transform.scale(
                  scale: 0.985 + 0.015 * animation.value,
                  alignment: Alignment.topCenter,
                  child: c,
                ),
              ),
            ),
          );
        }
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween(begin: 0.97, end: 1.0).animate(animation),
            alignment: Alignment.topCenter,
            child: child,
          ),
        );
      },
      child: KeyedSubtree(key: current, child: child),
    );
  }
}

/// Transição de rotas usada por TODO `MaterialPageRoute` (registrada em
/// `buildTheme` → `pageTransitionsTheme`): a página nova entra com fade +
/// subida + leve escala; a de baixo recua e escurece um pouco.
class AtlasPageTransitionsBuilder extends PageTransitionsBuilder {
  const AtlasPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (context.reduceMotion) return child;
    final enter = CurvedAnimation(
      parent: animation,
      curve: AtlasMotion.enter,
      reverseCurve: AtlasMotion.exit,
    );
    final under = CurvedAnimation(
      parent: secondaryAnimation,
      curve: AtlasMotion.standard,
    );
    return AnimatedBuilder(
      animation: under,
      child: FadeTransition(
        opacity: enter,
        child: SlideTransition(
          position: Tween(
            begin: const Offset(0, 0.04),
            end: Offset.zero,
          ).animate(enter),
          child: ScaleTransition(
            scale: Tween(begin: 0.985, end: 1.0).animate(enter),
            child: child,
          ),
        ),
      ),
      builder: (context, c) => Transform.scale(
        scale: 1 - 0.03 * under.value,
        child: Opacity(opacity: 1 - 0.25 * under.value, child: c),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Listas com entrada E saída animadas
// ---------------------------------------------------------------------------

/// Coluna de itens que anima mudanças na lista:
/// * carga inicial: entrada escalonada (fade + subida);
/// * item novo: abre espaço (size) + fade;
/// * item removido: desliza para a direita, some e fecha o espaço.
///
/// Diferente do `AnimatedList`, você não chama insert/remove manualmente:
/// basta passar a lista nova (ex.: vinda do store) e o diff é automático
/// pelas chaves de [keyOf].
class AnimatedItems<T> extends StatefulWidget {
  const AnimatedItems({
    super.key,
    required this.items,
    required this.keyOf,
    required this.itemBuilder,
    this.spacing = 0,
  });

  final List<T> items;
  final Object Function(T item) keyOf;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;

  /// Espaço abaixo de cada item (também anima ao entrar/sair).
  final double spacing;

  @override
  State<AnimatedItems<T>> createState() => _AnimatedItemsState<T>();
}

class _ItemEntry<T> {
  _ItemEntry(this.key, this.item, this.controller, this.curve, this.grow);

  final Object key;
  T item;
  final AnimationController controller;
  final CurvedAnimation curve;

  /// true = item inserido/removido depois da carga (anima a altura).
  bool grow;
  bool leaving = false;
  bool _disposed = false;

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    curve.dispose();
    controller.dispose();
  }
}

class _AnimatedItemsState<T> extends State<AnimatedItems<T>>
    with TickerProviderStateMixin {
  final _entries = <_ItemEntry<T>>[];
  bool _initialized = false;
  bool _disposing = false;

  _ItemEntry<T> _create(T item, {required int index, required bool grow}) {
    final reduce = context.reduceMotion;
    final delay = grow ? 0 : math.min(index * 45, 360);
    final run = grow ? AtlasMotion.slow.inMilliseconds : 420;
    final total = delay + run;
    final c = AnimationController(
      vsync: this,
      duration: reduce ? Duration.zero : Duration(milliseconds: total),
      reverseDuration: reduce ? Duration.zero : AtlasMotion.base,
    );
    final curve = CurvedAnimation(
      parent: c,
      curve: Interval(delay / total, 1, curve: AtlasMotion.enter),
      reverseCurve: AtlasMotion.exit,
    );
    c.forward();
    return _ItemEntry(widget.keyOf(item), item, c, curve, grow);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    for (var i = 0; i < widget.items.length; i++) {
      _entries.add(_create(widget.items[i], index: i, grow: false));
    }
  }

  @override
  void didUpdateWidget(AnimatedItems<T> old) {
    super.didUpdateWidget(old);
    final byKey = {for (final e in _entries) e.key: e};
    final nextKeys = {for (final item in widget.items) widget.keyOf(item)};

    // Nova ordem: itens atuais (reaproveitando estado) + novos.
    final next = <_ItemEntry<T>>[];
    for (var i = 0; i < widget.items.length; i++) {
      final item = widget.items[i];
      final existing = byKey[widget.keyOf(item)];
      if (existing != null && !existing.leaving) {
        existing.item = item;
        next.add(existing);
      } else {
        existing?.dispose(); // estava saindo e voltou: recomeça
        next.add(_create(item, index: i, grow: true));
      }
    }

    // Itens que saíram: continuam na posição antiga até a animação acabar.
    for (var i = 0; i < _entries.length; i++) {
      final e = _entries[i];
      if (nextKeys.contains(e.key)) continue;
      if (!e.leaving) {
        e
          ..leaving = true
          ..grow = true;
        e.controller.reverse().whenCompleteOrCancel(() {
          if (_disposing || e._disposed || !mounted) return;
          setState(() => _entries.remove(e));
          e.dispose();
        });
      }
      next.insert(math.min(i, next.length), e);
    }

    _entries
      ..clear()
      ..addAll(next);
  }

  @override
  void dispose() {
    _disposing = true;
    for (final e in _entries) {
      e.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < _entries.length; i++)
          KeyedSubtree(
            key: ValueKey(_entries[i].key),
            child: _buildEntry(context, _entries[i], i),
          ),
      ],
    );
  }

  Widget _buildEntry(BuildContext context, _ItemEntry<T> e, int index) {
    final a = e.curve;
    Widget child = Padding(
      padding: EdgeInsets.only(bottom: widget.spacing),
      child: widget.itemBuilder(context, e.item, index),
    );
    child = AnimatedBuilder(
      animation: a,
      child: child,
      builder: (_, c) {
        final v = a.value.clamp(0.0, 1.0);
        final offset = e.leaving
            ? Offset(40 * (1 - v), 0)
            : Offset(0, 14 * (1 - v));
        return Opacity(
          opacity: v,
          child: Transform.translate(offset: offset, child: c),
        );
      },
    );
    if (e.grow) {
      child = SizeTransition(
        sizeFactor: a,
        axisAlignment: -1,
        child: child,
      );
    }
    // Itens saindo não recebem mais toques.
    return IgnorePointer(ignoring: e.leaving, child: child);
  }
}
