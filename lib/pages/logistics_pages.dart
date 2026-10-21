import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../core/format.dart';
import '../core/geo.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../services/store.dart';
import '../widgets/atlas_logo_3d.dart';
import '../widgets/button3d.dart';
import '../widgets/common.dart';
import '../widgets/extras_dialogs.dart';
import '../widgets/icon3d.dart';
import '../widgets/order_dialogs.dart';
import 'management_pages.dart';

const _navItems = <(String, IconData)>[
  ('Dashboard', Icons.grid_view_rounded),
  ('Pedidos', Icons.inventory_2_rounded),
  ('Frota', Icons.local_shipping_rounded),
  ('Relatórios', Icons.insights_rounded),
  ('Notificações', Icons.notifications_rounded),
  ('Configurações', Icons.settings_rounded),
];

class LogisticsShell extends StatefulWidget {
  const LogisticsShell({required this.store, required this.userName, super.key});

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
    showDialog<void>(
      context: context,
      builder: (context) => _CommandPalette(store: store, onNavigate: _navigate),
    );
  }

  void _openAssistant() {
    showDialog<void>(
      context: context,
      builder: (context) => AssistantDialog(store: store, onNavigate: _navigate),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyK, control: true): _openPalette,
        const SingleActivator(LogicalKeyboardKey.keyK, meta: true): _openPalette,
      },
      child: Focus(
        autofocus: true,
        child: ListenableBuilder(
          listenable: store,
          builder: (context, _) => LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 940;
              final body = AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                switchInCurve: Curves.easeOut,
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, .015),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                ),
                child: KeyedSubtree(
                  key: ValueKey(_page),
                  child: _buildPage(),
                ),
              );
              if (!wide) {
                final mobilePages = _mobilePages.where(_canSee).toList();
                return Scaffold(
                  appBar: AppBar(
                    titleSpacing: 0,
                    title: Text(
                      _page == 'Dashboard' ? 'ATLAS-LOG' : _page,
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
                  bottomNavigationBar: NavigationBar(
                    selectedIndex: _bottomIndex(mobilePages),
                    labelBehavior:
                        NavigationDestinationLabelBehavior.onlyShowSelected,
                    onDestinationSelected: (index) => _navigate(mobilePages[index]),
                    destinations: [
                      for (final page in mobilePages)
                        NavigationDestination(
                          icon: Icon(_iconFor(page)),
                          label: page,
                        ),
                    ],
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
                      onToggle: () =>
                          setState(() => _collapsed = !_collapsed),
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
                          Expanded(child: body),
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

  IconData _iconFor(String page) => _navItems
      .firstWhere((item) => item.$1 == page)
      .$2;

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
    final width = collapsed ? 82.0 : 254.0;
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
      duration: const Duration(milliseconds: 200),
      width: width,
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: .82),
        border: Border(right: BorderSide(color: colors.border)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(collapsed ? 16 : 22),
              child: Row(
                children: [
                  AtlasLogo3D(size: collapsed ? 42 : 44, showWordmark: !collapsed),
                ],
              ),
            ),
            if (!collapsed)
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 4, 18, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        store.settings.role.label.toUpperCase(),
                        style: TextStyle(color: colors.muted, fontSize: 10, letterSpacing: 1),
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
                padding: const EdgeInsets.symmetric(horizontal: 10),
                children: [
                  for (final item in visibleItems)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 5),
                      child: Tooltip(
                        message: collapsed ? item.$1 : '',
                        child: ListTile(
                          selected: selected == item.$1,
                          selectedTileColor: colors.accent.withValues(alpha: .14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
                          leading: Icon3D(
                            icon: item.$2,
                            color: selected == item.$1 ? colors.accent2 : colors.muted,
                            size: 36,
                            animate: selected == item.$1,
                            motion: item.$1 == 'Configurações'
                                ? IconMotion.spin
                                : IconMotion.tilt,
                          ),
                          title: collapsed
                              ? null
                              : Text(
                                  item.$1,
                                  style: TextStyle(
                                    fontWeight: selected == item.$1 ? FontWeight.w800 : FontWeight.w500,
                                  ),
                                ),
                          trailing: !collapsed && item.$1 == 'Pedidos'
                              ? _NavCount(count: store.inTransitCount)
                              : null,
                          onTap: () => onSelect(item.$1),
                        ),
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
            Divider(color: colors.border, height: 1),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: colors.accent2,
                foregroundColor: Colors.white,
                child: Text(store.settings.userName.isEmpty ? 'A' : store.settings.userName[0].toUpperCase()),
              ),
              title: collapsed ? null : Text(store.settings.userName, maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: collapsed ? null : Text(store.settings.role.label, maxLines: 1, overflow: TextOverflow.ellipsis),
              onTap: () => onSelect('Configurações'),
            ),
          ],
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
    if (count == 0) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: colors.accent.withValues(alpha: .14),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text('$count', style: TextStyle(color: colors.accent, fontWeight: FontWeight.w800, fontSize: 11)),
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
    return Glass(
      radius: 0,
      blur: 18,
      padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 12),
      child: Row(
        children: [
          const AtlasLogo3D(size: 40),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title == 'Dashboard' ? 'Visão geral da operação' : title,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
          ),
          OutlinedButton.icon(
            onPressed: onSearch,
            icon: const Icon(Icons.search_rounded, size: 17),
            label: const Text('Buscar pedidos e telas'),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: onAssistant,
            icon: const Icon(Icons.auto_awesome_rounded, size: 17),
            label: const Text('Assistente'),
          ),
          const SizedBox(width: 5),
          notification,
          const SizedBox(width: 8),
          CircleAvatar(
            radius: 17,
            backgroundColor: colors.accent2,
            foregroundColor: Colors.white,
            child: Text(userName.isEmpty ? 'A' : userName[0].toUpperCase()),
          ),
          const SizedBox(width: 9),
          Text(userName, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
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
        .where((o) => q.isEmpty || '${o.id} ${o.cliente}'.toLowerCase().contains(q))
        .take(5);
    final pages = _navItems.where((e) => q.isEmpty || e.$1.toLowerCase().contains(q));
    return Dialog(
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620, maxHeight: 620),
        child: Glass(
          opacity: .96,
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
                  children: [
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
                        subtitle: Text('${order.status.label} · ${order.destino}'),
                        onTap: () {
                          Navigator.pop(context);
                          showOrderDetails(context, widget.store, order.id);
                        },
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text('Atalho: Ctrl+K ou Cmd+K', style: TextStyle(color: context.ac.muted, fontSize: 11)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DashboardPage extends StatelessWidget {
  const DashboardPage({
    required this.store,
    required this.onNavigate,
    required this.onSearch,
    super.key,
  });

  final AtlasStore store;
  final ValueChanged<String> onNavigate;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    final colors = context.ac;
    final role = store.settings.role;
    final alerts = [...store.lateOrders, ...store.divergentOrders]
      ..sort((a, b) => a.previsaoEntrega.compareTo(b.previsaoEntrega));
    final flow = store.flow(store.now.subtract(const Duration(days: 6)), store.now);
    final wide = MediaQuery.sizeOf(context).width >= 1100;
    return ListView(
      padding: EdgeInsets.all(
        MediaQuery.sizeOf(context).width < 600 ? 16 : 24,
      ),
      children: [
        Glass(
          radius: 22,
          padding: EdgeInsets.all(
            MediaQuery.sizeOf(context).width < 600 ? 18 : 24,
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final greeting = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    role == UserRole.motorista
                        ? 'MINHAS ROTAS'
                        : 'CENTRAL DE OPERAÇÕES',
                    style: TextStyle(
                      color: colors.accent,
                      fontSize: 11,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Olá, ${store.settings.userName}',
                    style: const TextStyle(
                      fontSize: 27,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    role == UserRole.motorista
                        ? 'Acompanhe as entregas vinculadas ao seu perfil.'
                        : 'Acompanhe pedidos, prazos e disponibilidade da frota.',
                    style: TextStyle(color: colors.muted),
                  ),
                ],
              );
              if (constraints.maxWidth <= 520) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    greeting,
                    const SizedBox(height: 16),
                    Button3D(
                      label: 'Criar Pedido',
                      icon: Icons.add_rounded,
                      onPressed: () => showOrderForm(context, store),
                    ),
                  ],
                );
              }
              return Row(
              children: [
                Expanded(child: greeting),
                const SizedBox(width: 20),
                if (role != UserRole.motorista)
                  Button3D(
                    label: 'Criar Pedido',
                    icon: Icons.add_rounded,
                    onPressed: () => showOrderForm(context, store),
                  ),
                ],
            );
          },
          ),
        ),
        const SizedBox(height: 20),
        if (store.settings.role != UserRole.motorista)
          LayoutBuilder(
            builder: (context, constraints) {
              final count = constraints.maxWidth > 1050
                  ? 4
                  : constraints.maxWidth > 600
                  ? 2
                  : 1;
              final cards = [
                KpiCard(
                  label: 'Total de envios',
                  value: store.totalOrders,
                  icon: Icons.inventory_2_rounded,
                  color: colors.accent2,
                  motion: IconMotion.pop,
                  onTap: () => onNavigate('Pedidos'),
                ),
                KpiCard(
                  label: 'Em trânsito',
                  value: store.inTransitCount,
                  icon: Icons.local_shipping_rounded,
                  color: colors.accent,
                  motion: IconMotion.drive,
                  loop: true,
                  onTap: () => onNavigate('Pedidos'),
                ),
                KpiCard(
                  label: 'Entregues no prazo',
                  value: store.deliveredOnTimeCount,
                  icon: Icons.task_alt_rounded,
                  color: colors.success,
                  motion: IconMotion.bounce,
                  onTap: () => onNavigate('Relatórios'),
                ),
                KpiCard(
                  label: 'Alertas e atrasos',
                  value: store.alertCount,
                  icon: Icons.warning_amber_rounded,
                  color: colors.danger,
                  motion: IconMotion.pulse,
                  loop: store.alertCount > 0,
                  onTap: () => onNavigate('Notificações'),
                ),
              ];
              return GridView.count(
                crossAxisCount: count,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: count == 1 ? 3.2 : wide ? 2.05 : 1.75,
                children: cards,
              );
            },
          ),
        if (store.settings.role == UserRole.motorista) ...[
          KpiCard(
            label: 'Entregas na minha rota',
            value: store.activeOrdersOf(store.settings.roleDriverId).length,
            icon: Icons.route_rounded,
            color: colors.accent,
            motion: IconMotion.drive,
            loop: true,
            onTap: () => onNavigate('Frota'),
          ),
        ],
        const SizedBox(height: 20),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            Button3D(
              label: 'Buscar pedido',
              icon: Icons.search_rounded,
              secondary: true,
              onPressed: onSearch,
            ),
            Button3D(
              label: 'Vincular carga',
              icon: Icons.link_rounded,
              secondary: true,
              onPressed: () => showAssignDialog(context, store),
            ),
            Button3D(
              label: 'Simular frete',
              icon: Icons.calculate_rounded,
              secondary: true,
              onPressed: () => showFreightDialog(context),
            ),
          ],
        ),
        const SizedBox(height: 20),
        if (store.settings.role != UserRole.motorista)
          LayoutBuilder(
            builder: (context, constraints) => constraints.maxWidth > 1050
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 3, child: _FlowChart(flow: flow)),
                      const SizedBox(width: 16),
                      Expanded(flex: 2, child: _StatusChart(store: store)),
                    ],
                  )
                : Column(
                    children: [
                      _FlowChart(flow: flow),
                      const SizedBox(height: 16),
                      _StatusChart(store: store),
                    ],
                  ),
          ),
        const SizedBox(height: 18),
        LayoutBuilder(
          builder: (context, constraints) => constraints.maxWidth > 1000
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: _AlertPanel(alerts: alerts, store: store),
                    ),
                    const SizedBox(width: 16),
                    Expanded(flex: 2, child: _ActivityPanel(store: store)),
                  ],
                )
              : Column(
                  children: [
                    _AlertPanel(alerts: alerts, store: store),
                    const SizedBox(height: 16),
                    _ActivityPanel(store: store),
                  ],
                ),
        ),
      ],
    );
  }
}

class _FlowChart extends StatelessWidget {
  const _FlowChart({required this.flow});

  final List<DayFlow> flow;

  @override
  Widget build(BuildContext context) {
    final colors = context.ac;
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Fluxo de entregas', subtitle: 'Envios e entregas · últimos 7 dias'),
          const SizedBox(height: 22),
          SizedBox(
            height: 210,
            child: BarChart(
              BarChartData(
                gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (_) => FlLine(color: colors.border, strokeWidth: .6)),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30, getTitlesWidget: (value, _) => Text('${value.toInt()}', style: TextStyle(color: colors.muted, fontSize: 10)))),
                  bottomTitles: AxisTitles(sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, _) {
                      final index = value.toInt();
                      if (index < 0 || index >= flow.length) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(fmtShort(flow[index].day), style: TextStyle(color: colors.muted, fontSize: 10)),
                      );
                    },
                  )),
                ),
                barGroups: [
                  for (var i = 0; i < flow.length; i++)
                    BarChartGroupData(
                      x: i,
                      barsSpace: 3,
                      barRods: [
                        BarChartRodData(toY: flow[i].created.toDouble(), color: colors.accent2, width: 8, borderRadius: BorderRadius.circular(3)),
                        BarChartRodData(toY: flow[i].delivered.toDouble(), color: colors.success, width: 8, borderRadius: BorderRadius.circular(3)),
                      ],
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          const _Legend(items: [('Envios', Color(0xFF2563EB)), ('Entregas', Color(0xFF059669))]),
        ],
      ),
    );
  }
}

class _StatusChart extends StatelessWidget {
  const _StatusChart({required this.store});

  final AtlasStore store;

  @override
  Widget build(BuildContext context) {
    final colors = context.ac;
    final distribution = store.statusDistribution();
    final statuses = OrderStatus.values;
    final palette = [colors.warning, colors.accent, colors.success, colors.danger];
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Pedidos por status', subtitle: 'Distribuição da operação'),
          const SizedBox(height: 12),
          SizedBox(
            height: 186,
            child: PieChart(
              PieChartData(
                centerSpaceRadius: 45,
                sectionsSpace: 3,
                sections: [
                  for (var i = 0; i < statuses.length; i++)
                    PieChartSectionData(
                      value: (distribution[statuses[i]] ?? 0).toDouble(),
                      color: palette[i],
                      radius: 36,
                      showTitle: false,
                    ),
                ],
              ),
            ),
          ),
          for (var i = 0; i < statuses.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  CircleAvatar(radius: 5, backgroundColor: palette[i]),
                  const SizedBox(width: 8),
                  Expanded(child: Text(statuses[i].label, style: TextStyle(color: colors.muted, fontSize: 12))),
                  Text('${distribution[statuses[i]]}', style: const TextStyle(fontWeight: FontWeight.w800)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.items});

  final List<(String, Color)> items;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 18,
    children: [
      for (final item in items)
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 9, height: 9, decoration: BoxDecoration(color: item.$2, borderRadius: BorderRadius.circular(3))),
            const SizedBox(width: 6),
            Text(item.$1, style: TextStyle(color: context.ac.muted, fontSize: 11)),
          ],
        ),
    ],
  );
}

class _AlertPanel extends StatelessWidget {
  const _AlertPanel({required this.alerts, required this.store});

  final List<Order> alerts;
  final AtlasStore store;

  @override
  Widget build(BuildContext context) {
    final colors = context.ac;
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Central de alertas',
            subtitle: alerts.isEmpty ? 'Nenhum risco operacional no momento' : '${alerts.length} pedido(s) precisam de atenção',
            trailing: alerts.isNotEmpty ? Icon3D(icon: Icons.notification_important_rounded, color: colors.danger, motion: IconMotion.pulse, loop: true, size: 38) : null,
          ),
          const SizedBox(height: 12),
          if (alerts.isEmpty)
            const EmptyState(title: 'Operação em dia', message: 'Atrasos e divergências aparecerão aqui.')
          else
            for (final order in alerts.take(5))
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.warning_amber_rounded, color: colors.danger),
                title: Text('${order.id} · ${order.cliente}', maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text(order.isLate(store.now) ? 'Entrega atrasada · ${order.destino}' : 'Pedido sem motorista disponível'),
                trailing: IconButton(
                  tooltip: 'Ver pedido',
                  onPressed: () => showOrderDetails(context, store, order.id),
                  icon: const Icon(Icons.chevron_right_rounded),
                ),
              ),
        ],
      ),
    );
  }
}

class _ActivityPanel extends StatelessWidget {
  const _ActivityPanel({required this.store});

  final AtlasStore store;

  @override
  Widget build(BuildContext context) {
    final colors = context.ac;
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Atividade recente', subtitle: 'Últimas atualizações da operação'),
          const SizedBox(height: 12),
          for (final activity in store.recentActivity(limit: 7))
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 7),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.circle, size: 8, color: colors.accent),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${activity.order.id} · ${activity.entry.label}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                        Text('${activity.order.cliente} · ${fmtAgo(activity.entry.date, store.now)}', style: TextStyle(color: colors.muted, fontSize: 11)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class OrdersPage extends StatefulWidget {
  const OrdersPage({required this.store, super.key});

  final AtlasStore store;

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  final _search = TextEditingController();
  OrderStatus? _status;
  bool _newestFirst = true;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.ac;
    final query = _search.text.trim().toLowerCase();
    final orders = widget.store.orders.where((o) {
      final matchesQuery = query.isEmpty ||
          '${o.id} ${o.cliente} ${o.origem} ${o.destino}'.toLowerCase().contains(query);
      return matchesQuery && (_status == null || o.status == _status);
    }).toList()
      ..sort((a, b) => _newestFirst
          ? b.dataEnvio.compareTo(a.dataEnvio)
          : a.dataEnvio.compareTo(b.dataEnvio));
    return ListView(
      padding: EdgeInsets.all(
        MediaQuery.sizeOf(context).width < 600 ? 16 : 24,
      ),
      children: [
        SectionHeader(
          title: 'Pedidos e rastreamento',
          subtitle: '${orders.length} pedidos encontrados · filtre por status, cliente ou código',
          trailing: Wrap(
            spacing: 8,
            children: [
              Button3D(
                label: 'Calculadora',
                icon: Icons.calculate_rounded,
                secondary: true,
                onPressed: () => showFreightDialog(context),
              ),
              Button3D(
                label: 'Criar Pedido',
                icon: Icons.add_rounded,
                onPressed: () => showOrderForm(context, widget.store),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        GlassCard(
          padding: const EdgeInsets.all(14),
          child: LayoutBuilder(
            builder: (context, constraints) => Wrap(
              spacing: 10,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: constraints.maxWidth < 340
                      ? constraints.maxWidth
                      : 340,
                  child: TextField(
                    controller: _search,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      isDense: true,
                      prefixIcon: Icon(Icons.search_rounded),
                      hintText: 'Buscar código, cliente ou destino...',
                    ),
                  ),
                ),
                SizedBox(
                  width: constraints.maxWidth < 210
                      ? constraints.maxWidth
                      : 210,
                  child: DropdownButtonFormField<OrderStatus?>(
                    initialValue: _status,
                    decoration: const InputDecoration(
                      isDense: true,
                      labelText: 'Status',
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('Todos os status'),
                      ),
                      for (final status in OrderStatus.values)
                        DropdownMenuItem(
                          value: status,
                          child: Text(status.label),
                        ),
                    ],
                    onChanged: (value) => setState(() => _status = value),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () => setState(() => _newestFirst = !_newestFirst),
                  icon: Icon(
                    _newestFirst ? Icons.south_rounded : Icons.north_rounded,
                  ),
                  label: Text(_newestFirst ? 'Mais recentes' : 'Mais antigos'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        if (orders.isEmpty)
          EmptyState(
            title: 'Nenhum pedido encontrado',
            message: 'Ajuste os filtros ou crie um pedido para começar.',
            action: Button3D(label: 'Criar Pedido', icon: Icons.add_rounded, onPressed: () => showOrderForm(context, widget.store)),
          )
        else
          for (final order in orders)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _OrderCard(order: order, store: widget.store),
            ),
        const SizedBox(height: 22),
        Row(
          children: [
            Icon(Icons.info_outline_rounded, color: colors.muted, size: 16),
            const SizedBox(width: 8),
            Expanded(child: Text('Atualizações e alterações são salvas localmente neste dispositivo.', style: TextStyle(color: colors.muted, fontSize: 11))),
          ],
        ),
      ],
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order, required this.store});

  final Order order;
  final AtlasStore store;

  @override
  Widget build(BuildContext context) {
    final colors = context.ac;
    final late = order.isLate(store.now);
    final driver = store.driverById(order.motoristaId);
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 13),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 760;
          final info = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(order.id, style: const TextStyle(fontWeight: FontWeight.w900)),
                    StatusChip(status: order.status, late: late),
                  ],
                ),
                const SizedBox(height: 4),
                Text(order.cliente, style: TextStyle(color: colors.muted, fontSize: 12)),
                const SizedBox(height: 5),
                Text('${order.origem}  →  ${order.destino}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
              ],
            );
          final details = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Previsão · ${fmtDate(order.previsaoEntrega)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                Text(driver == null ? 'Motorista não vinculado' : driver.nome, style: TextStyle(color: colors.muted, fontSize: 11)),
                const SizedBox(height: 4),
                Text(kStages[order.stage], style: TextStyle(color: colors.accent, fontSize: 11, fontWeight: FontWeight.w700)),
              ],
            );
          final actions = Wrap(
            spacing: 2,
            children: [
              IconButton(tooltip: 'Detalhes e rastreio', onPressed: () => showOrderDetails(context, store, order.id), icon: const Icon(Icons.visibility_outlined)),
              IconButton(tooltip: 'Editar', onPressed: order.isActive ? () => showOrderForm(context, store, order: order) : null, icon: const Icon(Icons.edit_outlined)),
              IconButton(tooltip: 'Etiqueta', onPressed: () => showLabelDialog(context, store, order), icon: const Icon(Icons.qr_code_2_rounded)),
              IconButton(tooltip: 'WhatsApp', onPressed: order.telefone.isEmpty ? null : () => sendWhatsApp(context, order), icon: const Icon(Icons.chat_rounded)),
              IconButton(
                tooltip: 'Excluir pedido',
                onPressed: () async {
                  final ok = await confirmDialog(
                    context,
                    title: 'Excluir ${order.id}?',
                    message: 'Esta ação remove o pedido deste dispositivo.',
                  );
                  if (ok) store.deleteOrder(order.id);
                },
                icon: Icon(Icons.delete_outline_rounded, color: colors.danger),
              ),
            ],
          );
          return compact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [info, const SizedBox(height: 12), details, const SizedBox(height: 8), actions],
                )
              : Row(
                  children: [
                    Expanded(flex: 3, child: info),
                    Expanded(flex: 2, child: details),
                    actions,
                  ],
                );
        },
      ),
    );
  }
}

class FleetPage extends StatelessWidget {
  const FleetPage({required this.store, super.key});

  final AtlasStore store;

  @override
  Widget build(BuildContext context) {
    final activeOrders = store.orders.where((o) => o.isActive && o.motoristaId != null).toList();
    final drivers = store.settings.role == UserRole.motorista
        ? store.drivers
              .where((driver) => driver.id == store.settings.roleDriverId)
              .toList()
        : store.drivers;
    return ListView(
      padding: EdgeInsets.all(
        MediaQuery.sizeOf(context).width < 600 ? 16 : 24,
      ),
      children: [
        SectionHeader(
          title: store.settings.role == UserRole.motorista ? 'Minhas rotas' : 'Frota e motoristas',
          subtitle: store.settings.role == UserRole.motorista
              ? 'Pedidos vinculados ao perfil atual'
              : '${store.availableDrivers} motoristas disponíveis · mapa de entregas ativas',
          trailing: store.settings.role == UserRole.admin
              ? Wrap(
                  spacing: 8,
                  children: [
                    Button3D(label: 'Vincular carga', icon: Icons.link_rounded, secondary: true, onPressed: () => showAssignDialog(context, store)),
                    Button3D(label: 'Novo motorista', icon: Icons.person_add_alt_1_rounded, onPressed: () => showDriverForm(context, store)),
                  ],
                )
              : null,
        ),
        const SizedBox(height: 18),
        _FleetMap(orders: activeOrders),
        const SizedBox(height: 18),
        LayoutBuilder(
          builder: (context, constraints) => GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: drivers.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: constraints.maxWidth > 1180 ? 3 : constraints.maxWidth > 700 ? 2 : 1,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              mainAxisExtent: constraints.maxWidth < 600 ? 280 : 240,
            ),
            itemBuilder: (context, index) {
              final driver = drivers[index];
              return _DriverCard(store: store, driver: driver);
            },
          ),
        ),
      ],
    );
  }
}

class _FleetMap extends StatelessWidget {
  const _FleetMap({required this.orders});

  final List<Order> orders;

  @override
  Widget build(BuildContext context) {
    final colors = context.ac;
    final positioned = orders.where((o) => orderPosition(o) != null).toList();
    final center = positioned.isEmpty
        ? const LatLng(-15.78, -47.93)
        : orderPosition(positioned.first)!;
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).width < 600 ? 250 : 340,
        child: Stack(
          children: [
            FlutterMap(
              options: MapOptions(initialCenter: center, initialZoom: positioned.length > 1 ? 4.2 : 5.5),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.atlas.log',
                ),
                if (positioned.isNotEmpty)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: [
                          for (final order in positioned)
                            if (orderPosition(order) != null) orderPosition(order)!,
                        ],
                        color: colors.accent2.withValues(alpha: .8),
                        strokeWidth: 3,
                      ),
                    ],
                  ),
                MarkerLayer(
                  markers: [
                    for (final order in positioned)
                      if (orderPosition(order) case final point?)
                        Marker(
                          point: point,
                          width: 42,
                          height: 42,
                          child: Tooltip(
                            message: '${order.id} · ${order.cliente}',
                            child: Icon3D(
                              icon: Icons.local_shipping_rounded,
                              color: colors.accent2,
                              motion: IconMotion.drive,
                              size: 38,
                              loop: true,
                            ),
                          ),
                        ),
                  ],
                ),
                const RichAttributionWidget(
                  attributions: [TextSourceAttribution('© OpenStreetMap contributors')],
                ),
              ],
            ),
            Positioned(
              left: 12,
              top: 12,
              child: Glass(
                radius: 12,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Text('Mapa de posições estimadas · ${positioned.length} cargas', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
              ),
            ),
            if (positioned.isEmpty)
              Center(
                child: Glass(
                  padding: const EdgeInsets.all(14),
                  child: Text('Vincule pedidos com cidades cadastradas para visualizar cargas.', style: TextStyle(color: colors.text)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DriverCard extends StatelessWidget {
  const _DriverCard({required this.store, required this.driver});

  final AtlasStore store;
  final Driver driver;

  @override
  Widget build(BuildContext context) {
    final colors = context.ac;
    final assigned = store.activeOrdersOf(driver.id);
    final driverColor = switch (driver.status) {
      DriverStatus.disponivel => colors.success,
      DriverStatus.emRota => colors.accent,
      DriverStatus.manutencao => colors.warning,
    };
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon3D(icon: Icons.person_rounded, color: driverColor, motion: driver.status == DriverStatus.emRota ? IconMotion.drive : IconMotion.tilt, loop: driver.status == DriverStatus.emRota, size: 44),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(driver.nome, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800)),
                    Text('${driver.veiculo} · ${driver.placa}', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: colors.muted, fontSize: 11)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: driverColor.withValues(alpha: .14),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  driver.status.label,
                  style: TextStyle(color: driverColor, fontSize: 11, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text('${assigned.length} entrega(s) ativa(s)', style: TextStyle(color: colors.muted, fontSize: 12)),
          const SizedBox(height: 6),
          if (assigned.isNotEmpty)
            Text(
              assigned.take(2).map((o) => '${o.id} · ${o.destino}').join('\n'),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, height: 1.4),
            )
          else
            Text('Sem pedidos em andamento', style: TextStyle(color: colors.muted, fontSize: 12)),
          const Spacer(),
          Wrap(
            spacing: 6,
            children: [
              if (store.settings.role == UserRole.admin)
                OutlinedButton.icon(
                  onPressed: () => showAssignDialog(context, store, driverId: driver.id),
                  icon: const Icon(Icons.link_rounded, size: 16),
                  label: const Text('Vincular carga'),
                ),
              if (assigned.length > 1)
                TextButton.icon(
                  onPressed: () => _showOptimizedRoute(context, driver, assigned),
                  icon: const Icon(Icons.alt_route_rounded, size: 16),
                  label: const Text('Otimizar rota'),
                ),
              if (store.settings.role == UserRole.admin)
                IconButton(
                  tooltip: 'Editar motorista',
                  onPressed: () => showDriverForm(context, store, driver: driver),
                  icon: const Icon(Icons.edit_outlined),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showOptimizedRoute(
    BuildContext context,
    Driver driver,
    List<Order> assigned,
  ) async {
    final start = cityPos(assigned.first.origem) ?? const LatLng(-23.5505, -46.6333);
    final stops = <RouteStop>[
      for (final order in assigned)
        if (cityPos(order.destino) case final point?) RouteStop(order, point),
    ];
    final route = optimizeRoute(start, stops);
    await showDialog<void>(
      context: context,
      builder: (context) => DialogShell(
        title: 'Rota otimizada · ${driver.nome}',
        actions: [
          Button3D(
            label: 'Fechar',
            secondary: true,
            onPressed: () => Navigator.pop(context),
          ),
        ],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Estimativa em linha reta: ${route.optimizedKm.toStringAsFixed(0)} km'),
            Text('Redução estimada: ${route.savedKm.toStringAsFixed(0)} km'),
            const SizedBox(height: 12),
            for (var i = 0; i < route.stops.length; i++)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(radius: 15, child: Text('${i + 1}')),
                title: Text(route.stops[i].order.id),
                subtitle: Text('${route.stops[i].order.cliente} · ${route.stops[i].order.destino}'),
              ),
            const SizedBox(height: 8),
            Text('Sequência calculada por vizinho mais próximo e refinamento 2-opt. Distâncias são aproximadas.', style: TextStyle(color: context.ac.muted, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

class PublicTrackingPage extends StatefulWidget {
  const PublicTrackingPage({required this.store, this.initialCode = '', super.key});

  final AtlasStore store;
  final String initialCode;

  @override
  State<PublicTrackingPage> createState() => _PublicTrackingPageState();
}

class _PublicTrackingPageState extends State<PublicTrackingPage> {
  late final TextEditingController _code = TextEditingController(text: widget.initialCode);
  Order? _order;
  bool _searched = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialCode.isNotEmpty) _lookup();
  }

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  void _lookup() {
    setState(() {
      _searched = true;
      _order = widget.store.orderById(_code.text.trim().toUpperCase());
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.ac;
    final order = _order;
    return Scaffold(
      appBar: AppBar(title: const Text('Rastreamento ATLAS-LOG')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 28),
                  const Icon3D(icon: Icons.local_shipping_rounded, color: Color(0xFF0891B2), size: 66, motion: IconMotion.drive, loop: true),
                  const SizedBox(height: 16),
                  const Text('Acompanhe sua entrega', textAlign: TextAlign.center, style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 6),
                  Text('Digite o código de rastreio informado pela transportadora.', textAlign: TextAlign.center, style: TextStyle(color: colors.muted)),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _code,
                          textCapitalization: TextCapitalization.characters,
                          onSubmitted: (_) => _lookup(),
                          decoration: const InputDecoration(labelText: 'Código de rastreio', hintText: 'ATL-2400'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Button3D(label: 'Rastrear', icon: Icons.search_rounded, onPressed: _lookup),
                    ],
                  ),
                  if (_searched && order == null) ...[
                    const SizedBox(height: 18),
                    const EmptyState(title: 'Pedido não localizado', message: 'Confira o código e tente novamente.'),
                  ],
                  if (order != null) ...[
                    const SizedBox(height: 20),
                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(child: Text('${order.id} · ${order.cliente}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17))),
                              StatusChip(status: order.status, late: order.isLate(widget.store.now)),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Text('${order.origem}  →  ${order.destino}', style: TextStyle(color: colors.muted)),
                          const SizedBox(height: 6),
                          Text('Previsão de entrega: ${fmtDate(order.previsaoEntrega)}', style: const TextStyle(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 20),
                          for (var i = 0; i < kStages.length; i++)
                            _TrackingStage(order: order, index: i),
                          if (order.status == OrderStatus.cancelado)
                            Text('Este pedido foi cancelado.', style: TextStyle(color: colors.danger, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  Text('Informações exibidas correspondem aos dados locais de demonstração.', textAlign: TextAlign.center, style: TextStyle(color: colors.muted, fontSize: 11)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrackingStage extends StatelessWidget {
  const _TrackingStage({required this.order, required this.index});

  final Order order;
  final int index;

  @override
  Widget build(BuildContext context) {
    final colors = context.ac;
    final done = index <= order.stage && !order.cancelled;
    final entry = order.historico.where((e) => e.label == kStages[index]).firstOrNull;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Icon3D(
                icon: const [Icons.assignment_turned_in_rounded, Icons.inventory_2_rounded, Icons.local_shipping_rounded, Icons.route_rounded, Icons.verified_rounded][index],
                color: done ? colors.success : colors.border,
                size: 40,
                motion: index == 2 ? IconMotion.drive : IconMotion.pop,
                loop: index == order.stage && order.isActive,
                muted: !done,
              ),
              if (index < kStages.length - 1)
                Container(width: 2, height: 20, color: done ? colors.success : colors.border),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 7),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(kStages[index], style: TextStyle(fontWeight: FontWeight.w800, color: done ? colors.text : colors.muted)),
                  if (entry != null) Text(fmtDateTime(entry.date), style: TextStyle(color: colors.muted, fontSize: 11)),
                ],
              ),
            ),
          ),
          if (index == order.stage && order.isActive)
            Text('ATUAL', style: TextStyle(color: colors.accent, fontSize: 10, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}
