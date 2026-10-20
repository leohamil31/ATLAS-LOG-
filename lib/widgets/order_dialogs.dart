/// Diálogos de pedidos: formulário, detalhes com timeline 3D, vincular carga
/// e confirmação de exclusão.
library;

import 'package:flutter/material.dart';

import '../core/format.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../services/store.dart';
import '../widgets/button3d.dart';
import '../widgets/common.dart';
import '../widgets/extras_dialogs.dart';
import '../widgets/icon3d.dart';

Future<bool> confirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Excluir',
}) async {
  final ac = context.ac;
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => DialogShell(
      title: title,
      maxWidth: 440,
      actions: [
        Button3D(label: 'Voltar', secondary: true, onPressed: () => Navigator.pop(ctx, false)),
        Button3D(
          label: confirmLabel,
          icon: Icons.delete_rounded,
          color: ac.danger,
          onPressed: () => Navigator.pop(ctx, true),
        ),
      ],
      child: Text(message, style: TextStyle(color: ac.muted, height: 1.4)),
    ),
  );
  return result ?? false;
}

// ----------------------------------------------------------------- formulário

Future<void> showOrderForm(BuildContext context, AtlasStore store, {Order? order}) {
  return showDialog<void>(
    context: context,
    builder: (_) => _OrderForm(store: store, order: order),
  );
}

class _OrderForm extends StatefulWidget {
  const _OrderForm({required this.store, this.order});

  final AtlasStore store;
  final Order? order;

  @override
  State<_OrderForm> createState() => _OrderFormState();
}

class _OrderFormState extends State<_OrderForm> {
  final _key = GlobalKey<FormState>();
  late final _cliente = TextEditingController(text: widget.order?.cliente);
  late final _origem = TextEditingController(text: widget.order?.origem);
  late final _destino = TextEditingController(text: widget.order?.destino);
  late final _peso = TextEditingController(
    text: (widget.order?.pesoKg ?? 100).toStringAsFixed(0),
  );
  late final _tel = TextEditingController(text: widget.order?.telefone);
  late DateTime _previsao =
      widget.order?.previsaoEntrega ??
      widget.store.now.add(Duration(days: widget.store.settings.defaultDeliveryDays));

  bool get _editing => widget.order != null;

  @override
  void dispose() {
    _cliente.dispose();
    _origem.dispose();
    _destino.dispose();
    _peso.dispose();
    _tel.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final today = dayOnly(widget.store.now);
    final picked = await showDatePicker(
      context: context,
      initialDate: _previsao.isBefore(today) ? today : _previsao,
      firstDate: _editing ? today.subtract(const Duration(days: 365)) : today,
      lastDate: today.add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _previsao = picked);
  }

  bool _save() {
    if (!_key.currentState!.validate()) return false;
    final order = widget.order;
    final peso = double.tryParse(_peso.text.replaceAll(',', '.')) ?? 100;
    if (order == null) {
      final created = widget.store.createOrder(
        cliente: _cliente.text,
        origem: _origem.text,
        destino: _destino.text,
        previsao: _previsao,
        pesoKg: peso,
        telefone: _tel.text,
      );
      toast(context, 'Pedido ${created.id} criado.');
    } else {
      widget.store.updateOrder(
        order.id,
        cliente: _cliente.text,
        origem: _origem.text,
        destino: _destino.text,
        previsao: _previsao,
        pesoKg: peso,
        telefone: _tel.text,
      );
      toast(context, 'Pedido ${order.id} atualizado.');
    }
    return true;
  }

  String? _required(String? v) => (v == null || v.trim().isEmpty) ? 'Campo obrigatório' : null;

  @override
  Widget build(BuildContext context) {
    final ac = context.ac;
    return DialogShell(
      title: _editing ? 'Editar ${widget.order!.id}' : 'Novo pedido',
      actions: [
        Button3D(label: 'Cancelar', secondary: true, onPressed: () => Navigator.pop(context)),
        Button3D(
          label: 'Salvar',
          icon: Icons.save_rounded,
          successLabel: 'Salvo!',
          onAction: () {
            final ok = _save();
            if (ok) {
              // Fecha após o feedback de sucesso.
              Future<void>.delayed(const Duration(milliseconds: 650), () {
                if (mounted) Navigator.pop(context);
              });
            }
            return ok;
          },
        ),
      ],
      child: Form(
        key: _key,
        child: Column(
          children: [
            TextFormField(
              controller: _cliente,
              validator: _required,
              decoration: const InputDecoration(labelText: 'Cliente', prefixIcon: Icon(Icons.business_rounded)),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _origem,
              validator: _required,
              decoration: const InputDecoration(labelText: 'Origem', prefixIcon: Icon(Icons.trip_origin_rounded)),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _destino,
              validator: _required,
              decoration: const InputDecoration(labelText: 'Destino', prefixIcon: Icon(Icons.place_rounded)),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _peso,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Peso (kg)', prefixIcon: Icon(Icons.scale_rounded)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _tel,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(labelText: 'WhatsApp', prefixIcon: Icon(Icons.chat_rounded)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: _pickDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Previsão de entrega',
                  prefixIcon: Icon(Icons.event_rounded),
                ),
                child: Text(fmtDate(_previsao), style: TextStyle(color: ac.text)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -------------------------------------------------------------------- detalhes

Future<void> showOrderDetails(BuildContext context, AtlasStore store, String orderId) {
  return showDialog<void>(
    context: context,
    builder: (_) => ListenableBuilder(
      listenable: store,
      builder: (ctx, _) {
        final order = store.orderById(orderId);
        if (order == null) {
          return const DialogShell(title: 'Pedido', child: Text('Pedido não encontrado.'));
        }
        return _OrderDetails(store: store, order: order);
      },
    ),
  );
}

class _OrderDetails extends StatefulWidget {
  const _OrderDetails({required this.store, required this.order});

  final AtlasStore store;
  final Order order;

  @override
  State<_OrderDetails> createState() => _OrderDetailsState();
}

class _OrderDetailsState extends State<_OrderDetails> {
  int? _selected;

  static const _icons = [
    Icons.assignment_turned_in_rounded,
    Icons.inventory_2_rounded,
    Icons.local_shipping_rounded,
    Icons.route_rounded,
    Icons.verified_rounded,
  ];
  static const _motions = [
    IconMotion.pop,
    IconMotion.tilt,
    IconMotion.drive,
    IconMotion.bounce,
    IconMotion.pop,
  ];

  HistoryEntry? _entryFor(int stage) {
    for (final e in widget.order.historico) {
      if (e.label == kStages[stage]) return e;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final ac = context.ac;
    final o = widget.order;
    final store = widget.store;
    final driver = store.driverById(o.motoristaId);
    final late = o.isLate(store.now);
    final sel = _selected;

    Widget info(String label, String value) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 92, child: Text(label, style: TextStyle(color: ac.muted, fontSize: 13))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600))),
        ],
      ),
    );

    return DialogShell(
      title: 'Pedido ${o.id}',
      maxWidth: 620,
      actions: [
        if (o.isActive) ...[
          Button3D(
            label: 'Cancelar pedido',
            icon: Icons.block_rounded,
            color: ac.danger,
            secondary: true,
            onPressed: () async {
              final ok = await confirmDialog(
                context,
                title: 'Cancelar pedido?',
                message: 'O pedido ${o.id} será marcado como cancelado.',
                confirmLabel: 'Cancelar pedido',
              );
              if (ok) store.cancelOrder(o.id);
            },
          ),
          Button3D(
            label: 'Avançar: ${kStages[o.stage + 1]}',
            icon: Icons.arrow_forward_rounded,
            color: ac.success,
            successLabel: 'Atualizado',
            onAction: () {
              if (o.stage + 1 == 4) {
                // Última etapa: exige o comprovante de entrega (POD).
                showDeliveryDialog(context, store, o);
                return false;
              }
              return store.advanceOrder(o.id);
            },
          ),
        ],
        if (o.telefone.isNotEmpty)
          Button3D(
            label: 'WhatsApp',
            icon: Icons.chat_rounded,
            color: const Color(0xFF16A34A),
            secondary: true,
            onPressed: () => sendWhatsApp(context, o),
          ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            children: [
              StatusChip(status: o.status),
              if (late) const StatusChip(status: OrderStatus.pendente, late: true),
            ],
          ),
          const SizedBox(height: 14),
          info('Cliente', o.cliente),
          info('Origem', o.origem),
          info('Destino', o.destino),
          info('Envio', fmtDate(o.dataEnvio)),
          info('Previsão', fmtDate(o.previsaoEntrega)),
          info('Peso', '${o.pesoKg.toStringAsFixed(0)} kg'),
          if (o.pod != null)
            info(
              'Comprovante',
              '${o.pod!.tipo == 'foto' ? 'Foto (${o.pod!.arquivo})' : 'Assinatura'} - ${o.pod!.recebedor}',
            ),
          if (o.pod != null && o.pod!.assinatura.isNotEmpty)
            Container(
              height: 90,
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
              child: CustomPaint(size: Size.infinite, painter: SignaturePainter(o.pod!.assinatura)),
            ),
          info('Motorista', driver == null ? 'Não vinculado' : '${driver.nome} - ${driver.veiculo} (${driver.placa})'),
          const SizedBox(height: 10),
          const Text('Rastreamento', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          _timeline(ac, o),
          if (sel != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: ac.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: ac.accent.withValues(alpha: 0.35)),
              ),
              child: Text(
                _entryFor(sel) == null
                    ? '${kStages[sel]}: ainda não ocorreu.'
                    : '${kStages[sel]} em ${fmtDateTime(_entryFor(sel)!.date)}',
              ),
            ),
          ],
          const SizedBox(height: 16),
          const Text('Histórico', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          for (final e in o.historico.reversed)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 6, right: 10),
                    child: Icon(Icons.circle, size: 8, color: ac.accent),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(e.label, style: const TextStyle(fontWeight: FontWeight.w700)),
                        Text(
                          e.note.isEmpty ? fmtDateTime(e.date) : '${fmtDateTime(e.date)} - ${e.note}',
                          style: TextStyle(color: ac.muted, fontSize: 12),
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

  /// Linha de 5 etapas com ícones 3D: concluídas coloridas, atual em loop,
  /// futuras apagadas. Toque numa etapa para ver a data.
  Widget _timeline(AtlasColors ac, Order o) {
    final cancelled = o.cancelled;
    return LayoutBuilder(
      builder: (_, box) {
        final iconSize = box.maxWidth < 420 ? 38.0 : 46.0;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < kStages.length; i++) ...[
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => setState(() => _selected = _selected == i ? null : i),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 3,
                              color: i == 0
                                  ? Colors.transparent
                                  : (i <= o.stage && !cancelled ? ac.success : ac.border),
                            ),
                          ),
                          Icon3D(
                            icon: _icons[i],
                            motion: _motions[i],
                            size: iconSize,
                            color: i < o.stage || (i == 4 && o.stage == 4)
                                ? ac.success
                                : ac.accent,
                            loop: i == o.stage && o.isActive,
                            muted: i > o.stage || cancelled && i >= o.stage,
                          ),
                          Expanded(
                            child: Container(
                              height: 3,
                              color: i == kStages.length - 1
                                  ? Colors.transparent
                                  : (i < o.stage && !cancelled ? ac.success : ac.border),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        kStages[i],
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: i == o.stage ? FontWeight.w800 : FontWeight.w500,
                          color: i <= o.stage ? ac.text : ac.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

// --------------------------------------------------------------- vincular carga

Future<void> showAssignDialog(
  BuildContext context,
  AtlasStore store, {
  String? orderId,
  String? driverId,
}) {
  return showDialog<void>(
    context: context,
    builder: (_) => _AssignDialog(store: store, orderId: orderId, driverId: driverId),
  );
}

class _AssignDialog extends StatefulWidget {
  const _AssignDialog({required this.store, this.orderId, this.driverId});

  final AtlasStore store;
  final String? orderId;
  final String? driverId;

  @override
  State<_AssignDialog> createState() => _AssignDialogState();
}

class _AssignDialogState extends State<_AssignDialog> {
  late String? _order = widget.orderId;
  late String? _driver = widget.driverId;
  String? _error;

  bool _assign() {
    if (_order == null || _driver == null) {
      setState(() => _error = 'Selecione o pedido e o motorista.');
      return false;
    }
    final err = widget.store.assignOrder(_order!, _driver!);
    if (err != null) {
      setState(() => _error = err);
      return false;
    }
    Future<void>.delayed(const Duration(milliseconds: 650), () {
      if (mounted) Navigator.pop(context);
    });
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final ac = context.ac;
    final store = widget.store;
    final active = store.orders.where((o) => o.isActive).toList();
    final drivers = store.drivers.where((d) => d.status != DriverStatus.manutencao).toList();

    return DialogShell(
      title: 'Vincular carga',
      maxWidth: 520,
      actions: [
        Button3D(label: 'Cancelar', secondary: true, onPressed: () => Navigator.pop(context)),
        Button3D(
          label: 'Vincular carga',
          icon: Icons.link_rounded,
          successLabel: 'Vinculado!',
          onAction: _assign,
        ),
      ],
      child: Column(
        children: [
          if (active.isEmpty)
            Text('Não há pedidos em andamento.', style: TextStyle(color: ac.muted))
          else
            DropdownButtonFormField<String>(
              initialValue: active.any((o) => o.id == _order) ? _order : null,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Pedido', prefixIcon: Icon(Icons.inventory_2_rounded)),
              items: [
                for (final o in active)
                  DropdownMenuItem(
                    value: o.id,
                    child: Text('${o.id} - ${o.cliente}', overflow: TextOverflow.ellipsis),
                  ),
              ],
              onChanged: (v) => setState(() {
                _order = v;
                _error = null;
              }),
            ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: drivers.any((d) => d.id == _driver) ? _driver : null,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Motorista / veículo', prefixIcon: Icon(Icons.local_shipping_rounded)),
            items: [
              for (final d in drivers)
                DropdownMenuItem(
                  value: d.id,
                  child: Text('${d.nome} - ${d.placa} (${d.status.label})', overflow: TextOverflow.ellipsis),
                ),
            ],
            onChanged: (v) => setState(() {
              _driver = v;
              _error = null;
            }),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.error_rounded, color: ac.danger, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text(_error!, style: TextStyle(color: ac.danger))),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// -------------------------------------------------------------- form motorista

Future<void> showDriverForm(BuildContext context, AtlasStore store, {Driver? driver}) {
  return showDialog<void>(
    context: context,
    builder: (_) => _DriverForm(store: store, driver: driver),
  );
}

class _DriverForm extends StatefulWidget {
  const _DriverForm({required this.store, this.driver});

  final AtlasStore store;
  final Driver? driver;

  @override
  State<_DriverForm> createState() => _DriverFormState();
}

class _DriverFormState extends State<_DriverForm> {
  final _key = GlobalKey<FormState>();
  late final _nome = TextEditingController(text: widget.driver?.nome);
  late final _veiculo = TextEditingController(text: widget.driver?.veiculo);
  late final _placa = TextEditingController(text: widget.driver?.placa);
  late final _tel = TextEditingController(text: widget.driver?.telefone);

  @override
  void dispose() {
    _nome.dispose();
    _veiculo.dispose();
    _placa.dispose();
    _tel.dispose();
    super.dispose();
  }

  bool _save() {
    if (!_key.currentState!.validate()) return false;
    final d = widget.driver;
    if (d == null) {
      widget.store.addDriver(nome: _nome.text, veiculo: _veiculo.text, placa: _placa.text, telefone: _tel.text);
    } else {
      widget.store.updateDriver(d.id, nome: _nome.text, veiculo: _veiculo.text, placa: _placa.text, telefone: _tel.text);
    }
    Future<void>.delayed(const Duration(milliseconds: 650), () {
      if (mounted) Navigator.pop(context);
    });
    return true;
  }

  String? _required(String? v) => (v == null || v.trim().isEmpty) ? 'Campo obrigatório' : null;

  @override
  Widget build(BuildContext context) {
    return DialogShell(
      title: widget.driver == null ? 'Novo motorista' : 'Editar motorista',
      maxWidth: 500,
      actions: [
        Button3D(label: 'Cancelar', secondary: true, onPressed: () => Navigator.pop(context)),
        Button3D(label: 'Salvar', icon: Icons.save_rounded, successLabel: 'Salvo!', onAction: _save),
      ],
      child: Form(
        key: _key,
        child: Column(
          children: [
            TextFormField(controller: _nome, validator: _required, decoration: const InputDecoration(labelText: 'Nome', prefixIcon: Icon(Icons.person_rounded))),
            const SizedBox(height: 12),
            TextFormField(controller: _veiculo, validator: _required, decoration: const InputDecoration(labelText: 'Veículo', prefixIcon: Icon(Icons.local_shipping_rounded))),
            const SizedBox(height: 12),
            TextFormField(controller: _placa, validator: _required, textCapitalization: TextCapitalization.characters, decoration: const InputDecoration(labelText: 'Placa', prefixIcon: Icon(Icons.pin_rounded))),
            const SizedBox(height: 12),
            TextFormField(controller: _tel, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Telefone', prefixIcon: Icon(Icons.phone_rounded))),
          ],
        ),
      ),
    );
  }
}
