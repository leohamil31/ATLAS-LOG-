part of '../logistics_pages.dart';

// Mapa de design:
//   DESIGN-SLOT[sidebar]     _Sidebar / _NavTile (indicador animado, hover)
//   DESIGN-SLOT[topbar]      _TopBar (vidro com blur) + _SearchPill
//   MOTION-HOOK[page-switch] AtlasPageSwitcher (widgets/motion.dart)
//   MOTION-HOOK[palette]     _CommandPalette (Ctrl+K) — entrada via showAtlasDialog
//   Mobile (< 940 px): AppBar + Drawer + NavigationBar (tema em theme.dart)

// Shell do app logado: sidebar, top bar, navegação inferior (mobile),
// paleta de comandos (Ctrl+K) e troca de abas com profundidade.

const _navItems = <(String, IconData)>[
  ('Dashboard', Icons.grid_view_rounded),
  ('Pedidos', Icons.inventory_2_rounded),
  ('Frota', Icons.local_shipping_rounded),
  ('Relatórios', Icons.insights_rounded),
  ('Notificações', Icons.notifications_rounded),
  ('Configurações', Icons.settings_rounded),
];

class LogisticsShell extends StatefulWidget {
  const LogisticsShell({
    required this.store,
    required this.userName,
    super.key,
  });

  final AtlasStore store;
  final String userName;

  @override
  State<LogisticsShell> createState() => _LogisticsShellState();
}

class _LogisticsShellState extends State<LogisticsShell> {
  String _page = 'Dashboard';
  bool _collapsed = false;

  AtlasStore get store => widget.store;
  UserRole get role => store.settings.role;

  bool _canSee(String page) {
    if (role == UserRole.admin) return true;
    if (role == UserRole.operador) {
      return page != 'Relatórios' && page != 'Configurações';
    }
    return page == 'Dashboard' ||
        page == 'Frota' ||
        page == 'Notificações' ||
        page == 'Configurações';
  }

  void _navigate(String page) {
    if (!_canSee(page)) return;
    setState(() => _page = page);
    if (Navigator.of(context).canPop()) Navigator.of(context).pop();
  }

  void _openPalette() {
    showAtlasDialog<void>(
      context: context,
      builder: (context) =>
          _CommandPalette(store: store, onNavigate: _navigate),
    );
  }

  void _openAssistant() {
    showAtlasDialog<void>(
      context: context,
      builder: (context) =>
          AssistantDialog(store: store, onNavigate: _navigate),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyK, control: true):
            _openPalette,
        const SingleActivator(LogicalKeyboardKey.keyK, meta: true):
            _openPalette,
      },
      child: Focus(
        autofocus: true,
        child: ListenableBuilder(
          listenable: store,
          builder: (context, _) => LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 940;
              // Troca de abas com profundidade (entra subindo, sai recuando).
              final body = AtlasPageSwitcher(
                pageKey: _page,
                child: _buildPage(),
              );
              if (!wide) {
                final mobilePages = _mobilePages.where(_canSee).toList();
                return Scaffold(
                  appBar: AppBar(
                    titleSpacing: 0,
                    title: Text(
                      _page == 'Dashboard' ? 'ATLAS LOG' : _page,
                      overflow: TextOverflow.ellipsis,
                    ),
                    leading: Builder(
                      builder: (context) => IconButton(
                        tooltip: 'Abrir menu',
                        icon: const Icon(Icons.menu_rounded),
                        onPressed: () => Scaffold.of(context).openDrawer(),
                      ),
                    ),
                    actions: [
                      IconButton(
                        tooltip: 'Buscar (Ctrl+K)',
                        onPressed: _openPalette,
                        icon: const Icon(Icons.search_rounded),
                      ),
                      IconButton(
                        tooltip: 'Assistente de logística',
                        onPressed: _openAssistant,
                        icon: const Icon(Icons.auto_awesome_rounded),
                      ),
                      _notificationAction(),
                    ],
                  ),
                  drawer: Drawer(
                    child: _Sidebar(
                      store: store,
                      selected: _page,
                      collapsed: false,
                      onSelect: _navigate,
                    ),
                  ),
                  body: body,
                  bottomNavigationBar: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(color: context.ac.border),
                      ),
                    ),
                    child: NavigationBar(
                    selectedIndex: _bottomIndex(mobilePages),
                    animationDuration: AtlasMotion.of(
                      context,
                      AtlasMotion.slow,
                    ),
                    labelBehavior:
                        NavigationDestinationLabelBehavior.onlyShowSelected,
                    onDestinationSelected: (index) =>
                        _navigate(mobilePages[index]),
                    destinations: [
                      for (final page in mobilePages)
                        NavigationDestination(
                          icon: Icon(_iconFor(page), color: context.ac.muted),
                          selectedIcon: Icon(
                            _iconFor(page),
                            color: context.ac.accent2,
                          ),
                          label: page,
                        ),
                    ],
                  ),
                  ),
                );
              }
              return Scaffold(
                body: Row(
                  children: [
                    _Sidebar(
                      store: store,
                      selected: _page,
                      collapsed: _collapsed,
                      onSelect: _navigate,
                      onToggle: () => setState(() => _collapsed = !_collapsed),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          _TopBar(
                            title: _page,
                            userName: widget.userName,
                            onSearch: _openPalette,
                            onAssistant: _openAssistant,
                            notification: _notificationAction(),
                          ),
                          Expanded(
                            child: Align(
                              alignment: Alignment.topCenter,
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: AtlasBreakpoints.contentMax,
                                ),
                                child: body,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  static const _mobilePages = ['Dashboard', 'Pedidos', 'Frota', 'Relatórios'];

  int _bottomIndex(List<String> mobilePages) {
    final index = mobilePages.indexOf(_page);
    return index < 0 ? 0 : index;
  }

  IconData _iconFor(String page) =>
      _navItems.firstWhere((item) => item.$1 == page).$2;

  Widget _notificationAction() => IconButton(
    tooltip: 'Notificações (${store.unreadCount} não lidas)',
    onPressed: () => _navigate('Notificações'),
    icon: Badge(
      isLabelVisible: store.unreadCount > 0,
      label: Text('${store.unreadCount}'),
      child: const Icon(Icons.notifications_none_rounded),
    ),
  );

  Widget _buildPage() {
    if (!_canSee(_page)) _page = 'Dashboard';
    if (store.loading) return const PageSkeleton();
    return switch (_page) {
      'Dashboard' => DashboardPage(
        store: store,
        onNavigate: _navigate,
        onSearch: _openPalette,
      ),
      'Pedidos' => OrdersPage(store: store),
      'Frota' => FleetPage(store: store),
      'Relatórios' => ReportsPage(store: store),
      'Notificações' => NotificationsPage(store: store),
      'Configurações' => SettingsPage(store: store),
      _ => const Center(child: Text('Tela não encontrada')),
    };
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.store,
    required this.selected,
    required this.collapsed,
    required this.onSelect,
    this.onToggle,
  });

  final AtlasStore store;
  final String selected;
  final bool collapsed;
  final ValueChanged<String> onSelect;
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context) {
    final colors = context.ac;
    final width = collapsed ? 84.0 : 258.0;
    final visibleItems = _navItems.where((e) {
      if (store.settings.role == UserRole.admin) return true;
      if (store.settings.role == UserRole.operador) {
        return e.$1 != 'Relatórios' && e.$1 != 'Configurações';
      }
      return e.$1 == 'Dashboard' ||
          e.$1 == 'Frota' ||
          e.$1 == 'Notificações' ||
          e.$1 == 'Configurações';
    });
    return AnimatedContainer(
      duration: AtlasMotion.of(context, AtlasMotion.slow),
      curve: AtlasMotion.standard,
      width: width,
      decoration: BoxDecoration(
        color: colors.glass,
        border: Border(right: BorderSide(color: colors.border)),
      ),
      // O conteúdo troca de layout pela largura *atual* (animada), não pelo
      // flag — assim nada transborda durante a animação de recolher/expandir.
      child: LayoutBuilder(
        builder: (context, box) {
          final collapsed = box.maxWidth < 200;
          return ClipRect(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                  collapsed ? 22 : 20,
                  22,
                  collapsed ? 22 : 12,
                  16,
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: AtlasLogo3D(
                    size: collapsed ? 38 : 36,
                    showWordmark: !collapsed,
                  ),
                ),
              ),
              if (!collapsed)
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 2, 12, 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          store.settings.role.label.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.clip,
                          style: TextStyle(
                            color: colors.muted,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.4,
                          ),
                        ),
                      ),
                      if (onToggle != null)
                        IconButton(
                          tooltip: 'Recolher menu',
                          visualDensity: VisualDensity.compact,
                          onPressed: onToggle,
                          icon: const Icon(Icons.menu_open_rounded, size: 18),
                        ),
                    ],
                  ),
                ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: [
                    for (final (i, item) in visibleItems.indexed)
                      FadeSlideIn(
                        index: i,
                        offset: const Offset(-10, 0),
                        child: _NavTile(
                          label: item.$1,
                          icon: item.$2,
                          selected: selected == item.$1,
                          collapsed: collapsed,
                          trailing: item.$1 == 'Pedidos'
                              ? _NavCount(count: store.inTransitCount)
                              : null,
                          onTap: () => onSelect(item.$1),
                        ),
                      ),
                  ],
                ),
              ),
              if (onToggle != null && collapsed)
                IconButton(
                  tooltip: 'Expandir menu',
                  onPressed: onToggle,
                  icon: const Icon(Icons.menu_rounded),
                ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Material(
                  type: MaterialType.transparency,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AtlasRadius.md),
                    onTap: () => onSelect('Configurações'),
                    child: Container(
                      padding: EdgeInsets.all(collapsed ? 8 : 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AtlasRadius.md),
                        border: Border.all(color: colors.border),
                        color: colors.surface.withValues(alpha: 0.5),
                      ),
                      child: Row(
                        children: [
                          _Avatar(name: store.settings.userName, radius: 17),
                          if (!collapsed) ...[
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    store.settings.userName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                  Text(
                                    store.settings.role.label,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: colors.muted,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
        },
      ),
    );
  }
}

/// Item de navegação com indicador animado (barra + fundo tingido) e hover.
class _NavTile extends StatefulWidget {
  const _NavTile({
    required this.label,
    required this.icon,
    required this.selected,
    required this.collapsed,
    required this.onTap,
    this.trailing,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final bool collapsed;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  State<_NavTile> createState() => _NavTileState();
}

class _NavTileState extends State<_NavTile> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final c = context.ac;
    final sel = widget.selected;
    final d = AtlasMotion.of(context, AtlasMotion.base);
    final radius = BorderRadius.circular(AtlasRadius.sm);
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Tooltip(
        message: widget.collapsed ? widget.label : '',
        child: Semantics(
          selected: sel,
          button: true,
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              borderRadius: radius,
              onTap: widget.onTap,
              onHover: (h) => setState(() => _hover = h),
              hoverColor: Colors.transparent,
              child: AnimatedContainer(
                duration: d,
                curve: AtlasMotion.standard,
                height: 46,
                padding: EdgeInsets.symmetric(
                  horizontal: widget.collapsed ? 0 : 12,
                ),
                decoration: BoxDecoration(
                  borderRadius: radius,
                  gradient: sel
                      ? LinearGradient(
                          colors: [
                            c.accent2.withValues(alpha: c.dark ? 0.26 : 0.13),
                            c.accent3.withValues(alpha: c.dark ? 0.10 : 0.04),
                          ],
                        )
                      : null,
                  color: !sel && _hover
                      ? c.accent2.withValues(alpha: 0.06)
                      : null,
                  border: Border.all(
                    color: sel
                        ? c.accent2.withValues(alpha: 0.22)
                        : Colors.transparent,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: widget.collapsed
                      ? MainAxisAlignment.center
                      : MainAxisAlignment.start,
                  children: [
                    if (!widget.collapsed)
                      AnimatedContainer(
                        duration: d,
                        curve: AtlasMotion.pop,
                        width: 3,
                        height: sel ? 18 : 0,
                        margin: const EdgeInsets.only(right: 9),
                        decoration: BoxDecoration(
                          gradient: c.brandGradient,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    AnimatedScale(
                      scale: sel || _hover ? 1.08 : 1,
                      duration: d,
                      curve: AtlasMotion.pop,
                      child: Icon(
                        widget.icon,
                        size: 21,
                        color: sel ? c.accent : c.muted,
                      ),
                    ),
                    if (!widget.collapsed) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: AnimatedDefaultTextStyle(
                          duration: d,
                          style: TextStyle(
                            color: sel ? c.accent : c.text,
                            fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                            fontSize: 14,
                          ),
                          child: Text(
                            widget.label,
                            maxLines: 1,
                            overflow: TextOverflow.clip,
                          ),
                        ),
                      ),
                      ?widget.trailing,
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.name, this.radius = 16});

  final String name;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final c = context.ac;
    return Container(
      width: radius * 2,
      height: radius * 2,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: c.brandGradient,
        boxShadow: AtlasShadows.glow(c.accent2, strength: 0.5),
      ),
      child: Text(
        name.isEmpty ? 'A' : name[0].toUpperCase(),
        style: TextStyle(
          color: Colors.white,
          fontSize: radius * 0.8,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _NavCount extends StatelessWidget {
  const _NavCount({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final colors = context.ac;
    return AnimatedSwitcher(
      duration: AtlasMotion.of(context, AtlasMotion.base),
      transitionBuilder: (child, anim) => ScaleTransition(
        scale: CurvedAnimation(parent: anim, curve: AtlasMotion.pop),
        child: child,
      ),
      child: count == 0
          ? const SizedBox.shrink()
          : Container(
              key: ValueKey(count),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: colors.accent2.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(AtlasRadius.pill),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  color: colors.accent,
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                ),
              ),
            ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.title,
    required this.userName,
    required this.onSearch,
    required this.onAssistant,
    required this.notification,
  });

  final String title;
  final String userName;
  final VoidCallback onSearch;
  final VoidCallback onAssistant;
  final Widget notification;

  @override
  Widget build(BuildContext context) {
    final colors = context.ac;
    return ClipRect(
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          height: 68,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            color: colors.glass,
            border: Border(bottom: BorderSide(color: colors.border)),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 210,
                child: AnimatedSwitcher(
                  duration: AtlasMotion.of(context, AtlasMotion.base),
                  layoutBuilder: (current, previous) => Stack(
                    alignment: Alignment.centerLeft,
                    children: [...previous, ?current],
                  ),
                  transitionBuilder: (child, anim) => FadeTransition(
                    opacity: anim,
                    child: SlideTransition(
                      position: Tween(
                        begin: const Offset(0, 0.3),
                        end: Offset.zero,
                      ).animate(anim),
                      child: child,
                    ),
                  ),
                  child: Text(
                    title == 'Dashboard' ? 'Visão geral' : title,
                    key: ValueKey(title),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 460),
                    child: _SearchPill(onTap: onSearch),
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Assistente de logística',
                onPressed: onAssistant,
                icon: const Icon(Icons.auto_awesome_outlined),
              ),
              notification,
              const SizedBox(width: 10),
              Tooltip(
                message: userName,
                child: _Avatar(name: userName),
              ),
              const SizedBox(width: 9),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 130),
                child: Text(
                  userName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Campo de busca "falso" que abre a paleta de comandos.
class _SearchPill extends StatefulWidget {
  const _SearchPill({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_SearchPill> createState() => _SearchPillState();
}

class _SearchPillState extends State<_SearchPill> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.ac;
    final radius = BorderRadius.circular(AtlasRadius.pill);
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: widget.onTap,
        onHover: (h) => setState(() => _hover = h),
        hoverColor: Colors.transparent,
        borderRadius: radius,
        child: AnimatedContainer(
          duration: AtlasMotion.of(context, AtlasMotion.fast),
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: _hover
                ? colors.surface
                : colors.surface.withValues(alpha: colors.dark ? 0.4 : 0.7),
            border: Border.all(
              color: _hover
                  ? colors.accent2.withValues(alpha: 0.45)
                  : colors.border,
            ),
            borderRadius: radius,
            boxShadow: _hover ? AtlasShadows.soft(colors) : null,
          ),
          child: Row(
            children: [
              Icon(
                Icons.search_rounded,
                size: 19,
                color: _hover ? colors.accent : colors.muted,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Buscar pedidos, telas e clientes',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: colors.muted, fontSize: 13),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AtlasRadius.xs),
                  border: Border.all(color: colors.border),
                  color: colors.bg.withValues(alpha: 0.6),
                ),
                child: Text(
                  'Ctrl K',
                  style: TextStyle(
                    color: colors.muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CommandPalette extends StatefulWidget {
  const _CommandPalette({required this.store, required this.onNavigate});

  final AtlasStore store;
  final ValueChanged<String> onNavigate;

  @override
  State<_CommandPalette> createState() => _CommandPaletteState();
}

class _CommandPaletteState extends State<_CommandPalette> {
  final _query = TextEditingController();

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = _query.text.trim().toLowerCase();
    final orders = widget.store.orders
        .where(
          (o) => q.isEmpty || '${o.id} ${o.cliente}'.toLowerCase().contains(q),
        )
        .take(5);
    final pages = _navItems.where(
      (e) => q.isEmpty || e.$1.toLowerCase().contains(q),
    );
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      alignment: const Alignment(0, -0.45),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620, maxHeight: 620),
        child: Glass(
          opacity: context.ac.dark ? .9 : .95,
          radius: AtlasRadius.xl,
          blur: 24,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _query,
                  autofocus: true,
                  onChanged: (_) => setState(() {}),
                  onSubmitted: (_) {
                    if (orders.isNotEmpty) {
                      final order = orders.first;
                      Navigator.pop(context);
                      showOrderDetails(context, widget.store, order.id);
                    }
                  },
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search_rounded),
                    hintText: 'Buscar tela, pedido ou cliente...',
                  ),
                ),
              ),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  children: staggered([
                    for (final item in pages)
                      ListTile(
                        leading: Icon(item.$2),
                        title: Text(item.$1),
                        subtitle: const Text('Abrir tela'),
                        onTap: () {
                          Navigator.pop(context);
                          widget.onNavigate(item.$1);
                        },
                      ),
                    for (final order in orders)
                      ListTile(
                        leading: const Icon(Icons.inventory_2_rounded),
                        title: Text('${order.id} · ${order.cliente}'),
                        subtitle: Text(
                          '${order.status.label} · ${order.destino}',
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          showOrderDetails(context, widget.store, order.id);
                        },
                      ),
                  ]),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  'Atalho: Ctrl+K ou Cmd+K',
                  style: TextStyle(color: context.ac.muted, fontSize: 11),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
