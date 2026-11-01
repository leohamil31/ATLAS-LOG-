/// GALERIA DE DESIGN — abra em `/#/design` (ex.: http://localhost:xxxx/#/design).
///
/// Mostra TODOS os componentes visuais e seus estados numa única tela, com
/// dados de exemplo fixos (sem store, sem login). É a bancada de trabalho
/// para redesenhar: como usa os widgets reais, qualquer mudança feita aqui
/// aparece no app inteiro.
///
/// Não é usada pelo app em produção; pode ser removida antes de publicar
/// (rota em `main.dart`, marcada com "DESIGN").
library;

import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../models/models.dart';
import '../widgets/atlas_logo_3d.dart';
import '../widgets/button3d.dart';
import '../widgets/common.dart';
import '../widgets/icon3d.dart';

class DesignGalleryPage extends StatefulWidget {
  const DesignGalleryPage({super.key});

  @override
  State<DesignGalleryPage> createState() => _DesignGalleryPageState();
}

class _DesignGalleryPageState extends State<DesignGalleryPage> {
  bool _dark = false;
  int _kpi = 42;
  int _nextId = 4;
  final _items = <(int, String)>[
    (1, 'ATL-2401 · Mercado Central'),
    (2, 'ATL-2402 · Farmácia Vida'),
    (3, 'ATL-2403 · Loja Horizonte'),
  ];

  @override
  Widget build(BuildContext context) {
    // Tema local: alterna claro/escuro só nesta tela, sem mexer no store.
    return AnimatedTheme(
      data: buildTheme(dark: _dark),
      duration: AtlasMotion.slow,
      child: Builder(builder: _page),
    );
  }

  Widget _page(BuildContext context) {
    final c = context.ac;
    final phone = MediaQuery.sizeOf(context).width < AtlasBreakpoints.phone;
    return Scaffold(
      body: ColoredBox(
        // Fundo do tema local (o AtlasBackdrop global segue o tema do app).
        color: c.bg.withValues(alpha: 0.6),
        child: ListView(
          padding: EdgeInsets.all(phone ? 16 : 32),
          children: staggered([
            SectionHeader(
              title: 'Galeria de design · ATLAS LOG',
              subtitle:
                  'Componentes reais com dados de exemplo. Passe o mouse, clique, alterne o tema.',
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.light_mode_rounded, size: 18, color: c.muted),
                  Switch(
                    value: _dark,
                    onChanged: (v) => setState(() => _dark = v),
                  ),
                  Icon(Icons.dark_mode_rounded, size: 18, color: c.muted),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _section(
              context,
              'Paleta (AtlasColors)',
              'Tokens de cor — theme.dart. Também em design-tokens.json.',
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final (name, color) in [
                    ('bg', c.bg),
                    ('surface', c.surface),
                    ('card', c.card),
                    ('border', c.border),
                    ('text', c.text),
                    ('muted', c.muted),
                    ('accent', c.accent),
                    ('accent2', c.accent2),
                    ('accent3', c.accent3),
                    ('success', c.success),
                    ('warning', c.warning),
                    ('danger', c.danger),
                  ])
                    _Swatch(name: name, color: color),
                  _Swatch(name: 'brandGradient', gradient: c.brandGradient),
                ],
              ),
            ),
            _section(
              context,
              'Marca — AtlasLogo3D',
              'DESIGN-SLOT[logo]: extrusão + brilho + tilt (≥ 56 px). Passe o mouse.',
              const Wrap(
                spacing: 32,
                runSpacing: 20,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  AtlasLogo3D(size: 120, sway: true),
                  AtlasLogo3D(size: 64),
                  AtlasLogo3D(size: 36, showWordmark: true),
                  AtlasLogo3D(size: 24, extrude: false),
                ],
              ),
            ),
            _section(
              context,
              'Botões — Button3D',
              'MOTION-HOOK[button]: tecla física. Hover sobe, clique afunda; ação assíncrona → spinner → ✓.',
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  Button3D(
                    label: 'Primário',
                    icon: Icons.add_rounded,
                    onPressed: () {},
                  ),
                  Button3D(
                    label: 'Salvar (assíncrono)',
                    icon: Icons.save_rounded,
                    successLabel: 'Salvo',
                    onAction: () async {
                      await Future<void>.delayed(
                        const Duration(milliseconds: 900),
                      );
                      return true;
                    },
                  ),
                  Button3D(
                    label: 'Secundário',
                    icon: Icons.search_rounded,
                    secondary: true,
                    onPressed: () {},
                  ),
                  Button3D(
                    label: 'Perigo',
                    icon: Icons.delete_outline_rounded,
                    color: c.danger,
                    onPressed: () {},
                  ),
                  Button3D(label: 'Compacto', compact: true, onPressed: () {}),
                  const Button3D(label: 'Desabilitado'),
                  FilledButton(onPressed: () {}, child: const Text('Filled')),
                  OutlinedButton(
                    onPressed: () {},
                    child: const Text('Outlined'),
                  ),
                  TextButton(onPressed: () {}, child: const Text('Text')),
                ],
              ),
            ),
            _section(
              context,
              'Ícones — Icon3D',
              'Ladrilho iluminado (≥ 40 px). Cada um mostra um movimento; passe o mouse para tocar de novo.',
              Wrap(
                spacing: 18,
                runSpacing: 18,
                children: [
                  for (final (motion, icon, color) in [
                    (IconMotion.drive, Icons.local_shipping_rounded, c.accent2),
                    (IconMotion.pop, Icons.inventory_2_rounded, c.accent),
                    (IconMotion.pulse, Icons.schedule_rounded, c.warning),
                    (IconMotion.bounce, Icons.build_circle_outlined, c.danger),
                    (IconMotion.tilt, Icons.person_rounded, c.success),
                    (IconMotion.spin, Icons.sync_rounded, c.accent3),
                  ])
                    Column(
                      children: [
                        Icon3D(
                          icon: icon,
                          color: color,
                          motion: motion,
                          size: 56,
                          animate: true,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          motion.name,
                          style: TextStyle(color: c.muted, fontSize: 11),
                        ),
                      ],
                    ),
                  Column(
                    children: [
                      Icon3D(
                        icon: Icons.route_rounded,
                        color: c.accent,
                        size: 56,
                        loop: true,
                        motion: IconMotion.drive,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'loop',
                        style: TextStyle(color: c.muted, fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            _section(
              context,
              'KPIs — KpiCard + Tilt3D',
              'MOTION-HOOK[tilt] + [count-up]: os clicáveis inclinam com o mouse.',
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LayoutBuilder(
                    builder: (context, box) {
                      final cols = box.maxWidth > 900
                          ? 3
                          : box.maxWidth > 560
                          ? 2
                          : 1;
                      final w = (box.maxWidth - 14 * (cols - 1)) / cols;
                      return Wrap(
                        spacing: 14,
                        runSpacing: 14,
                        children: [
                          SizedBox(
                            width: w,
                            child: KpiCard(
                              label: 'Entregas em andamento',
                              value: _kpi,
                              icon: Icons.inventory_2_rounded,
                              color: c.accent,
                              motion: IconMotion.pop,
                              onTap: () {},
                            ),
                          ),
                          SizedBox(
                            width: w,
                            child: KpiCard(
                              label: 'Atrasos',
                              value: _kpi ~/ 6,
                              icon: Icons.schedule_rounded,
                              color: c.warning,
                              motion: IconMotion.pulse,
                              hint: '+2 hoje',
                              onTap: () {},
                            ),
                          ),
                          SizedBox(
                            width: w,
                            child: KpiCard(
                              label: 'Informativo (sem clique)',
                              value: _kpi * 3,
                              icon: Icons.insights_rounded,
                              color: c.success,
                              motion: IconMotion.tilt,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  Button3D(
                    label: 'Sortear valores',
                    icon: Icons.casino_rounded,
                    secondary: true,
                    compact: true,
                    onPressed: () => setState(
                      () => _kpi = 10 + DateTime.now().millisecond % 90,
                    ),
                  ),
                ],
              ),
            ),
            _section(
              context,
              'Status — StatusChip',
              'Troca de status faz crossfade + pop.',
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final s in OrderStatus.values) StatusChip(status: s),
                  const StatusChip(status: OrderStatus.emTransito, late: true),
                ],
              ),
            ),
            _section(
              context,
              'Superfícies — Glass, GlassCard, Tilt3D',
              'Vidro com blur real; card com hover; tilt com reflexo.',
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  SizedBox(
                    width: 240,
                    child: Glass(
                      padding: const EdgeInsets.all(18),
                      child: Text('Glass', style: TextStyle(color: c.text)),
                    ),
                  ),
                  SizedBox(
                    width: 240,
                    child: Glass(
                      highlight: true,
                      padding: const EdgeInsets.all(18),
                      child: Text(
                        'Glass (highlight)',
                        style: TextStyle(color: c.text),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 240,
                    child: GlassCard(
                      onTap: () {},
                      child: const Text('GlassCard clicável'),
                    ),
                  ),
                  SizedBox(
                    width: 240,
                    child: Tilt3D(
                      child: GlassCard(
                        onTap: () {},
                        child: const Text('Tilt3D + GlassCard'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            _section(
              context,
              'Lista animada — AnimatedItems',
              'MOTION-HOOK[list]: itens novos abrem espaço; removidos deslizam para fora.',
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 10,
                    children: [
                      Button3D(
                        label: 'Adicionar',
                        icon: Icons.add_rounded,
                        compact: true,
                        onPressed: () => setState(() {
                          _items.insert(0, (
                            _nextId,
                            'ATL-24${_nextId.toString().padLeft(2, '0')} · Novo cliente',
                          ));
                          _nextId++;
                        }),
                      ),
                      Button3D(
                        label: 'Remover último',
                        icon: Icons.remove_rounded,
                        compact: true,
                        secondary: true,
                        onPressed: _items.isEmpty
                            ? null
                            : () => setState(() => _items.removeLast()),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  AnimatedItems<(int, String)>(
                    items: List.of(_items),
                    keyOf: (it) => it.$1,
                    spacing: 8,
                    itemBuilder: (context, it, _) => GlassCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          Expanded(child: Text(it.$2)),
                          IconButton(
                            tooltip: 'Remover',
                            onPressed: () => setState(
                              () => _items.removeWhere((x) => x.$1 == it.$1),
                            ),
                            icon: Icon(
                              Icons.close_rounded,
                              color: c.danger,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            _section(
              context,
              'Formulário e campos',
              'InputDecorationTheme — foco, erro, prefixo.',
              Wrap(
                spacing: 14,
                runSpacing: 14,
                children: [
                  const SizedBox(
                    width: 280,
                    child: TextField(
                      decoration: InputDecoration(
                        labelText: 'Nome do cliente',
                        prefixIcon: Icon(Icons.person_outline_rounded),
                      ),
                    ),
                  ),
                  const SizedBox(
                    width: 280,
                    child: TextField(
                      decoration: InputDecoration(
                        labelText: 'Telefone',
                        errorText: 'Telefone inválido',
                        prefixIcon: Icon(Icons.phone_rounded),
                      ),
                    ),
                  ),
                  FilterChip(
                    label: const Text('Em trânsito'),
                    selected: true,
                    onSelected: (_) {},
                  ),
                  FilterChip(
                    label: const Text('Entregue'),
                    selected: false,
                    onSelected: (_) {},
                  ),
                ],
              ),
            ),
            _section(
              context,
              'Carregamento, vazio e feedback',
              'Skeleton (shimmer), EmptyState, toast, diálogo.',
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Skeleton(height: 18, width: 220),
                  const SizedBox(height: 10),
                  const Skeleton(height: 64, radius: 14),
                  const EmptyState(
                    title: 'Nenhum pedido encontrado',
                    message: 'Ajuste os filtros ou crie um pedido.',
                  ),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      Button3D(
                        label: 'Toast de sucesso',
                        secondary: true,
                        compact: true,
                        onPressed: () => toast(context, 'Pedido ATL-2401 salvo.'),
                      ),
                      Button3D(
                        label: 'Toast de erro',
                        secondary: true,
                        compact: true,
                        onPressed: () => toast(
                          context,
                          'Falha ao salvar o pedido.',
                          error: true,
                        ),
                      ),
                      Button3D(
                        label: 'Abrir diálogo',
                        icon: Icons.open_in_new_rounded,
                        compact: true,
                        onPressed: () => _openDialog(context),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Future<void> _openDialog(BuildContext context) {
    return showAtlasDialog<void>(
      context: context,
      // O diálogo abre no Navigator raiz (fora do tema local): reaplica o tema.
      builder: (ctx) => Theme(
        data: buildTheme(dark: _dark),
        child: DialogShell(
        title: 'Diálogo de exemplo',
        actions: [
          Button3D(
            label: 'Cancelar',
            secondary: true,
            onPressed: () => Navigator.pop(ctx),
          ),
          Button3D(
            label: 'Confirmar',
            icon: Icons.check_rounded,
            onPressed: () => Navigator.pop(ctx),
          ),
        ],
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Entrada: fade + escala + subida, com o fundo desfocado.'),
            SizedBox(height: 16),
            TextField(decoration: InputDecoration(labelText: 'Observação')),
          ],
        ),
      ),
      ),
    );
  }

  Widget _section(
    BuildContext context,
    String title,
    String note,
    Widget child,
  ) {
    final c = context.ac;
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Glass(
        blur: 0,
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 4),
            Text(note, style: TextStyle(color: c.muted, fontSize: 12.5)),
            const SizedBox(height: 18),
            child,
          ],
        ),
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({required this.name, this.color, this.gradient});

  final String name;
  final Color? color;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    final c = context.ac;
    final hex = color == null
        ? ''
        : '#${color!.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
    return SizedBox(
      width: 112,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 56,
            decoration: BoxDecoration(
              color: color,
              gradient: gradient,
              borderRadius: BorderRadius.circular(AtlasRadius.sm),
              border: Border.all(color: c.border),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            name,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
          ),
          if (hex.isNotEmpty)
            Text(hex, style: TextStyle(color: c.muted, fontSize: 11)),
        ],
      ),
    );
  }
}
