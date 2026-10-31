part of '../logistics_pages.dart';

// Mapa de design:
//   DESIGN-SLOT[tracking-hero] cabeçalho público com Icon3D (caminhão em loop)
//   DESIGN-SLOT[timeline]      _TrackingStage — etapas do rastreio

// Página pública de rastreio (/#/rastreio?codigo=...).

class PublicTrackingPage extends StatefulWidget {
  const PublicTrackingPage({
    required this.store,
    this.initialCode = '',
    super.key,
  });

  final AtlasStore store;
  final String initialCode;

  @override
  State<PublicTrackingPage> createState() => _PublicTrackingPageState();
}

class _PublicTrackingPageState extends State<PublicTrackingPage> {
  late final TextEditingController _code = TextEditingController(
    text: widget.initialCode,
  );
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
      appBar: AppBar(title: const Text('Rastreamento ATLAS LOG')),
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
                  const Icon3D(
                    icon: Icons.local_shipping_rounded,
                    color: Color(0xFF0891B2),
                    size: 66,
                    motion: IconMotion.drive,
                    loop: true,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Acompanhe sua entrega',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Digite o código de rastreio informado pela transportadora.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: colors.muted),
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _code,
                          textCapitalization: TextCapitalization.characters,
                          onSubmitted: (_) => _lookup(),
                          decoration: const InputDecoration(
                            labelText: 'Código de rastreio',
                            hintText: 'ATL-2400',
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Button3D(
                        label: 'Rastrear',
                        icon: Icons.search_rounded,
                        onPressed: _lookup,
                      ),
                    ],
                  ),
                  if (_searched && order == null) ...[
                    const SizedBox(height: 18),
                    const EmptyState(
                      title: 'Pedido não localizado',
                      message: 'Confira o código e tente novamente.',
                    ),
                  ],
                  if (order != null) ...[
                    const SizedBox(height: 20),
                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${order.id} · ${order.cliente}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 17,
                                  ),
                                ),
                              ),
                              StatusChip(
                                status: order.status,
                                late: order.isLate(widget.store.now),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Text(
                            '${order.origem}  →  ${order.destino}',
                            style: TextStyle(color: colors.muted),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Previsão de entrega: ${fmtDate(order.previsaoEntrega)}',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 20),
                          for (var i = 0; i < kStages.length; i++)
                            _TrackingStage(order: order, index: i),
                          if (order.status == OrderStatus.cancelado)
                            Text(
                              'Este pedido foi cancelado.',
                              style: TextStyle(
                                color: colors.danger,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  Text(
                    'Informações exibidas correspondem aos dados locais de demonstração.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: colors.muted, fontSize: 11),
                  ),
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
    final entry = order.historico
        .where((e) => e.label == kStages[index])
        .firstOrNull;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Icon3D(
                icon: const [
                  Icons.assignment_turned_in_rounded,
                  Icons.inventory_2_rounded,
                  Icons.local_shipping_rounded,
                  Icons.route_rounded,
                  Icons.verified_rounded,
                ][index],
                color: done ? colors.success : colors.border,
                size: 40,
                motion: index == 2 ? IconMotion.drive : IconMotion.pop,
                loop: index == order.stage && order.isActive,
                muted: !done,
              ),
              if (index < kStages.length - 1)
                Container(
                  width: 2,
                  height: 20,
                  color: done ? colors.success : colors.border,
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 7),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    kStages[index],
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: done ? colors.text : colors.muted,
                    ),
                  ),
                  if (entry != null)
                    Text(
                      fmtDateTime(entry.date),
                      style: TextStyle(color: colors.muted, fontSize: 11),
                    ),
                ],
              ),
            ),
          ),
          if (index == order.stage && order.isActive)
            Text(
              'ATUAL',
              style: TextStyle(
                color: colors.accent,
                fontSize: 10,
                fontWeight: FontWeight.w900,
              ),
            ),
        ],
      ),
    );
  }
}
