/// Camada de serviço do Atlas: guarda todo o estado em memória, aplica as
/// regras operacionais e persiste tudo em `SharedPreferences` (localStorage
/// na web), de modo que qualquer ação sobrevive a recarregar a página.
library;

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/format.dart';
import '../models/models.dart';
import 'seed.dart';

/// Uma linha do feed de atividades (evento de histórico de um pedido).
class ActivityItem {
  ActivityItem(this.order, this.entry);

  final Order order;
  final HistoryEntry entry;
}

/// Contagem diária usada pelo gráfico de fluxo de entregas.
class DayFlow {
  DayFlow(this.day, this.created, this.delivered);

  final DateTime day;
  final int created;
  final int delivered;
}

class AtlasStore extends ChangeNotifier {
  AtlasStore({
    SharedPreferences? prefs,
    DateTime Function()? clock,
    this.loadDelay = const Duration(milliseconds: 700),
  }) : _prefs = prefs,
       _clock = clock ?? DateTime.now;

  static const _storageKey = 'atlas.state.v1';

  final SharedPreferences? _prefs;
  final DateTime Function() _clock;

  /// Tempo mínimo de "carregando" (permite exibir os skeletons).
  final Duration loadDelay;

  bool loading = true;
  String? restoreWarning;
  List<Order> orders = [];
  List<Driver> drivers = [];
  List<AppNotification> notifications = [];
  Settings settings = Settings();

  DateTime get now => _clock();

  // ---------------------------------------------------------------- carga

  Future<void> load() async {
    final raw = _prefs?.getString(_storageKey);
    var restored = false;
    if (raw != null) {
      try {
        _restore(jsonDecode(raw) as Map<String, dynamic>);
        restored = true;
      } catch (error, stackTrace) {
        restoreWarning =
            'Não foi possível ler os dados locais; os dados de demonstração foram restaurados.';
        debugPrint('Estado local do Atlas inválido; restaurando dados de exemplo: $error');
        debugPrintStack(stackTrace: stackTrace);
        restored = false; // dado corrompido: recomeça do seed
      }
    }
    if (!restored) {
      _applySeed();
      if (restoreWarning != null) {
        notifications.insert(
          0,
          AppNotification(
            id: 'N-restore-warning',
            mensagem: restoreWarning!,
            tipo: NotificationType.alerta,
            data: now,
          ),
        );
      }
    }
    if (loadDelay > Duration.zero) await Future<void>.delayed(loadDelay);
    loading = false;
    checkAlerts();
    notifyListeners();
  }

  void _applySeed() {
    final seed = buildSeed(now);
    orders = seed.orders;
    drivers = seed.drivers;
    notifications = seed.notifications;
  }

  void _restore(Map<String, dynamic> json) {
    orders = (json['orders'] as List)
        .map((e) => Order.fromJson(e as Map<String, dynamic>))
        .toList();
    drivers = (json['drivers'] as List)
        .map((e) => Driver.fromJson(e as Map<String, dynamic>))
        .toList();
    notifications = (json['notifications'] as List)
        .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
        .toList();
    settings = Settings.fromJson(json['settings'] as Map<String, dynamic>);
  }

  Map<String, dynamic> toJson() => {
    'orders': orders.map((e) => e.toJson()).toList(),
    'drivers': drivers.map((e) => e.toJson()).toList(),
    'notifications': notifications.map((e) => e.toJson()).toList(),
    'settings': settings.toJson(),
  };

  /// Persiste e avisa a interface. Toda mutação passa por aqui.
  void _commit() {
    _prefs?.setString(_storageKey, jsonEncode(toJson()));
    notifyListeners();
  }

  // ------------------------------------------------------------- consultas

  Order? orderById(String id) {
    for (final o in orders) {
      if (o.id == id) return o;
    }
    return null;
  }

  Driver? driverById(String? id) {
    if (id == null) return null;
    for (final d in drivers) {
      if (d.id == id) return d;
    }
    return null;
  }

  List<Order> activeOrdersOf(String driverId) =>
      orders.where((o) => o.isActive && o.motoristaId == driverId).toList();

  int get unreadCount => notifications.where((n) => !n.lida).length;

  // ------------------------------------------------------------------ KPIs

  int get totalOrders => orders.length;

  int get inTransitCount =>
      orders.where((o) => o.status == OrderStatus.emTransito).length;

  int get deliveredOnTimeCount => orders.where((o) => o.deliveredOnTime).length;

  int get delayedCount => orders.where((o) => o.isLate(now)).length;

  int get availableDrivers =>
      drivers.where((d) => d.status == DriverStatus.disponivel).length;

  Map<OrderStatus, int> statusDistribution([Iterable<Order>? source]) {
    final map = {for (final s in OrderStatus.values) s: 0};
    for (final o in source ?? orders) {
      map[o.status] = map[o.status]! + 1;
    }
    return map;
  }

  /// Pedidos criados x entregues por dia, do dia [from] até [to] (inclusive).
  List<DayFlow> flow(DateTime from, DateTime to) {
    final result = <DayFlow>[];
    var day = dayOnly(from);
    final last = dayOnly(to);
    while (!day.isAfter(last)) {
      final created = orders.where((o) => sameDay(o.dataEnvio, day)).length;
      final delivered = orders.where((o) {
        final d = o.deliveredAt;
        return d != null && sameDay(d, day);
      }).length;
      result.add(DayFlow(day, created, delivered));
      day = day.add(const Duration(days: 1));
    }
    return result;
  }

  /// Últimos [limit] eventos de histórico de todos os pedidos.
  List<ActivityItem> recentActivity({int limit = 8}) {
    final items = <ActivityItem>[
      for (final o in orders)
        for (final e in o.historico) ActivityItem(o, e),
    ]..sort((a, b) => b.entry.date.compareTo(a.entry.date));
    return items.take(limit).toList();
  }

  List<Order> ordersInRange(DateTime from, DateTime to) {
    final start = dayOnly(from);
    final end = dayOnly(to).add(const Duration(days: 1));
    return orders
        .where((o) => !o.dataEnvio.isBefore(start) && o.dataEnvio.isBefore(end))
        .toList()
      ..sort((a, b) => b.dataEnvio.compareTo(a.dataEnvio));
  }

  // ---------------------------------------------------------------- pedidos

  String _nextOrderId() {
    var max = 2399;
    for (final o in orders) {
      final n = int.tryParse(o.id.replaceFirst('ATL-', ''));
      if (n != null && n > max) max = n;
    }
    return 'ATL-${max + 1}';
  }

  Order createOrder({
    required String cliente,
    required String origem,
    required String destino,
    required DateTime previsao,
    String? driverId,
    double pesoKg = 100,
    String telefone = '',
  }) {
    final created = now;
    final order = Order(
      id: _nextOrderId(),
      cliente: cliente.trim(),
      origem: origem.trim(),
      destino: destino.trim(),
      dataEnvio: created,
      previsaoEntrega: previsao,
      motoristaId: driverId,
      pesoKg: pesoKg,
      telefone: telefone.trim(),
    )..historico.add(HistoryEntry(label: kStages[0], date: created));

    if (order.motoristaId == null && settings.autoAssignDriver) {
      for (final d in drivers) {
        if (d.status == DriverStatus.disponivel) {
          order.motoristaId = d.id;
          order.historico.add(
            HistoryEntry(
              label: 'Motorista vinculado',
              date: created,
              note: '${d.nome} (automático)',
            ),
          );
          break;
        }
      }
    }
    orders.insert(0, order);
    _syncDriver(order.motoristaId);
    _notify('Novo pedido ${order.id} criado para ${order.cliente}.',
        NotificationType.info);
    _commit();
    return order;
  }

  void updateOrder(
    String id, {
    required String cliente,
    required String origem,
    required String destino,
    required DateTime previsao,
    double? pesoKg,
    String? telefone,
  }) {
    final order = orderById(id);
    if (order == null) return;
    order
      ..cliente = cliente.trim()
      ..origem = origem.trim()
      ..destino = destino.trim()
      ..previsaoEntrega = previsao;
    if (pesoKg != null) order.pesoKg = pesoKg;
    if (telefone != null) order.telefone = telefone.trim();
    order.historico.add(
      HistoryEntry(label: 'Pedido editado', date: now),
    );
    _commit();
  }

  void deleteOrder(String id) {
    final order = orderById(id);
    if (order == null) return;
    orders.remove(order);
    _syncDriver(order.motoristaId);
    _notify('Pedido $id foi excluído.', NotificationType.alerta);
    _commit();
  }

  /// Avança o pedido para a próxima etapa da timeline.
  bool advanceOrder(String id) {
    final order = orderById(id);
    if (order == null || !order.isActive) return false;
    order.stage += 1;
    final label = kStages[order.stage];
    order.historico.add(HistoryEntry(label: label, date: now));
    if (order.stage == 4) {
      final onTime = order.deliveredOnTime;
      _notify(
        'Pedido $id foi entregue${onTime ? ' no prazo' : ' com atraso'}.',
        onTime ? NotificationType.sucesso : NotificationType.alerta,
      );
    } else if (order.stage == 3) {
      _notify('Pedido $id saiu para entrega.', NotificationType.info);
    }
    _syncDriver(order.motoristaId);
    _commit();
    return true;
  }

  /// Conclui a entrega anexando o comprovante (POD).
  bool deliverOrder(String id, ProofOfDelivery pod) {
    final order = orderById(id);
    if (order == null || !order.isActive) return false;
    order.pod = pod;
    order.stage = 3;
    final ok = advanceOrder(id);
    final entry = order.historico.last;
    order.historico[order.historico.length - 1] = HistoryEntry(
      label: entry.label,
      date: entry.date,
      note: 'Recebido por ${pod.recebedor} (${pod.tipo})',
    );
    _commit();
    return ok;
  }

  // ------------------------------------------------------------- financeiro

  void addExpense(
    String driverId, {
    required ExpenseType tipo,
    required double valor,
    String descricao = '',
    double km = 0,
  }) {
    final d = driverById(driverId);
    if (d == null) return;
    d.despesas.insert(
      0,
      Expense(
        id: '$driverId-E${now.microsecondsSinceEpoch}',
        tipo: tipo,
        valor: valor,
        data: now,
        descricao: descricao.trim(),
      ),
    );
    d.kmRodados += km;
    _commit();
  }

  void removeExpense(String driverId, String expenseId) {
    driverById(driverId)?.despesas.removeWhere((e) => e.id == expenseId);
    _commit();
  }

  double get fleetExpenses => drivers.fold(0.0, (s, d) => s + d.totalDespesas());

  double get fleetKm => drivers.fold(0.0, (s, d) => s + d.kmRodados);

  // ---------------------------------------------------------------- alertas

  /// Divergência: pedido em trânsito sem motorista ou com motorista em
  /// manutenção.
  List<Order> get divergentOrders => orders.where((o) {
    if (!o.isActive || o.stage < 2) return false;
    final d = driverById(o.motoristaId);
    return d == null || d.status == DriverStatus.manutencao;
  }).toList();

  List<Order> get lateOrders => orders.where((o) => o.isLate(now)).toList();

  int get alertCount => {
    ...lateOrders.map((o) => o.id),
    ...divergentOrders.map((o) => o.id),
  }.length;

  /// Gera notificações para atrasos/divergências ainda não avisados.
  void checkAlerts() {
    var changed = false;
    bool has(String msg) => notifications.any((n) => n.mensagem == msg);
    for (final o in lateOrders) {
      final msg = 'Pedido ${o.id} está com a entrega atrasada.';
      if (!has(msg)) {
        _notify(msg, NotificationType.alerta);
        changed = true;
      }
    }
    for (final o in divergentOrders) {
      final msg = 'Divergência no pedido ${o.id}: sem motorista disponível.';
      if (!has(msg)) {
        _notify(msg, NotificationType.alerta);
        changed = true;
      }
    }
    if (changed) _commit();
  }

  // ----------------------------------------------------------------- perfil

  void setRole(UserRole role, {String? driverId}) {
    settings.role = role;
    if (driverId != null) settings.roleDriverId = driverId;
    _commit();
  }

  bool cancelOrder(String id) {
    final order = orderById(id);
    if (order == null || !order.isActive) return false;
    order.cancelled = true;
    order.historico.add(
      HistoryEntry(
        label: 'Cancelado',
        date: now,
        note: 'Cancelado pelo operador.',
      ),
    );
    _syncDriver(order.motoristaId);
    _notify('Pedido $id foi cancelado.', NotificationType.alerta);
    _commit();
    return true;
  }

  /// Vincula um pedido a um motorista. Retorna uma mensagem de erro ou null.
  String? assignOrder(String orderId, String driverId) {
    final order = orderById(orderId);
    final driver = driverById(driverId);
    if (order == null || driver == null) return 'Pedido ou motorista inválido.';
    if (!order.isActive) return 'Só é possível vincular pedidos em andamento.';
    if (driver.status == DriverStatus.manutencao) {
      return '${driver.nome} está em manutenção.';
    }
    final previous = order.motoristaId;
    order.motoristaId = driverId;
    order.historico.add(
      HistoryEntry(
        label: 'Motorista vinculado',
        date: now,
        note: '${driver.nome} - ${driver.veiculo} (${driver.placa})',
      ),
    );
    _syncDriver(previous);
    _syncDriver(driverId);
    _notify('Pedido $orderId vinculado a ${driver.nome}.',
        NotificationType.sucesso);
    _commit();
    return null;
  }

  // -------------------------------------------------------------- motoristas

  Driver addDriver({
    required String nome,
    required String veiculo,
    required String placa,
    required String telefone,
  }) {
    var max = 0;
    for (final d in drivers) {
      final n = int.tryParse(d.id.replaceFirst('D-', ''));
      if (n != null && n > max) max = n;
    }
    final driver = Driver(
      id: 'D-${(max + 1).toString().padLeft(3, '0')}',
      nome: nome.trim(),
      veiculo: veiculo.trim(),
      placa: placa.trim().toUpperCase(),
      telefone: telefone.trim(),
    );
    drivers.add(driver);
    _notify('Motorista ${driver.nome} cadastrado.', NotificationType.info);
    _commit();
    return driver;
  }

  void updateDriver(
    String id, {
    required String nome,
    required String veiculo,
    required String placa,
    required String telefone,
  }) {
    final driver = driverById(id);
    if (driver == null) return;
    driver
      ..nome = nome.trim()
      ..veiculo = veiculo.trim()
      ..placa = placa.trim().toUpperCase()
      ..telefone = telefone.trim();
    _commit();
  }

  /// Remove o motorista e desvincula seus pedidos. Retorna erro ou null.
  String? deleteDriver(String id) {
    final driver = driverById(id);
    if (driver == null) return null;
    if (activeOrdersOf(id).isNotEmpty) {
      return 'Motorista possui pedidos em andamento. Reatribua-os antes.';
    }
    for (final o in orders.where((o) => o.motoristaId == id)) {
      o.motoristaId = null;
    }
    drivers.remove(driver);
    _commit();
    return null;
  }

  /// Alterna manualmente entre Disponível e Em Manutenção.
  String? setMaintenance(String id, bool maintenance) {
    final driver = driverById(id);
    if (driver == null) return null;
    if (maintenance && activeOrdersOf(id).isNotEmpty) {
      return 'Há pedidos em andamento com ${driver.nome}.';
    }
    driver.status =
        maintenance ? DriverStatus.manutencao : DriverStatus.disponivel;
    _syncDriver(id);
    _commit();
    return null;
  }

  /// Em Rota enquanto houver pedidos ativos; senão Disponível.
  void _syncDriver(String? id) {
    final driver = driverById(id);
    if (driver == null || driver.status == DriverStatus.manutencao) return;
    driver.status = activeOrdersOf(driver.id).isEmpty
        ? DriverStatus.disponivel
        : DriverStatus.emRota;
  }

  // ------------------------------------------------------------ notificações

  void _notify(String message, NotificationType type) {
    notifications.insert(
      0,
      AppNotification(
        id: 'N-${now.microsecondsSinceEpoch}-${notifications.length}',
        mensagem: message,
        tipo: type,
        data: now,
      ),
    );
    if (notifications.length > 50) notifications.removeLast();
    if (settings.sound) {
      SystemSound.play(SystemSoundType.alert);
    }
  }

  void markRead(String id) {
    for (final n in notifications) {
      if (n.id == id) n.lida = true;
    }
    _commit();
  }

  void markAllRead() {
    for (final n in notifications) {
      n.lida = true;
    }
    _commit();
  }

  void clearNotifications() {
    notifications.clear();
    _commit();
  }

  // ----------------------------------------------------------- configurações

  void updateSettings(void Function(Settings s) change) {
    change(settings);
    _commit();
  }

  /// Apaga tudo e volta aos dados de exemplo (mantém as preferências).
  void resetData() {
    _applySeed();
    _commit();
  }

  String exportBackup() =>
      const JsonEncoder.withIndent('  ').convert(toJson());
}
