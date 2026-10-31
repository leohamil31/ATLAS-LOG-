part of '../logistics_pages.dart';

// Mapa de design:
//   DESIGN-SLOT[order-card] _OrderCard (GlassCard + StatusChip + ações)
//   MOTION-HOOK[list]       AnimatedItems: entrada/saída ao filtrar/paginar/excluir
//   Estados: vazio (EmptyState), paginação, filtros (chips/datas)

// Pedidos: filtros, busca, paginação e lista com entrada/saída animadas.

class OrdersPage extends StatefulWidget {
  const OrdersPage({required this.store, super.key});

  final AtlasStore store;

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  static const _pageSize = 20;

  final _search = TextEditingController();
  OrderStatus? _status;
  String? _driverId;
  DateTimeRange? _dateRange;
  int _page = 0;
  bool _newestFirst = true;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _selectDateRange() async {
    final now = widget.store.now;
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: now.add(const Duration(days: 365)),
      initialDateRange:
          _dateRange ??
          DateTimeRange(start: now.subtract(const Duration(days: 6)), end: now),
    );
    if (range == null) return;
    setState(() {
      _dateRange = range;
      _page = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.ac;
    final query = _search.text.trim().toLowerCase();
    final orders =
        widget.store.orders.where((o) {
          final driver = widget.store.driverById(o.motoristaId);
          final searchable =
              '${o.id} ${o.cliente} ${o.origem} ${o.destino} '
                      '${driver?.nome ?? ''} ${driver?.placa ?? ''} ${driver?.veiculo ?? ''}'
                  .toLowerCase();
          final matchesQuery = query.isEmpty || searchable.contains(query);
          final matchesStatus = _status == null || o.status == _status;
          final matchesDriver = _driverId == null || o.motoristaId == _driverId;
          final matchesDate =
              _dateRange == null ||
              (!o.dataEnvio.isBefore(
                    DateTime(
                      _dateRange!.start.year,
                      _dateRange!.start.month,
                      _dateRange!.start.day,
                    ),
                  ) &&
                  o.dataEnvio.isBefore(
                    DateTime(
                      _dateRange!.end.year,
                      _dateRange!.end.month,
                      _dateRange!.end.day + 1,
                    ),
                  ));
          return matchesQuery && matchesStatus && matchesDriver && matchesDate;
        }).toList()..sort(
          (a, b) => _newestFirst
              ? b.dataEnvio.compareTo(a.dataEnvio)
              : a.dataEnvio.compareTo(b.dataEnvio),
        );
    final pageCount = orders.isEmpty
        ? 1
        : (orders.length + _pageSize - 1) ~/ _pageSize;
    final currentPage = _page.clamp(0, pageCount - 1);
    final visibleOrders = orders.skip(currentPage * _pageSize).take(_pageSize);
    return ListView(
      padding: EdgeInsets.all(MediaQuery.sizeOf(context).width < 600 ? 16 : 24),
      children: [
        SectionHeader(
          title: 'Pedidos e rastreamento',
          subtitle:
              '${orders.length} pedidos encontrados · filtre por status, motorista ou período; busque também por placa',
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
                    onChanged: (_) => setState(() => _page = 0),
                    decoration: const InputDecoration(
                      isDense: true,
                      prefixIcon: Icon(Icons.search_rounded),
                      hintText: 'Buscar pedido, motorista ou placa...',
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
                    onChanged: (value) => setState(() {
                      _status = value;
                      _page = 0;
                    }),
                  ),
                ),
                SizedBox(
                  width: constraints.maxWidth < 230
                      ? constraints.maxWidth
                      : 230,
                  child: DropdownButtonFormField<String?>(
                    isExpanded: true,
                    initialValue: _driverId,
                    decoration: const InputDecoration(
                      isDense: true,
                      labelText: 'Motorista',
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('Todos os motoristas'),
                      ),
                      for (final driver in widget.store.drivers)
                        DropdownMenuItem(
                          value: driver.id,
                          child: Text(
                            '${driver.nome} · ${driver.placa}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: (value) => setState(() {
                      _driverId = value;
                      _page = 0;
                    }),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _selectDateRange,
                  icon: const Icon(Icons.date_range_rounded),
                  label: Text(
                    _dateRange == null
                        ? 'Período'
                        : '${fmtDate(_dateRange!.start)} – ${fmtDate(_dateRange!.end)}',
                  ),
                ),
                if (_dateRange != null)
                  IconButton(
                    tooltip: 'Limpar período',
                    onPressed: () => setState(() {
                      _dateRange = null;
                      _page = 0;
                    }),
                    icon: const Icon(Icons.close_rounded),
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
            action: Button3D(
              label: 'Criar Pedido',
              icon: Icons.add_rounded,
              onPressed: () => showOrderForm(context, widget.store),
            ),
          )
        else
          // Entrada escalonada na carga; ao filtrar/paginar/excluir, cards
          // novos abrem espaço e removidos deslizam para fora (diff por id).
          AnimatedItems<Order>(
            items: visibleOrders.toList(),
            keyOf: (order) => order.id,
            spacing: 10,
            itemBuilder: (context, order, _) =>
                _OrderCard(order: order, store: widget.store),
          ),
        if (orders.isNotEmpty && pageCount > 1)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Text(
                  'Página ${currentPage + 1} de $pageCount',
                  style: TextStyle(color: colors.muted),
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Página anterior',
                  onPressed: currentPage > 0
                      ? () => setState(() => _page = currentPage - 1)
                      : null,
                  icon: const Icon(Icons.chevron_left_rounded),
                ),
                IconButton(
                  tooltip: 'Próxima página',
                  onPressed: currentPage < pageCount - 1
                      ? () => setState(() => _page = currentPage + 1)
                      : null,
                  icon: const Icon(Icons.chevron_right_rounded),
                ),
              ],
            ),
          ),
        const SizedBox(height: 22),
        Row(
          children: [
            Icon(Icons.info_outline_rounded, color: colors.muted, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Atualizações e alterações são salvas localmente neste dispositivo.',
                style: TextStyle(color: colors.muted, fontSize: 11),
              ),
            ),
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
                  Text(
                    order.id,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  StatusChip(status: order.status, late: late),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                order.cliente,
                style: TextStyle(color: colors.muted, fontSize: 12),
              ),
              const SizedBox(height: 5),
              Text(
                '${order.origem}  →  ${order.destino}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12),
              ),
            ],
          );
          final details = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Previsão · ${fmtDate(order.previsaoEntrega)}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                driver == null ? 'Motorista não vinculado' : driver.nome,
                style: TextStyle(color: colors.muted, fontSize: 11),
              ),
              const SizedBox(height: 4),
              Text(
                kStages[order.stage],
                style: TextStyle(
                  color: colors.accent,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          );
          final actions = Wrap(
            spacing: 2,
            children: [
              IconButton(
                tooltip: 'Detalhes e rastreio',
                onPressed: () => showOrderDetails(context, store, order.id),
                icon: const Icon(Icons.visibility_outlined),
              ),
              IconButton(
                tooltip: 'Editar',
                onPressed: order.isActive
                    ? () => showOrderForm(context, store, order: order)
                    : null,
                icon: const Icon(Icons.edit_outlined),
              ),
              IconButton(
                tooltip: 'Etiqueta',
                onPressed: () => showLabelDialog(context, store, order),
                icon: const Icon(Icons.qr_code_2_rounded),
              ),
              IconButton(
                tooltip: 'WhatsApp',
                onPressed: order.telefone.isEmpty
                    ? null
                    : () => sendWhatsApp(context, order),
                icon: const Icon(Icons.chat_rounded),
              ),
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
                  children: [
                    info,
                    const SizedBox(height: 12),
                    details,
                    const SizedBox(height: 8),
                    actions,
                  ],
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
