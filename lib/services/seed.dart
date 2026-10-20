/// Dados de exemplo gerados em relação à data atual, para o painel sempre
/// parecer "vivo" (entregas recentes, pedidos em rota e alguns atrasos).
library;

import '../models/models.dart';

class SeedData {
  SeedData({
    required this.orders,
    required this.drivers,
    required this.notifications,
  });

  final List<Order> orders;
  final List<Driver> drivers;
  final List<AppNotification> notifications;
}

SeedData buildSeed(DateTime now) {
  final drivers = <Driver>[
    Driver(
      id: 'D-001',
      nome: 'Carlos Menezes',
      veiculo: 'Volvo FH 540',
      placa: 'QRT-4F21',
      telefone: '(11) 98812-3045',
      status: DriverStatus.emRota,
    ),
    Driver(
      id: 'D-002',
      nome: 'Fernanda Souza',
      veiculo: 'Mercedes Actros',
      placa: 'RIO-7B93',
      telefone: '(21) 99765-1180',
      status: DriverStatus.emRota,
    ),
    Driver(
      id: 'D-003',
      nome: 'Rafael Tavares',
      veiculo: 'Scania R450',
      placa: 'BRA-2E19',
      telefone: '(31) 98540-7712',
    ),
    Driver(
      id: 'D-004',
      nome: 'Juliana Prado',
      veiculo: 'Iveco Tector',
      placa: 'SPX-9C05',
      telefone: '(41) 99120-6634',
    ),
    Driver(
      id: 'D-005',
      nome: 'Marcos Oliveira',
      veiculo: 'VW Constellation',
      placa: 'MGA-1D77',
      telefone: '(19) 98233-4519',
      status: DriverStatus.manutencao,
    ),
    Driver(
      id: 'D-006',
      nome: 'Patrícia Lima',
      veiculo: 'DAF XF',
      placa: 'PRT-5A48',
      telefone: '(51) 99871-2206',
    ),
  ];

  // Quilometragem e despesas de exemplo para a gestão financeira.
  for (var i = 0; i < drivers.length; i++) {
    final d = drivers[i];
    d.kmRodados = 2400.0 + i * 780;
    d.despesas.addAll([
      Expense(
        id: '${d.id}-E1',
        tipo: ExpenseType.combustivel,
        valor: 2100.0 + i * 410,
        data: now.subtract(Duration(days: 3 + i)),
        descricao: 'Diesel S10',
      ),
      Expense(
        id: '${d.id}-E2',
        tipo: ExpenseType.combustivel,
        valor: 1500.0 + i * 220,
        data: now.subtract(Duration(days: 9 + i)),
        descricao: 'Diesel S10',
      ),
      Expense(
        id: '${d.id}-E3',
        tipo: ExpenseType.manutencao,
        valor: 650.0 + i * 340,
        data: now.subtract(Duration(days: 14 + i)),
        descricao: 'Revisão e pneus',
      ),
    ]);
  }

  const clientes = [
    'Mineradora Horizonte',
    'Construtora Alvorada',
    'Metalúrgica Norte',
    'Porto Seco Logística',
    'AgroSul Ltda',
    'Indústrias Vega',
    'Rede Fácil Varejo',
    'Siderúrgica Atlântico',
  ];
  const rotas = [
    ['São Paulo, SP', 'Belo Horizonte, MG'],
    ['Rio de Janeiro, RJ', 'Vitória, ES'],
    ['Curitiba, PR', 'Porto Alegre, RS'],
    ['Campinas, SP', 'Goiânia, GO'],
    ['Santos, SP', 'Brasília, DF'],
    ['Salvador, BA', 'Recife, PE'],
  ];

  final orders = <Order>[];

  // Cria um pedido já avançado até [stage], com histórico coerente.
  Order make(int n, int daysAgo, int stage, int prazo, String? driverId) {
    final route = rotas[n % rotas.length];
    final sent = now.subtract(Duration(days: daysAgo, hours: n % 5));
    final order = Order(
      id: 'ATL-${2400 + n}',
      cliente: clientes[n % clientes.length],
      origem: route[0],
      destino: route[1],
      dataEnvio: sent,
      previsaoEntrega: sent.add(Duration(days: prazo)),
      motoristaId: driverId,
      stage: stage,
      pesoKg: 80.0 + (n * 137) % 1400,
      telefone: '(11) 9${(8100 + n * 173) % 10000}-${(1000 + n * 311) % 10000}',
    );
    for (var i = 0; i <= stage; i++) {
      // Distribui as etapas entre a data de envio e agora.
      var date = sent.add(Duration(hours: (i * prazo * 24 / 5).round()));
      if (date.isAfter(now)) {
        date = now.subtract(Duration(minutes: 20 * (4 - i)));
      }
      order.historico.add(HistoryEntry(label: kStages[i], date: date));
    }
    return order;
  }

  // Entregues nos últimos dias (a maioria no prazo, alguns atrasados).
  for (var i = 0; i < 14; i++) {
    orders.add(make(i, 1 + (i % 7), 4, i % 6 == 0 ? 1 : 3, null));
  }
  // Em trânsito / saindo para entrega.
  orders.add(make(14, 2, 2, 4, 'D-001'));
  orders.add(make(15, 1, 3, 3, 'D-002'));
  orders.add(make(16, 3, 2, 5, 'D-001'));
  orders.add(make(17, 1, 2, 3, null));
  // Pendentes.
  orders.add(make(18, 0, 0, 3, null));
  orders.add(make(19, 0, 1, 4, null));
  // Atrasados (ainda ativos e com previsão vencida).
  orders.add(make(20, 6, 2, 3, 'D-002'));
  orders.add(make(21, 5, 1, 2, null));
  // Cancelado.
  final cancelled = make(22, 4, 1, 3, null)
    ..cancelled = true
    ..historico.add(
      HistoryEntry(
        label: 'Cancelado',
        date: now.subtract(const Duration(days: 3)),
        note: 'Cancelado a pedido do cliente.',
      ),
    );
  orders.add(cancelled);

  final notifications = <AppNotification>[
    AppNotification(
      id: 'N-1',
      mensagem: 'Pedido ATL-2420 está com a entrega atrasada.',
      tipo: NotificationType.alerta,
      data: now.subtract(const Duration(minutes: 12)),
    ),
    AppNotification(
      id: 'N-2',
      mensagem: 'Pedido ATL-2415 saiu para entrega.',
      tipo: NotificationType.info,
      data: now.subtract(const Duration(hours: 1)),
    ),
    AppNotification(
      id: 'N-3',
      mensagem: 'Pedido ATL-2413 foi entregue no prazo.',
      tipo: NotificationType.sucesso,
      data: now.subtract(const Duration(hours: 3)),
    ),
  ];

  return SeedData(
    orders: orders,
    drivers: drivers,
    notifications: notifications,
  );
}
