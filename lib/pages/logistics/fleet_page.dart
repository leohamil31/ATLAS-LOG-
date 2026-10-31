part of '../logistics_pages.dart';

// Mapa de design:
//   DESIGN-SLOT[map]         _FleetMap (flutter_map/OSM) — rótulos em Glass com blur
//   DESIGN-SLOT[driver-card] _DriverCard (Icon3D + status do motorista)
//   MOTION-HOOK[grid]        cards entram com FadeSlideIn por índice

// Frota: mapa de posições estimadas e cards de motoristas.

class FleetPage extends StatelessWidget {
  const FleetPage({required this.store, super.key});

  final AtlasStore store;

  @override
  Widget build(BuildContext context) {
    final activeOrders = store.orders
        .where((o) => o.isActive && o.motoristaId != null)
        .toList();
    final drivers = store.settings.role == UserRole.motorista
        ? store.drivers
              .where((driver) => driver.id == store.settings.roleDriverId)
              .toList()
        : store.drivers;
    return ListView(
      padding: EdgeInsets.all(MediaQuery.sizeOf(context).width < 600 ? 16 : 24),
      children: [
        SectionHeader(
          title: store.settings.role == UserRole.motorista
              ? 'Minhas rotas'
              : 'Frota e motoristas',
          subtitle: store.settings.role == UserRole.motorista
              ? 'Pedidos vinculados ao perfil atual'
              : '${store.availableDrivers} motoristas disponíveis · mapa de entregas ativas',
          trailing: store.settings.role == UserRole.admin
              ? Wrap(
                  spacing: 8,
                  children: [
                    Button3D(
                      label: 'Vincular carga',
                      icon: Icons.link_rounded,
                      secondary: true,
                      onPressed: () => showAssignDialog(context, store),
                    ),
                    Button3D(
                      label: 'Novo motorista',
                      icon: Icons.person_add_alt_1_rounded,
                      onPressed: () => showDriverForm(context, store),
                    ),
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
              crossAxisCount: constraints.maxWidth > 1180
                  ? 3
                  : constraints.maxWidth > 700
                  ? 2
                  : 1,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              mainAxisExtent: constraints.maxWidth < 600 ? 280 : 240,
            ),
            itemBuilder: (context, index) {
              final driver = drivers[index];
              return FadeSlideIn(
                key: ValueKey(driver.id),
                index: index,
                scale: 0.97,
                child: _DriverCard(store: store, driver: driver),
              );
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
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).width < 600 ? 250 : 340,
        child: Stack(
          children: [
            FlutterMap(
              options: MapOptions(
                initialCenter: center,
                initialZoom: positioned.length > 1 ? 4.2 : 5.5,
              ),
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
                            if (orderPosition(order) != null)
                              orderPosition(order)!,
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
                  attributions: [
                    TextSourceAttribution('© OpenStreetMap contributors'),
                  ],
                ),
              ],
            ),
            Positioned(
              left: 12,
              top: 12,
              child: Glass(
                radius: 12,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Text(
                  'Mapa de posições estimadas · ${positioned.length} cargas',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            if (positioned.isEmpty)
              Center(
                child: Glass(
                  padding: const EdgeInsets.all(14),
                  child: Text(
                    'Vincule pedidos com cidades cadastradas para visualizar cargas.',
                    style: TextStyle(color: colors.text),
                  ),
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
              Icon3D(
                icon: Icons.person_rounded,
                color: driverColor,
                motion: driver.status == DriverStatus.emRota
                    ? IconMotion.drive
                    : IconMotion.tilt,
                loop: driver.status == DriverStatus.emRota,
                size: 44,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      driver.nome,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    Text(
                      '${driver.veiculo} · ${driver.placa}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: colors.muted, fontSize: 11),
                    ),
                  ],
                ),
              ),
              Text(
                driver.status.label,
                style: TextStyle(
                  color: driverColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            '${assigned.length} entrega(s) ativa(s)',
            style: TextStyle(color: colors.muted, fontSize: 12),
          ),
          const SizedBox(height: 6),
          if (assigned.isNotEmpty)
            Text(
              assigned.take(2).map((o) => '${o.id} · ${o.destino}').join('\n'),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, height: 1.4),
            )
          else
            Text(
              'Sem pedidos em andamento',
              style: TextStyle(color: colors.muted, fontSize: 12),
            ),
          const Spacer(),
          Wrap(
            spacing: 6,
            children: [
              if (store.settings.role == UserRole.admin)
                OutlinedButton.icon(
                  onPressed: () =>
                      showAssignDialog(context, store, driverId: driver.id),
                  icon: const Icon(Icons.link_rounded, size: 16),
                  label: const Text('Vincular carga'),
                ),
              if (assigned.length > 1)
                TextButton.icon(
                  onPressed: () =>
                      _showOptimizedRoute(context, driver, assigned),
                  icon: const Icon(Icons.alt_route_rounded, size: 16),
                  label: const Text('Otimizar rota'),
                ),
              if (store.settings.role == UserRole.admin)
                IconButton(
                  tooltip: 'Editar motorista',
                  onPressed: () =>
                      showDriverForm(context, store, driver: driver),
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
    final start =
        cityPos(assigned.first.origem) ?? const LatLng(-23.5505, -46.6333);
    final stops = <RouteStop>[
      for (final order in assigned)
        if (cityPos(order.destino) case final point?) RouteStop(order, point),
    ];
    final route = optimizeRoute(start, stops);
    await showAtlasDialog<void>(
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
            Text(
              'Estimativa em linha reta: ${route.optimizedKm.toStringAsFixed(0)} km',
            ),
            Text('Redução estimada: ${route.savedKm.toStringAsFixed(0)} km'),
            const SizedBox(height: 12),
            for (var i = 0; i < route.stops.length; i++)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(radius: 15, child: Text('${i + 1}')),
                title: Text(route.stops[i].order.id),
                subtitle: Text(
                  '${route.stops[i].order.cliente} · ${route.stops[i].order.destino}',
                ),
              ),
            const SizedBox(height: 8),
            Text(
              'Sequência calculada por vizinho mais próximo e refinamento 2-opt. Distâncias são aproximadas.',
              style: TextStyle(color: context.ac.muted, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
