import 'package:flutter/material.dart';

import '../core/format.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../services/export.dart';
import '../services/report_pdf.dart';
import '../services/store.dart';
import '../widgets/button3d.dart';
import '../widgets/common.dart';
import '../widgets/order_dialogs.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({required this.store, super.key});

  final AtlasStore store;

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  DateTime _from = DateTime.now().subtract(const Duration(days: 6));
  DateTime _to = DateTime.now();
  String _period = '7 dias';

  List<Order> get _orders => widget.store.ordersInRange(_from, _to);

  Future<void> _selectRange() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: widget.store.now.add(const Duration(days: 365)),
      initialDateRange: DateTimeRange(start: _from, end: _to),
    );
    if (range == null) return;
    setState(() {
      _period = 'Personalizado';
      _from = range.start;
      _to = range.end;
    });
  }

  void _setPeriod(String period) {
    final now = widget.store.now;
    setState(() {
      _period = period;
      _to = now;
      _from = switch (period) {
        'Mês atual' => DateTime(now.year, now.month),
        _ => now.subtract(const Duration(days: 6)),
      };
    });
  }

  Future<bool> _exportCsv() async {
    try {
      await saveCsv(
        'atlas-relatorio-${fmtDate(_from).replaceAll('/', '-')}.csv',
        ordersToCsv(widget.store, _orders),
      );
      if (mounted) toast(context, 'Relatório CSV exportado.');
      return true;
    } catch (error, stackTrace) {
      debugPrint('Falha ao exportar CSV: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (mounted) toast(context, 'Falha ao exportar CSV: $error', error: true);
      return false;
    }
  }

  Future<bool> _exportPdf() async {
    try {
      await printReport(widget.store, _orders, _from, _to);
      return true;
    } catch (error, stackTrace) {
      debugPrint('Falha ao gerar PDF: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (mounted) toast(context, 'Falha ao gerar PDF: $error', error: true);
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.ac;
    final orders = _orders;
    final expenses = widget.store.fleetExpenses;
    final fuel = widget.store.drivers.fold<double>(
      0,
      (sum, driver) => sum + driver.totalDespesas(ExpenseType.combustivel),
    );
    final revenue = orders
        .where((order) => order.status == OrderStatus.entregue)
        .fold<double>(0, (sum, order) => sum + _estimateFreight(order));
    return ListView(
      padding: EdgeInsets.all(
        MediaQuery.sizeOf(context).width < 600 ? 16 : 24,
      ),
      children: [
        SectionHeader(
          title: 'Relatórios e indicadores',
          subtitle:
              'Período ${fmtDate(_from)} a ${fmtDate(_to)} · ${orders.length} envios',
          trailing: Wrap(
            spacing: 8,
            children: [
              Button3D(
                label: 'Exportar CSV',
                icon: Icons.table_view_rounded,
                secondary: true,
                onAction: _exportCsv,
              ),
              Button3D(
                label: 'Exportar PDF',
                icon: Icons.picture_as_pdf_rounded,
                onAction: _exportPdf,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final period in ['7 dias', 'Mês atual'])
              ChoiceChip(
                label: Text(period),
                selected: _period == period,
                onSelected: (_) => _setPeriod(period),
              ),
            ActionChip(
              avatar: const Icon(Icons.date_range_rounded, size: 17),
              label: Text(
                _period == 'Personalizado'
                    ? 'Período personalizado'
                    : 'Escolher datas',
              ),
              onPressed: _selectRange,
            ),
          ],
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) => GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: constraints.maxWidth > 1000
                ? 4
                : constraints.maxWidth > 600
                ? 2
                : 1,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: constraints.maxWidth > 600 ? 2.1 : 2.8,
            children: [
              _FinanceCard(
                label: 'Faturamento estimado',
                value: _money(revenue),
                icon: Icons.payments_rounded,
                color: colors.success,
              ),
              _FinanceCard(
                label: 'Despesas da frota',
                value: _money(expenses),
                icon: Icons.account_balance_wallet_rounded,
                color: colors.warning,
              ),
              _FinanceCard(
                label: 'Combustível',
                value: _money(fuel),
                icon: Icons.local_gas_station_rounded,
                color: colors.accent,
              ),
              _FinanceCard(
                label: 'Custo por km',
                value:
                    '${_money(widget.store.fleetKm <= 0 ? 0 : expenses / widget.store.fleetKm)}/km',
                icon: Icons.speed_rounded,
                color: colors.accent2,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeader(
                title: 'Resumo do período',
                subtitle: 'Indicadores calculados com os dados locais',
              ),
              const SizedBox(height: 12),
              _SummaryRow(label: 'Pedidos criados', value: '${orders.length}'),
              _SummaryRow(
                label: 'Em trânsito',
                value:
                    '${orders.where((o) => o.status == OrderStatus.emTransito).length}',
              ),
              _SummaryRow(
                label: 'Entregues no prazo',
                value: '${orders.where((o) => o.deliveredOnTime).length}',
              ),
              _SummaryRow(
                label: 'Atrasados atualmente',
                value:
                    '${orders.where((o) => o.isLate(widget.store.now)).length}',
              ),
              const SizedBox(height: 10),
              Text(
                'O faturamento estimado usa a fórmula demonstrativa de frete; não substitui dados contábeis.',
                style: TextStyle(color: colors.muted, fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    );
  }

  double _estimateFreight(Order order) => 85 + order.pesoKg * .3;

  String _money(double value) =>
      'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';
}

class _FinanceCard extends StatelessWidget {
  const _FinanceCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: context.ac.muted, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(
      children: [
        Expanded(
          child: Text(label, style: TextStyle(color: context.ac.muted)),
        ),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
      ],
    ),
  );
}

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({required this.store, super.key});

  final AtlasStore store;

  @override
  Widget build(BuildContext context) {
    final colors = context.ac;
    return ListView(
      padding: EdgeInsets.all(
        MediaQuery.sizeOf(context).width < 600 ? 16 : 24,
      ),
      children: [
        SectionHeader(
          title: 'Central de notificações',
          subtitle: '${store.unreadCount} não lida(s)',
          trailing: Wrap(
            spacing: 8,
            children: [
              TextButton.icon(
                onPressed: store.markAllRead,
                icon: const Icon(Icons.done_all_rounded),
                label: const Text('Marcar todas como lidas'),
              ),
              TextButton.icon(
                onPressed: store.clearNotifications,
                icon: const Icon(Icons.delete_sweep_rounded),
                label: const Text('Limpar'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (store.notifications.isEmpty)
          const EmptyState(
            title: 'Sem notificações',
            message: 'Novos eventos operacionais serão exibidos aqui.',
          )
        else
          for (final notification in store.notifications)
            Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: GlassCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    switch (notification.tipo) {
                      NotificationType.info => Icons.info_outline_rounded,
                      NotificationType.sucesso =>
                        Icons.check_circle_outline_rounded,
                      NotificationType.alerta => Icons.warning_amber_rounded,
                    },
                    color: switch (notification.tipo) {
                      NotificationType.info => colors.accent,
                      NotificationType.sucesso => colors.success,
                      NotificationType.alerta => colors.danger,
                    },
                  ),
                  title: Text(
                    notification.mensagem,
                    style: TextStyle(
                      fontWeight: notification.lida
                          ? FontWeight.w500
                          : FontWeight.w800,
                    ),
                  ),
                  subtitle: Text(fmtAgo(notification.data, store.now)),
                  trailing: notification.lida
                      ? const Icon(Icons.done_rounded)
                      : TextButton(
                          onPressed: () => store.markRead(notification.id),
                          child: const Text('Marcar lida'),
                        ),
                  onTap: notification.lida
                      ? null
                      : () => store.markRead(notification.id),
                ),
              ),
            ),
      ],
    );
  }
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({required this.store, super.key});

  final AtlasStore store;

  @override
  Widget build(BuildContext context) {
    final colors = context.ac;
    return ListView(
      padding: EdgeInsets.all(
        MediaQuery.sizeOf(context).width < 600 ? 16 : 24,
      ),
      children: [
        const SectionHeader(
          title: 'Configurações',
          subtitle: 'Preferências, perfil de demonstração e dados locais',
        ),
        const SizedBox(height: 16),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Preferências',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                secondary: const Icon(Icons.dark_mode_rounded),
                title: const Text('Tema escuro'),
                subtitle: const Text(
                  'Aplica a preferência em todo o dashboard',
                ),
                value: store.settings.darkMode,
                onChanged: (value) => store.updateSettings(
                  (settings) => settings.darkMode = value,
                ),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                secondary: const Icon(Icons.volume_up_rounded),
                title: const Text('Alertas sonoros'),
                subtitle: const Text('Som ao criar alertas operacionais'),
                value: store.settings.sound,
                onChanged: (value) =>
                    store.updateSettings((settings) => settings.sound = value),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                secondary: const Icon(Icons.person_add_alt_1_rounded),
                title: const Text(
                  'Vincular motorista disponível automaticamente',
                ),
                value: store.settings.autoAssignDriver,
                onChanged: (value) => store.updateSettings(
                  (settings) => settings.autoAssignDriver = value,
                ),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.event_available_rounded),
                title: const Text('Prazo padrão de entrega'),
                subtitle: Text('${store.settings.defaultDeliveryDays} dias'),
                trailing: DropdownButton<int>(
                  value: store.settings.defaultDeliveryDays.clamp(1, 14),
                  items: [
                    for (var day = 1; day <= 14; day++)
                      DropdownMenuItem(value: day, child: Text('$day dias')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      store.updateSettings(
                        (settings) => settings.defaultDeliveryDays = value,
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Perfil e permissões (RBAC demonstrativo)',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                'A troca de perfil simula permissões na interface; não é autenticação de produção.',
                style: TextStyle(color: colors.muted, fontSize: 12),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<UserRole>(
                initialValue: store.settings.role,
                decoration: const InputDecoration(labelText: 'Perfil ativo'),
                items: [
                  for (final role in UserRole.values)
                    DropdownMenuItem(value: role, child: Text(role.label)),
                ],
                onChanged: (role) {
                  if (role != null) store.setRole(role);
                },
              ),
              if (store.settings.role == UserRole.motorista) ...[
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue:
                      store.drivers.any(
                        (driver) => driver.id == store.settings.roleDriverId,
                      )
                      ? store.settings.roleDriverId
                      : null,
                  decoration: const InputDecoration(
                    labelText: 'Motorista deste perfil',
                  ),
                  items: [
                    for (final driver in store.drivers)
                      DropdownMenuItem(
                        value: driver.id,
                        child: Text(driver.nome),
                      ),
                  ],
                  onChanged: (driverId) {
                    if (driverId != null) {
                      store.setRole(UserRole.motorista, driverId: driverId);
                    }
                  },
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Dados deste dispositivo',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  Button3D(
                    label: 'Exportar backup JSON',
                    icon: Icons.download_rounded,
                    secondary: true,
                    onAction: () async {
                      try {
                        await saveJson(
                          'atlas-backup.json',
                          store.exportBackup(),
                        );
                        if (context.mounted) {
                          toast(context, 'Backup JSON exportado.');
                        }
                        return true;
                      } catch (error, stackTrace) {
                        debugPrint('Falha ao exportar backup JSON: $error');
                        debugPrintStack(stackTrace: stackTrace);
                        if (context.mounted) {
                          toast(
                            context,
                            'Falha ao exportar backup: $error',
                            error: true,
                          );
                        }
                        return false;
                      }
                    },
                  ),
                  Button3D(
                    label: 'Resetar dados de teste',
                    icon: Icons.restart_alt_rounded,
                    color: colors.danger,
                    secondary: true,
                    onPressed: () async {
                      final confirmed = await confirmDialog(
                        context,
                        title: 'Resetar dados de teste?',
                        message:
                            'Pedidos, motoristas e notificações voltarão aos dados de demonstração. As preferências serão mantidas.',
                        confirmLabel: 'Resetar dados',
                      );
                      if (confirmed) {
                        store.resetData();
                        if (context.mounted) {
                          toast(context, 'Dados de demonstração restaurados.');
                        }
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'A persistência usa o armazenamento local do navegador/dispositivo. Para uso real, conecte autenticação e backend.',
                style: TextStyle(color: colors.muted, fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class AssistantDialog extends StatefulWidget {
  const AssistantDialog({
    required this.store,
    required this.onNavigate,
    super.key,
  });

  final AtlasStore store;
  final ValueChanged<String> onNavigate;

  @override
  State<AssistantDialog> createState() => _AssistantDialogState();
}

class _AssistantDialogState extends State<AssistantDialog> {
  final _input = TextEditingController();
  final List<(bool, String)> _messages = [
    (
      false,
      'Olá! Posso localizar pedidos por código, cliente, status ou mostrar motoristas.',
    ),
  ];
  List<Order> _orders = [];
  List<Driver> _drivers = [];

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _send() {
    final query = _input.text.trim();
    if (query.isEmpty) return;
    final normalized = query.toLowerCase();
    final orderIntent = RegExp(
      r'pedido|encomenda|entrega|atras|trânsito|transito|entregue|pendente|atl-',
    ).hasMatch(normalized);
    final driverIntent = RegExp(
      r'motorista|motoristas|frota|veículo|veiculo|placa',
    ).hasMatch(normalized);
    final status = normalized.contains('atras')
        ? null
        : normalized.contains('entregue')
        ? OrderStatus.entregue
        : normalized.contains('trânsito') || normalized.contains('transito')
        ? OrderStatus.emTransito
        : normalized.contains('pendente')
        ? OrderStatus.pendente
        : null;
    final lateOnly = normalized.contains('atras');
    final term = normalized
        .replaceAll(
          RegExp(
            r'pedido|encomenda|entrega|entregas|atrasados?|em|trânsito|transito|entregue|pendente|motoristas?|frota|veículos?|veiculos|placas?|mostrar|buscar|listar|quais|me|os|as|da|do|por|favor',
          ),
          ' ',
        )
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    final orderMatches = widget.store.orders
        .where((order) {
          final matchesStatus = status == null || order.status == status;
          final matchesLate = !lateOnly || order.isLate(widget.store.now);
          final matchesTerm =
              term.isEmpty ||
              '${order.id} ${order.cliente} ${order.origem} ${order.destino}'
                  .toLowerCase()
                  .contains(term);
          return matchesStatus && matchesLate && matchesTerm;
        })
        .take(10)
        .toList();
    final driverMatches = widget.store.drivers
        .where(
          (driver) =>
              term.isEmpty ||
              '${driver.nome} ${driver.veiculo} ${driver.placa}'
                  .toLowerCase()
                  .contains(term),
        )
        .take(10)
        .toList();
    setState(() {
      _messages
        ..add((true, query))
        ..add((
          false,
          orderIntent
              ? '${orderMatches.length} pedido(s) correspondem ao filtro.'
              : driverIntent
              ? '${driverMatches.length} motorista(s) correspondem à busca.'
              : 'Encontrei ${orderMatches.length} pedido(s) e ${driverMatches.length} motorista(s). Refine por código, cliente, status ou frota.',
        ));
      _orders = orderIntent || (!driverIntent && orderMatches.isNotEmpty)
          ? orderMatches
          : [];
      _drivers = driverIntent ? driverMatches : [];
      _input.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.ac;
    return Dialog(
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640, maxHeight: 720),
        child: Glass(
          opacity: .96,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 12, 10, 8),
                child: Row(
                  children: [
                    Icon(Icons.auto_awesome_rounded, color: colors.accent),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Assistente de logística',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 17,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  children: [
                    for (final message in _messages)
                      Align(
                        alignment: message.$1
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 480),
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(11),
                          decoration: BoxDecoration(
                            color: message.$1
                                ? colors.accent2.withValues(alpha: .2)
                                : colors.surface,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(message.$2),
                        ),
                      ),
                    for (final order in _orders)
                      ListTile(
                        dense: true,
                        leading: const Icon(Icons.inventory_2_rounded),
                        title: Text('${order.id} · ${order.cliente}'),
                        subtitle: Text(
                          '${order.status.label} · ${order.destino}',
                        ),
                        trailing: IconButton(
                          tooltip: 'Abrir pedido',
                          onPressed: () {
                            Navigator.pop(context);
                            showOrderDetails(context, widget.store, order.id);
                          },
                          icon: const Icon(Icons.open_in_new_rounded),
                        ),
                      ),
                    for (final driver in _drivers)
                      ListTile(
                        dense: true,
                        leading: const Icon(Icons.local_shipping_rounded),
                        title: Text(driver.nome),
                        subtitle: Text(
                          '${driver.veiculo} · ${driver.placa} · ${driver.status.label}',
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _input,
                        onSubmitted: (_) => _send(),
                        decoration: const InputDecoration(
                          hintText: 'Ex.: mostrar pedidos atrasados',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      tooltip: 'Enviar consulta',
                      onPressed: _send,
                      icon: const Icon(Icons.send_rounded),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  'Assistente local de demonstração; não envia dados a uma IA externa.',
                  style: TextStyle(color: colors.muted, fontSize: 10),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
