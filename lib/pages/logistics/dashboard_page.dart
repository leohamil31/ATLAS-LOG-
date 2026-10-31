part of '../logistics_pages.dart';

// Mapa de design:
//   DESIGN-SLOT[hero]   Glass(highlight) com saudação + "Criar Pedido"
//   DESIGN-SLOT[kpis]   KpiCard + Tilt3D (widgets/common.dart)
//   DESIGN-SLOT[charts] _FlowChart / _StatusChart (fl_chart) — cores via context.ac
//   MOTION-HOOK[stagger] seções entram escalonadas (staggered)

// Dashboard: hero, KPIs (com tilt 3D), gráficos, alertas e atividade.

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
    final flow = store.flow(
      store.now.subtract(const Duration(days: 6)),
      store.now,
    );
    final wide = MediaQuery.sizeOf(context).width >= 1100;
    return ListView(
      padding: EdgeInsets.all(MediaQuery.sizeOf(context).width < 600 ? 16 : 24),
      children: staggered([
        Glass(
          radius: AtlasRadius.xl,
          highlight: true,
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
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.7,
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
                  label: 'Veículos ativos',
                  value: store.drivers
                      .where((driver) => driver.status == DriverStatus.emRota)
                      .length,
                  icon: Icons.local_shipping_rounded,
                  color: colors.accent2,
                  motion: IconMotion.drive,
                  loop: true,
                  onTap: () => onNavigate('Frota'),
                ),
                KpiCard(
                  label: 'Entregas em andamento',
                  value: store.inTransitCount,
                  icon: Icons.inventory_2_rounded,
                  color: colors.accent,
                  motion: IconMotion.pop,
                  onTap: () => onNavigate('Pedidos'),
                ),
                KpiCard(
                  label: 'Atrasos',
                  value: store.delayedCount,
                  icon: Icons.schedule_rounded,
                  color: colors.warning,
                  motion: IconMotion.pulse,
                  loop: store.delayedCount > 0,
                  onTap: () => onNavigate('Notificações'),
                ),
                KpiCard(
                  label: 'Em manutenção',
                  value: store.drivers
                      .where(
                        (driver) => driver.status == DriverStatus.manutencao,
                      )
                      .length,
                  icon: Icons.build_circle_outlined,
                  color: colors.danger,
                  motion: IconMotion.bounce,
                  onTap: () => onNavigate('Frota'),
                ),
              ];
              return GridView.count(
                crossAxisCount: count,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: count == 1
                    ? 3.2
                    : wide
                    ? 2.05
                    : 1.75,
                children: [
                  for (var i = 0; i < cards.length; i++)
                    FadeSlideIn(index: i + 1, scale: 0.97, child: cards[i]),
                ],
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
      ]),
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
          const SectionHeader(
            title: 'Fluxo de entregas',
            subtitle: 'Envios e entregas · últimos 7 dias',
          ),
          const SizedBox(height: 22),
          SizedBox(
            height: 210,
            child: BarChart(
              BarChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) =>
                      FlLine(color: colors.border, strokeWidth: .6),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, _) => Text(
                        '${value.toInt()}',
                        style: TextStyle(color: colors.muted, fontSize: 10),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, _) {
                        final index = value.toInt();
                        if (index < 0 || index >= flow.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            fmtShort(flow[index].day),
                            style: TextStyle(color: colors.muted, fontSize: 10),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: [
                  for (var i = 0; i < flow.length; i++)
                    BarChartGroupData(
                      x: i,
                      barsSpace: 3,
                      barRods: [
                        BarChartRodData(
                          toY: flow[i].created.toDouble(),
                          color: colors.accent2,
                          width: 8,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        BarChartRodData(
                          toY: flow[i].delivered.toDouble(),
                          color: colors.success,
                          width: 8,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          const _Legend(
            items: [
              ('Envios', Color(0xFF2563EB)),
              ('Entregas', Color(0xFF059669)),
            ],
          ),
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
    final palette = [
      colors.warning,
      colors.accent,
      colors.success,
      colors.danger,
    ];
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Pedidos por status',
            subtitle: 'Distribuição da operação',
          ),
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
                  Expanded(
                    child: Text(
                      statuses[i].label,
                      style: TextStyle(color: colors.muted, fontSize: 12),
                    ),
                  ),
                  Text(
                    '${distribution[statuses[i]]}',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
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
            Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                color: item.$2,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              item.$1,
              style: TextStyle(color: context.ac.muted, fontSize: 11),
            ),
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
            subtitle: alerts.isEmpty
                ? 'Nenhum risco operacional no momento'
                : '${alerts.length} pedido(s) precisam de atenção',
            trailing: alerts.isNotEmpty
                ? Icon3D(
                    icon: Icons.notification_important_rounded,
                    color: colors.danger,
                    motion: IconMotion.pulse,
                    loop: true,
                    size: 38,
                  )
                : null,
          ),
          const SizedBox(height: 12),
          if (alerts.isEmpty)
            const EmptyState(
              title: 'Operação em dia',
              message: 'Atrasos e divergências aparecerão aqui.',
            )
          else
            for (final order in alerts.take(5))
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  Icons.warning_amber_rounded,
                  color: colors.danger,
                ),
                title: Text(
                  '${order.id} · ${order.cliente}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  order.isLate(store.now)
                      ? 'Entrega atrasada · ${order.destino}'
                      : 'Pedido sem motorista disponível',
                ),
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
          const SectionHeader(
            title: 'Atividade recente',
            subtitle: 'Últimas atualizações da operação',
          ),
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
                        Text(
                          '${activity.order.id} · ${activity.entry.label}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          '${activity.order.cliente} · ${fmtAgo(activity.entry.date, store.now)}',
                          style: TextStyle(color: colors.muted, fontSize: 11),
                        ),
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
