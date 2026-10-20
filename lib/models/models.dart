/// Modelos de dados do Atlas. Todos são serializáveis em JSON para que o
/// estado inteiro possa ser persistido localmente e exportado como backup.
library;

/// Etapas da timeline de rastreio, na ordem em que acontecem.
const List<String> kStages = [
  'Pedido Criado',
  'Em Separação',
  'Em Trânsito',
  'Saiu para Entrega',
  'Entregue',
];

/// Status "de negócio" exibidos em filtros e gráficos.
enum OrderStatus { pendente, emTransito, entregue, cancelado }

extension OrderStatusLabel on OrderStatus {
  String get label => switch (this) {
    OrderStatus.pendente => 'Pendente',
    OrderStatus.emTransito => 'Em Trânsito',
    OrderStatus.entregue => 'Entregue',
    OrderStatus.cancelado => 'Cancelado',
  };
}

/// Um registro do histórico de uma encomenda (uma linha da timeline).
class HistoryEntry {
  HistoryEntry({required this.label, required this.date, this.note = ''});

  final String label;
  final DateTime date;
  final String note;

  Map<String, dynamic> toJson() => {
    'label': label,
    'date': date.toIso8601String(),
    'note': note,
  };

  factory HistoryEntry.fromJson(Map<String, dynamic> json) => HistoryEntry(
    label: json['label'] as String,
    date: DateTime.parse(json['date'] as String),
    note: (json['note'] as String?) ?? '',
  );
}

/// Comprovante de entrega: quem recebeu e a "foto"/assinatura (simulada).
class ProofOfDelivery {
  ProofOfDelivery({
    required this.recebedor,
    required this.tipo,
    required this.date,
    this.arquivo = '',
    this.assinatura = const [],
  });

  final String recebedor;

  /// 'foto' ou 'assinatura'.
  final String tipo;
  final DateTime date;

  /// Nome do arquivo anexado (quando for foto).
  final String arquivo;

  /// Traços da assinatura: lista de pontos [x,y] normalizados (0..1); um
  /// ponto `[-1,-1]` marca a quebra entre traços.
  final List<List<double>> assinatura;

  Map<String, dynamic> toJson() => {
    'recebedor': recebedor,
    'tipo': tipo,
    'date': date.toIso8601String(),
    'arquivo': arquivo,
    'assinatura': assinatura,
  };

  factory ProofOfDelivery.fromJson(Map<String, dynamic> json) =>
      ProofOfDelivery(
        recebedor: json['recebedor'] as String,
        tipo: json['tipo'] as String,
        date: DateTime.parse(json['date'] as String),
        arquivo: (json['arquivo'] as String?) ?? '',
        assinatura: ((json['assinatura'] as List?) ?? [])
            .map((e) => (e as List).map((n) => (n as num).toDouble()).toList())
            .toList(),
      );
}

class Order {
  Order({
    required this.id,
    required this.cliente,
    required this.origem,
    required this.destino,
    required this.dataEnvio,
    required this.previsaoEntrega,
    this.motoristaId,
    this.stage = 0,
    this.cancelled = false,
    this.pesoKg = 100,
    this.telefone = '',
    this.pod,
    List<HistoryEntry>? historico,
  }) : historico = historico ?? [];

  final String id;

  /// Peso da carga em kg (usado na calculadora de frete e etiqueta).
  double pesoKg;

  /// Telefone do cliente (WhatsApp), com DDD.
  String telefone;

  /// Comprovante de entrega digital (foto/assinatura simulada).
  ProofOfDelivery? pod;
  String cliente;
  String origem;
  String destino;
  DateTime dataEnvio;
  DateTime previsaoEntrega;
  String? motoristaId;

  /// Índice em [kStages] da etapa atual.
  int stage;
  bool cancelled;
  final List<HistoryEntry> historico;

  OrderStatus get status {
    if (cancelled) return OrderStatus.cancelado;
    if (stage >= 4) return OrderStatus.entregue;
    if (stage >= 2) return OrderStatus.emTransito;
    return OrderStatus.pendente;
  }

  bool get isActive => !cancelled && stage < 4;

  DateTime? get deliveredAt {
    if (status != OrderStatus.entregue) return null;
    for (final entry in historico.reversed) {
      if (entry.label == kStages[4]) return entry.date;
    }
    return null;
  }

  /// Atrasado: ainda ativo e a previsão já passou.
  bool isLate(DateTime now) => isActive && previsaoEntrega.isBefore(now);

  /// Entregue dentro da previsão.
  bool get deliveredOnTime {
    final delivered = deliveredAt;
    return delivered != null && !delivered.isAfter(previsaoEntrega);
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'cliente': cliente,
    'origem': origem,
    'destino': destino,
    'dataEnvio': dataEnvio.toIso8601String(),
    'previsaoEntrega': previsaoEntrega.toIso8601String(),
    'motoristaId': motoristaId,
    'stage': stage,
    'cancelled': cancelled,
    'pesoKg': pesoKg,
    'telefone': telefone,
    'pod': pod?.toJson(),
    'historico': historico.map((e) => e.toJson()).toList(),
  };

  factory Order.fromJson(Map<String, dynamic> json) => Order(
    id: json['id'] as String,
    cliente: json['cliente'] as String,
    origem: json['origem'] as String,
    destino: json['destino'] as String,
    dataEnvio: DateTime.parse(json['dataEnvio'] as String),
    previsaoEntrega: DateTime.parse(json['previsaoEntrega'] as String),
    motoristaId: json['motoristaId'] as String?,
    stage: (json['stage'] as num).toInt(),
    cancelled: json['cancelled'] as bool,
    pesoKg: (json['pesoKg'] as num?)?.toDouble() ?? 100,
    telefone: (json['telefone'] as String?) ?? '',
    pod: json['pod'] == null
        ? null
        : ProofOfDelivery.fromJson(json['pod'] as Map<String, dynamic>),
    historico: (json['historico'] as List)
        .map((e) => HistoryEntry.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}

enum DriverStatus { disponivel, emRota, manutencao }

extension DriverStatusLabel on DriverStatus {
  String get label => switch (this) {
    DriverStatus.disponivel => 'Disponível',
    DriverStatus.emRota => 'Em Rota',
    DriverStatus.manutencao => 'Em Manutenção',
  };
}

enum ExpenseType { combustivel, manutencao }

extension ExpenseTypeLabel on ExpenseType {
  String get label =>
      this == ExpenseType.combustivel ? 'Combustível' : 'Manutenção';
}

/// Despesa de um motorista/veículo (combustível ou manutenção).
class Expense {
  Expense({
    required this.id,
    required this.tipo,
    required this.valor,
    required this.data,
    this.descricao = '',
  });

  final String id;
  final ExpenseType tipo;
  final double valor;
  final DateTime data;
  final String descricao;

  Map<String, dynamic> toJson() => {
    'id': id,
    'tipo': tipo.name,
    'valor': valor,
    'data': data.toIso8601String(),
    'descricao': descricao,
  };

  factory Expense.fromJson(Map<String, dynamic> json) => Expense(
    id: json['id'] as String,
    tipo: ExpenseType.values.byName(json['tipo'] as String),
    valor: (json['valor'] as num).toDouble(),
    data: DateTime.parse(json['data'] as String),
    descricao: (json['descricao'] as String?) ?? '',
  );
}

class Driver {
  Driver({
    required this.id,
    required this.nome,
    required this.veiculo,
    required this.placa,
    required this.telefone,
    this.status = DriverStatus.disponivel,
    this.kmRodados = 0,
    List<Expense>? despesas,
  }) : despesas = despesas ?? [];

  final String id;
  String nome;
  String veiculo;
  String placa;
  String telefone;
  DriverStatus status;

  /// Quilometragem acumulada no período (base do custo por km).
  double kmRodados;
  final List<Expense> despesas;

  double totalDespesas([ExpenseType? tipo]) => despesas
      .where((e) => tipo == null || e.tipo == tipo)
      .fold(0.0, (s, e) => s + e.valor);

  double get custoPorKm => kmRodados <= 0 ? 0 : totalDespesas() / kmRodados;

  Map<String, dynamic> toJson() => {
    'id': id,
    'nome': nome,
    'veiculo': veiculo,
    'placa': placa,
    'telefone': telefone,
    'status': status.name,
    'kmRodados': kmRodados,
    'despesas': despesas.map((e) => e.toJson()).toList(),
  };

  factory Driver.fromJson(Map<String, dynamic> json) => Driver(
    id: json['id'] as String,
    nome: json['nome'] as String,
    veiculo: json['veiculo'] as String,
    placa: json['placa'] as String,
    telefone: json['telefone'] as String,
    status: DriverStatus.values.byName(json['status'] as String),
    kmRodados: (json['kmRodados'] as num?)?.toDouble() ?? 0,
    despesas: ((json['despesas'] as List?) ?? [])
        .map((e) => Expense.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}

enum NotificationType { info, sucesso, alerta }

class AppNotification {
  AppNotification({
    required this.id,
    required this.mensagem,
    required this.tipo,
    required this.data,
    this.lida = false,
  });

  final String id;
  final String mensagem;
  final NotificationType tipo;
  final DateTime data;
  bool lida;

  Map<String, dynamic> toJson() => {
    'id': id,
    'mensagem': mensagem,
    'tipo': tipo.name,
    'data': data.toIso8601String(),
    'lida': lida,
  };

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      AppNotification(
        id: json['id'] as String,
        mensagem: json['mensagem'] as String,
        tipo: NotificationType.values.byName(json['tipo'] as String),
        data: DateTime.parse(json['data'] as String),
        lida: json['lida'] as bool,
      );
}

enum UserRole { admin, operador, motorista }

extension UserRoleLabel on UserRole {
  String get label => switch (this) {
    UserRole.admin => 'Administrador',
    UserRole.operador => 'Operador de Galpão',
    UserRole.motorista => 'Motorista',
  };
}

/// Preferências do sistema e regras padrão de entrega.
class Settings {
  Settings({
    this.darkMode = true,
    this.sound = true,
    this.defaultDeliveryDays = 3,
    this.autoAssignDriver = false,
    this.userName = 'Operador Atlas',
    this.role = UserRole.admin,
    this.roleDriverId = 'D-001',
  });

  bool darkMode;
  bool sound;

  /// Perfil ativo (RBAC simulado) e, para "Motorista", qual motorista é.
  UserRole role;
  String roleDriverId;

  /// Prazo padrão (em dias) sugerido ao criar um pedido.
  int defaultDeliveryDays;

  /// Vincula automaticamente um motorista disponível a novos pedidos.
  bool autoAssignDriver;
  String userName;

  Map<String, dynamic> toJson() => {
    'darkMode': darkMode,
    'sound': sound,
    'defaultDeliveryDays': defaultDeliveryDays,
    'autoAssignDriver': autoAssignDriver,
    'userName': userName,
    'role': role.name,
    'roleDriverId': roleDriverId,
  };

  factory Settings.fromJson(Map<String, dynamic> json) => Settings(
    darkMode: (json['darkMode'] as bool?) ?? true,
    sound: (json['sound'] as bool?) ?? true,
    defaultDeliveryDays: (json['defaultDeliveryDays'] as num?)?.toInt() ?? 3,
    autoAssignDriver: (json['autoAssignDriver'] as bool?) ?? false,
    userName: (json['userName'] as String?) ?? 'Operador Atlas',
    role: UserRole.values.byName((json['role'] as String?) ?? 'admin'),
    roleDriverId: (json['roleDriverId'] as String?) ?? 'D-001',
  );
}
