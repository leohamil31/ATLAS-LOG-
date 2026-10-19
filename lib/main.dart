import 'package:flutter/material.dart';

void main() {
  runApp(const AtlasLogApp());
}

const _navy = Color(0xFF09243D);
const _blue = Color(0xFF0875C9);
const _canvas = Color(0xFFF3F6FA);
const _ink = Color(0xFF172B3D);

class AtlasLogApp extends StatefulWidget {
  const AtlasLogApp({super.key});

  @override
  State<AtlasLogApp> createState() => _AtlasLogAppState();
}

class _AtlasLogAppState extends State<AtlasLogApp> {
  ThemeMode _themeMode = ThemeMode.light;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Atlas',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _blue,
          primary: _blue,
          surface: Colors.white,
        ),
        scaffoldBackgroundColor: _canvas,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: _ink,
          surfaceTintColor: Colors.transparent,
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: Color(0xFFE7EDF3)),
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          indicatorColor: const Color(0xFFDDEEFB),
          height: 68,
          labelTextStyle: WidgetStateProperty.resolveWith(
            (states) => TextStyle(
              fontSize: 12,
              fontWeight: states.contains(WidgetState.selected)
                  ? FontWeight.w800
                  : FontWeight.w500,
            ),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size(48, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF7F9FB),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE2E8EF)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE2E8EF)),
          ),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF62B5FF),
          brightness: Brightness.dark,
        ),
        cardTheme: CardThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
      home: AppShell(
        onThemeChanged: (dark) {
          setState(() => _themeMode = dark ? ThemeMode.dark : ThemeMode.light);
        },
      ),
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({required this.onThemeChanged, super.key});

  final ValueChanged<bool> onThemeChanged;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  bool _signedIn = false;
  String _role = 'Administrador';
  String _name = 'Leona';
  String _page = 'Dashboard';
  bool _tracking = false;
  bool _checklistComplete = false;
  bool _darkMode = false;
  final List<Vehicle> _vehicles = [
    Vehicle('Guindaste Atlas 1070', 'ABC-1D23', 'Ativo', '2022'),
    Vehicle('Guindaste Atlas 3050', 'DEF-4G56', 'Em manutenção', '2021'),
    Vehicle('Munck Mercedes 2423', 'GHI-7J89', 'Ativo', '2023'),
  ];

  List<NavItem> get _items {
    if (_role == 'Administrador') {
      return const [
        NavItem('Dashboard', Icons.grid_view_rounded),
        NavItem('Operações', Icons.construction_rounded),
        NavItem('Documentos', Icons.folder_open_rounded),
        NavItem('Checklist', Icons.fact_check_rounded),
        NavItem('Frota', Icons.local_shipping_rounded),
        NavItem('Manutenções', Icons.build_circle_outlined),
        NavItem('Financeiro', Icons.account_balance_wallet_outlined),
        NavItem('Relatórios', Icons.bar_chart_rounded),
        NavItem('Usuários', Icons.people_alt_outlined),
        NavItem('Notificações', Icons.notifications_none_rounded),
        NavItem('Configurações', Icons.settings_outlined),
      ];
    }
    return const [
      NavItem('Dashboard', Icons.grid_view_rounded),
      NavItem('Operações', Icons.construction_rounded),
      NavItem('Documentos', Icons.folder_open_rounded),
      NavItem('Checklist', Icons.fact_check_rounded),
      NavItem('Minha Carteira', Icons.badge_outlined),
      NavItem('Notificações', Icons.notifications_none_rounded),
      NavItem('Configurações', Icons.settings_outlined),
    ];
  }

  void _navigate(String page) {
    if (!_items.any((item) => item.label == page)) return;
    setState(() => _page = page);
  }

  void _login(String role, String name) {
    setState(() {
      _role = role;
      _name = name.trim().isEmpty ? 'Usuário' : name.trim();
      _page = 'Dashboard';
      _signedIn = true;
    });
  }

  void _showQrDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => const DemoFeatureDialog(
        icon: Icons.qr_code_scanner_rounded,
        title: 'Leitor de QR Code',
        description:
            'A interface já está preparada. O acesso à câmera e a leitura real '
            'do QR Code precisam ser conectados para cada plataforma.',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_signedIn) {
      return LoginPage(onLogin: _login);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 950;
        final content = AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          switchInCurve: Curves.easeOut,
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, .02),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          ),
          child: KeyedSubtree(key: ValueKey(_page), child: _buildPage()),
        );
        if (wide) {
          return Scaffold(
            body: Row(
              children: [
                _Sidebar(
                  items: _items,
                  selected: _page,
                  role: _role,
                  name: _name,
                  onSelect: _navigate,
                  onLogout: () => setState(() => _signedIn = false),
                ),
                Expanded(
                  child: Column(
                    children: [
                      _TopBar(
                        title: _page,
                        onNotifications: () => _navigate('Notificações'),
                        onQr: _showQrDialog,
                      ),
                      Expanded(child: content),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(_page == 'Dashboard' ? 'ATLAS' : _page),
            leading: Builder(
              builder: (context) => IconButton(
                tooltip: 'Abrir menu',
                icon: const Icon(Icons.menu_rounded),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ),
            actions: [
              IconButton(
                tooltip: 'Notificações',
                onPressed: () => _navigate('Notificações'),
                icon: const Icon(Icons.notifications_none_rounded),
              ),
              IconButton(
                tooltip: 'Leitor QR',
                onPressed: _showQrDialog,
                icon: const Icon(Icons.qr_code_scanner_rounded),
              ),
              const SizedBox(width: 4),
            ],
          ),
          drawer: Drawer(
            child: _Sidebar(
              items: _items,
              selected: _page,
              role: _role,
              name: _name,
              compact: true,
              onSelect: (page) {
                _navigate(page);
                Navigator.pop(context);
              },
              onLogout: () => setState(() => _signedIn = false),
            ),
          ),
          body: content,
          bottomNavigationBar: NavigationBar(
            selectedIndex: _bottomIndex,
            onDestinationSelected: (index) =>
                _navigate(_bottomItems[index].label),
            destinations: _bottomItems
                .map(
                  (item) => NavigationDestination(
                    icon: Icon(item.icon),
                    selectedIcon: Icon(item.icon, color: _blue),
                    label: item.label,
                  ),
                )
                .toList(),
          ),
        );
      },
    );
  }

  List<NavItem> get _bottomItems => const [
    NavItem('Dashboard', Icons.grid_view_rounded),
    NavItem('Operações', Icons.construction_rounded),
    NavItem('Checklist', Icons.fact_check_rounded),
    NavItem('Frota', Icons.local_shipping_rounded),
  ];

  int get _bottomIndex {
    final index = _bottomItems.indexWhere((item) => item.label == _page);
    return index < 0 ? 0 : index;
  }

  Widget _buildPage() {
    switch (_page) {
      case 'Dashboard':
        return DashboardPage(name: _name, role: _role, onNavigate: _navigate);
      case 'Operações':
        return OperationsPage(
          tracking: _tracking,
          onTrackingChanged: (value) => setState(() => _tracking = value),
        );
      case 'Checklist':
        return ChecklistPage(
          completed: _checklistComplete,
          onCompleted: () => setState(() => _checklistComplete = true),
        );
      case 'Frota':
        return FleetPage(
          vehicles: _vehicles,
          onAdd: (vehicle) => setState(() => _vehicles.insert(0, vehicle)),
        );
      case 'Documentos':
        return DocumentsPage(role: _role);
      case 'Manutenções':
        return const MaintenancePage();
      case 'Financeiro':
        return const FinancePage();
      case 'Relatórios':
        return const ReportsPage();
      case 'Usuários':
        return const UsersPage();
      case 'Minha Carteira':
        return const WalletPage();
      case 'Notificações':
        return const NotificationsPage();
      case 'Configurações':
        return SettingsPage(
          name: _name,
          role: _role,
          darkMode: _darkMode,
          onDarkModeChanged: (value) {
            setState(() => _darkMode = value);
            widget.onThemeChanged(value);
          },
          onLogout: () => setState(() => _signedIn = false),
        );
      default:
        return const Center(child: Text('Tela não encontrada.'));
    }
  }
}

class NavItem {
  const NavItem(this.label, this.icon);

  final String label;
  final IconData icon;
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.items,
    required this.selected,
    required this.role,
    required this.name,
    required this.onSelect,
    required this.onLogout,
    this.compact = false,
  });

  final List<NavItem> items;
  final String selected;
  final String role;
  final String name;
  final ValueChanged<String> onSelect;
  final VoidCallback onLogout;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: compact ? null : 250,
      color: _navy,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 22, 22, 6),
              child: Row(
                children: [
                  const _AtlasMark(size: 42),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ATLAS',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                          ),
                        ),
                        Text(
                          'GESTÃO OPERACIONAL',
                          style: TextStyle(
                            color: Color(0xFF9BB3C8),
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 15, 18, 12),
              child: Text(
                'MENU PRINCIPAL',
                style: TextStyle(
                  color: Color(0xFF8BA6BC),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.4,
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: items.map((item) {
                  final isSelected = item.label == selected;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: ListTile(
                      selected: isSelected,
                      selectedTileColor: const Color(0xFF17486E),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      leading: Icon(
                        item.icon,
                        color: isSelected
                            ? Colors.white
                            : const Color(0xFF9BB3C8),
                        size: 20,
                      ),
                      title: Text(
                        item.label,
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFFCDDAE5),
                          fontSize: 13,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                      onTap: () => onSelect(item.label),
                    ),
                  );
                }).toList(),
              ),
            ),
            const Divider(color: Color(0xFF294258), height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: const Color(0xFF17486E),
                    child: Text(
                      name.isEmpty ? 'U' : name[0].toUpperCase(),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          role,
                          style: const TextStyle(
                            color: Color(0xFF9BB3C8),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Sair',
                    onPressed: onLogout,
                    icon: const Icon(
                      Icons.logout_rounded,
                      color: Color(0xFF9BB3C8),
                      size: 19,
                    ),
                  ),
                ],
              ),
            ),
            if (compact) const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.title,
    required this.onNotifications,
    required this.onQr,
  });

  final String title;
  final VoidCallback onNotifications;
  final VoidCallback onQr;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 76,
      padding: const EdgeInsets.symmetric(horizontal: 30),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE7EDF3))),
      ),
      child: Row(
        children: [
          Text(
            title == 'Dashboard' ? 'Central de comando' : title,
            style: const TextStyle(
              color: _ink,
              fontSize: 19,
              fontWeight: FontWeight.w800,
            ),
          ),
          const Spacer(),
          IconButton(
            tooltip: 'Notificações',
            onPressed: onNotifications,
            icon: const Icon(Icons.notifications_none_rounded),
          ),
          IconButton(
            tooltip: 'Leitor QR',
            onPressed: onQr,
            icon: const Icon(Icons.qr_code_scanner_rounded),
          ),
          const SizedBox(width: 8),
          const _DemoBadge(),
        ],
      ),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({required this.onLogin, super.key});

  final void Function(String role, String name) onLogin;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _nameController = TextEditingController(text: 'Leona');
  String _role = 'Administrador';

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 900;
          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1050),
                child: wide
                    ? Row(
                        children: [
                          Expanded(child: _loginBranding()),
                          const SizedBox(width: 32),
                          SizedBox(width: 420, child: _loginForm()),
                        ],
                      )
                    : Column(
                        children: [
                          _loginBranding(compact: true),
                          const SizedBox(height: 24),
                          _loginForm(),
                        ],
                      ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _loginBranding({bool compact = false}) {
    return Container(
      height: compact ? 270 : 480,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_navy, Color(0xFF124A75)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const _AtlasMark(size: 48),
              const SizedBox(width: 12),
              const Text(
                'ATLAS',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'SISTEMA INTEGRADO ATLAS',
                style: TextStyle(
                  color: Color(0xFF68BCFF),
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                compact
                    ? 'Gestão da sua frota, em um só lugar.'
                    : 'Operação segura.\nGestão inteligente.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: compact ? 25 : 36,
                  height: 1.12,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Acesse o ambiente de demonstração multiplataforma.',
                style: TextStyle(color: Color(0xFFC3D2DF), fontSize: 14),
              ),
            ],
          ),
          if (!compact)
            const Row(
              children: [
                _MiniFeature(
                  icon: Icons.fact_check_outlined,
                  label: 'Checklists',
                ),
                SizedBox(width: 20),
                _MiniFeature(
                  icon: Icons.local_shipping_outlined,
                  label: 'Frota',
                ),
                SizedBox(width: 20),
                _MiniFeature(
                  icon: Icons.analytics_outlined,
                  label: 'Relatórios',
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _loginForm() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(26),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Bem-vindo',
              style: TextStyle(
                fontSize: 25,
                color: _ink,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Entre para explorar o app.',
              style: TextStyle(color: Colors.blueGrey),
            ),
            const SizedBox(height: 24),
            const Text(
              'Nome para demonstração',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.person_outline_rounded),
                hintText: 'Seu nome',
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Perfil de acesso',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'Administrador',
                  label: Text('Admin'),
                  icon: Icon(Icons.admin_panel_settings_outlined),
                ),
                ButtonSegment(
                  value: 'Colaborador',
                  label: Text('Colaborador'),
                  icon: Icon(Icons.engineering_outlined),
                ),
              ],
              selected: {_role},
              onSelectionChanged: (value) =>
                  setState(() => _role = value.first),
            ),
            const SizedBox(height: 22),
            FilledButton.icon(
              onPressed: () => widget.onLogin(_role, _nameController.text),
              icon: const Icon(Icons.login_rounded),
              label: const Padding(
                padding: EdgeInsets.symmetric(vertical: 13),
                child: Text('Entrar no ambiente de teste'),
              ),
            ),
            const SizedBox(height: 18),
            const _DemoBadge(),
            const SizedBox(height: 10),
            const Text(
              'Este protótipo usa dados locais de exemplo. Não informe senhas reais.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.blueGrey, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniFeature extends StatelessWidget {
  const _MiniFeature({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF9FD6FF), size: 18),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
      ],
    );
  }
}

class _AtlasMark extends StatelessWidget {
  const _AtlasMark({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFF17486E),
        borderRadius: BorderRadius.circular(size * .28),
        border: Border.all(color: const Color(0xFF68BCFF), width: 1.5),
      ),
      child: Text(
        'A',
        style: TextStyle(
          color: Colors.white,
          fontSize: size * .58,
          fontWeight: FontWeight.w900,
          height: 1,
        ),
      ),
    );
  }
}

class _DemoBadge extends StatelessWidget {
  const _DemoBadge();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4DB),
        borderRadius: BorderRadius.circular(30),
      ),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        child: Text(
          'DEMONSTRAÇÃO',
          style: TextStyle(
            color: Color(0xFF9A6500),
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: .7,
          ),
        ),
      ),
    );
  }
}

String _greeting() {
  final hour = DateTime.now().hour;
  if (hour < 12) return 'Bom dia';
  if (hour < 18) return 'Boa tarde';
  return 'Boa noite';
}

class DashboardPage extends StatelessWidget {
  const DashboardPage({
    required this.name,
    required this.role,
    required this.onNavigate,
    super.key,
  });

  final String name;
  final String role;
  final ValueChanged<String> onNavigate;

  @override
  Widget build(BuildContext context) {
    final admin = role == 'Administrador';
    return _PageBody(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(
                colors: [_navy, Color(0xFF14517D)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  admin ? 'CENTRAL DE COMANDO' : 'MODO OPERACIONAL',
                  style: const TextStyle(
                    color: Color(0xFF9FD6FF),
                    fontSize: 11,
                    letterSpacing: 1.8,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '${_greeting()}, $name',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 29,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  admin
                      ? 'Acompanhe a operação Atlas.'
                      : 'Tudo pronto para começar sua jornada.',
                  style: const TextStyle(color: Color(0xFFD2E2EF)),
                ),
                if (!admin) ...[
                  const SizedBox(height: 22),
                  FilledButton.icon(
                    onPressed: () => onNavigate('Checklist'),
                    icon: const Icon(Icons.fact_check_outlined),
                    label: const Text('Realizar checklist'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: _navy,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 22),
          _ResponsiveCards(
            children: [
              _MetricCard(
                icon: Icons.fact_check_outlined,
                label: 'Checklists concluídos',
                value: '84%',
                detail: '+8% neste mês',
                color: const Color(0xFF16A36A),
              ),
              _MetricCard(
                icon: Icons.local_shipping_outlined,
                label: 'Frota ativa',
                value: '24 / 27',
                detail: '3 em manutenção',
                color: _blue,
              ),
              _MetricCard(
                icon: Icons.construction_outlined,
                label: 'Operações hoje',
                value: '12',
                detail: '4 em andamento',
                color: const Color(0xFF8A57CF),
              ),
              _MetricCard(
                icon: Icons.folder_open_outlined,
                label: 'Pendências',
                value: '06',
                detail: 'Documentos e aprovações',
                color: const Color(0xFFE69A18),
              ),
            ],
          ),
          const SizedBox(height: 28),
          _SectionHeading(
            title: 'Acesso rápido',
            subtitle: 'Navegue pelas principais áreas do sistema.',
          ),
          const SizedBox(height: 14),
          _ResponsiveCards(
            children: [
              _QuickAction(
                title: admin ? 'Centro de auditoria' : 'Enviar documentos',
                subtitle: admin
                    ? 'Aprovar documentos pendentes'
                    : 'CNH, NR-35 e certificados',
                icon: admin
                    ? Icons.verified_user_outlined
                    : Icons.cloud_upload_outlined,
                onTap: () => onNavigate('Documentos'),
              ),
              _QuickAction(
                title: admin ? 'Gestão de frota' : 'Minha carteira',
                subtitle: admin
                    ? 'Veículos, ativos e manutenção'
                    : 'Acompanhe seus documentos',
                icon: admin
                    ? Icons.local_shipping_outlined
                    : Icons.badge_outlined,
                onTap: () => onNavigate(admin ? 'Frota' : 'Minha Carteira'),
              ),
              _QuickAction(
                title: admin ? 'Financeiro' : 'Operações',
                subtitle: admin
                    ? 'Resumo de receitas e despesas'
                    : 'Atividades e localização',
                icon: admin
                    ? Icons.account_balance_outlined
                    : Icons.route_outlined,
                onTap: () => onNavigate(admin ? 'Financeiro' : 'Operações'),
              ),
            ],
          ),
          const SizedBox(height: 28),
          _SectionHeading(
            title: 'Operações recentes',
            subtitle: 'Acompanhamento de serviços em campo.',
            trailing: TextButton(
              onPressed: () => onNavigate('Operações'),
              child: const Text('Ver todas'),
            ),
          ),
          const SizedBox(height: 10),
          const _OperationRow(
            id: 'OP-2026-014',
            client: 'Mineradora Vale',
            equipment: 'Guindaste Atlas 1070',
            status: 'Em andamento',
            color: _blue,
          ),
          const _OperationRow(
            id: 'OP-2026-013',
            client: 'Construcivil S.A.',
            equipment: 'Guindaste Atlas 3050',
            status: 'Pendente',
            color: Color(0xFFE69A18),
          ),
        ],
      ),
    );
  }
}

class _PageBody extends StatelessWidget {
  const _PageBody({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: child,
        ),
      ),
    );
  }
}

class _ResponsiveCards extends StatelessWidget {
  const _ResponsiveCards({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth > 850
            ? 4
            : constraints.maxWidth > 550
            ? 2
            : 1;
        const spacing = 14.0;
        final width =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: children
              .map((child) => SizedBox(width: width, child: child))
              .toList(),
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.detail,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final String detail;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(19),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 15),
            Text(
              label,
              style: const TextStyle(color: Colors.blueGrey, fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 4),
            Text(
              detail,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(color: Colors.blueGrey, fontSize: 12),
              ),
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F4FD),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: _blue),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.blueGrey,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: Colors.blueGrey,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OperationRow extends StatelessWidget {
  const _OperationRow({
    required this.id,
    required this.client,
    required this.equipment,
    required this.status,
    required this.color,
  });

  final String id;
  final String client;
  final String equipment;
  final String status;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.precision_manufacturing_outlined, color: _blue),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$id · $client',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    equipment,
                    style: const TextStyle(
                      color: Colors.blueGrey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            _StatusTag(label: status, color: color),
          ],
        ),
      ),
    );
  }
}

class _StatusTag extends StatelessWidget {
  const _StatusTag({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class OperationsPage extends StatefulWidget {
  const OperationsPage({
    required this.tracking,
    required this.onTrackingChanged,
    super.key,
  });

  final bool tracking;
  final ValueChanged<bool> onTrackingChanged;

  @override
  State<OperationsPage> createState() => _OperationsPageState();
}

class _OperationsPageState extends State<OperationsPage> {
  final _searchController = TextEditingController();

  static const _operations = [
    (
      'OP-2026-014',
      'Mineradora Vale',
      'Guindaste Atlas 1070',
      'Em andamento',
      _blue,
    ),
    (
      'OP-2026-013',
      'Construcivil S.A.',
      'Guindaste Atlas 3050',
      'Pendente',
      Color(0xFFE69A18),
    ),
    (
      'OP-2026-012',
      'Logística Brasil',
      'Munck Mercedes 2423',
      'Concluído',
      Color(0xFF16A36A),
    ),
    (
      'OP-2026-011',
      'Energia Solar',
      'Guindaste XCMG QY25K5',
      'Em andamento',
      _blue,
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.toLowerCase();
    final filtered = _operations
        .where(
          (op) => '${op.$1} ${op.$2} ${op.$3}'.toLowerCase().contains(query),
        )
        .toList();
    return _PageBody(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeading(
            title: 'Operações',
            subtitle: 'Acompanhe serviços, clientes e status em campo.',
          ),
          const SizedBox(height: 18),
          Card(
            child: SwitchListTile.adaptive(
              secondary: Icon(
                Icons.location_on_outlined,
                color: widget.tracking ? const Color(0xFFE69A18) : _blue,
              ),
              title: Text(
                widget.tracking ? 'Rastreamento ativo' : 'Rastreamento GPS',
              ),
              subtitle: Text(
                widget.tracking
                    ? 'Modo de demonstração — GPS não está sendo enviado.'
                    : 'Ative para simular o início de uma operação.',
              ),
              value: widget.tracking,
              onChanged: widget.onTrackingChanged,
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search_rounded),
              hintText: 'Buscar cliente, equipamento ou ID...',
            ),
          ),
          const SizedBox(height: 14),
          ...filtered.map(
            (op) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _OperationRow(
                id: op.$1,
                client: op.$2,
                equipment: op.$3,
                status: op.$4,
                color: op.$5,
              ),
            ),
          ),
          if (filtered.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: Text('Nenhuma operação encontrada.')),
            ),
        ],
      ),
    );
  }
}

class ChecklistPage extends StatefulWidget {
  const ChecklistPage({
    required this.completed,
    required this.onCompleted,
    super.key,
  });

  final bool completed;
  final VoidCallback onCompleted;

  @override
  State<ChecklistPage> createState() => _ChecklistPageState();
}

class _ChecklistPageState extends State<ChecklistPage> {
  static const List<String> _items = [
    'Inspecionar pneus, rodas e fixações',
    'Verificar freios e sistema hidráulico',
    'Conferir níveis de óleo e combustível',
    'Testar luzes, sinalização e alarme de ré',
    'Confirmar validade dos documentos do veículo',
    'Verificar equipamentos de proteção individual',
  ];
  late final List<bool> _checked = List<bool>.filled(_items.length, false);

  @override
  Widget build(BuildContext context) {
    final count = _checked.where((value) => value).length;
    return _PageBody(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeading(
            title: 'Checklist pré-operacional',
            subtitle: 'Faça a inspeção antes de iniciar o deslocamento.',
          ),
          const SizedBox(height: 18),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Guindaste Atlas 1070',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      _StatusTag(
                        label: widget.completed
                            ? 'Concluído'
                            : '$count/${_items.length}',
                        color: widget.completed
                            ? const Color(0xFF16A36A)
                            : _blue,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Veículo ABC-1D23 · Hoje',
                    style: TextStyle(color: Colors.blueGrey),
                  ),
                  const SizedBox(height: 14),
                  LinearProgressIndicator(
                    value: count / _items.length,
                    minHeight: 7,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          ...List.generate(
            _items.length,
            (index) => Card(
              child: CheckboxListTile(
                value: _checked[index],
                onChanged: widget.completed
                    ? null
                    : (value) =>
                          setState(() => _checked[index] = value ?? false),
                title: Text(_items[index]),
                controlAffinity: ListTileControlAffinity.leading,
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: widget.completed
                  ? null
                  : count == _items.length
                  ? () {
                      widget.onCompleted();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Checklist concluído neste dispositivo.',
                          ),
                        ),
                      );
                    }
                  : null,
              icon: const Icon(Icons.task_alt_rounded),
              label: Text(
                widget.completed
                    ? 'Checklist concluído'
                    : 'Finalizar checklist',
              ),
            ),
          ),
          if (count < _items.length && !widget.completed)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'Marque todos os itens para habilitar a conclusão.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.blueGrey, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }
}

class Vehicle {
  Vehicle(this.model, this.plate, this.status, this.year);

  final String model;
  final String plate;
  final String status;
  final String year;
}

class FleetPage extends StatelessWidget {
  const FleetPage({required this.vehicles, required this.onAdd, super.key});

  final List<Vehicle> vehicles;
  final ValueChanged<Vehicle> onAdd;

  @override
  Widget build(BuildContext context) {
    return _PageBody(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeading(
            title: 'Frota e ativos',
            subtitle: 'Gestão técnica e disponibilidade dos equipamentos.',
            trailing: FilledButton.icon(
              onPressed: () => _showAddVehicle(context),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Novo veículo'),
            ),
          ),
          const SizedBox(height: 18),
          _ResponsiveCards(
            children: [
              _MetricCard(
                icon: Icons.local_shipping_outlined,
                label: 'Total de veículos',
                value: '${vehicles.length}',
                detail: 'Na frota cadastrada',
                color: _blue,
              ),
              _MetricCard(
                icon: Icons.check_circle_outline,
                label: 'Ativos',
                value: '${vehicles.where((v) => v.status == 'Ativo').length}',
                detail: 'Disponíveis para operação',
                color: const Color(0xFF16A36A),
              ),
              const _MetricCard(
                icon: Icons.build_outlined,
                label: 'Em manutenção',
                value: '01',
                detail: 'Acompanhe os serviços',
                color: Color(0xFFE69A18),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...vehicles.map(
            (vehicle) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Card(
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFE8F4FD),
                    child: Icon(Icons.local_shipping_outlined, color: _blue),
                  ),
                  title: Text(
                    vehicle.model,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: Text('${vehicle.plate} · Ano ${vehicle.year}'),
                  trailing: _StatusTag(
                    label: vehicle.status,
                    color: vehicle.status == 'Ativo'
                        ? const Color(0xFF16A36A)
                        : const Color(0xFFE69A18),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddVehicle(BuildContext context) async {
    final model = TextEditingController();
    final plate = TextEditingController();
    final year = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final vehicle = await showDialog<Vehicle>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cadastrar veículo'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: model,
                decoration: const InputDecoration(labelText: 'Modelo'),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Informe o modelo'
                    : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: plate,
                decoration: const InputDecoration(labelText: 'Placa'),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Informe a placa'
                    : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: year,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Ano'),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Informe o ano'
                    : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(
                  context,
                  Vehicle(
                    model.text.trim(),
                    plate.text.trim().toUpperCase(),
                    'Ativo',
                    year.text.trim(),
                  ),
                );
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
    model.dispose();
    plate.dispose();
    year.dispose();
    if (vehicle != null) onAdd(vehicle);
  }
}

class DocumentsPage extends StatelessWidget {
  const DocumentsPage({required this.role, super.key});

  final String role;

  @override
  Widget build(BuildContext context) {
    final isAdmin = role == 'Administrador';
    return _PageBody(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeading(
            title: isAdmin ? 'Centro de auditoria' : 'Meus documentos',
            subtitle: isAdmin
                ? 'Analise documentos e acompanhe as pendências.'
                : 'Acompanhe o status dos seus documentos.',
            trailing: isAdmin
                ? null
                : FilledButton.icon(
                    onPressed: () => _showDocumentNotice(context),
                    icon: const Icon(Icons.upload_file_rounded),
                    label: const Text('Enviar'),
                  ),
          ),
          const SizedBox(height: 18),
          if (isAdmin)
            const _NoticeCard(
              icon: Icons.info_outline_rounded,
              text:
                  'Os registros abaixo são de demonstração; nenhuma aprovação é enviada ao servidor.',
            ),
          ...const [
            ('Marcos Silva', 'CNH categoria D', '15/08/2026', 'Pendente'),
            ('Ana Oliveira', 'NR-35', '04/11/2026', 'Aprovado'),
            ('Carlos Santos', 'Exame médico', '20/07/2026', 'Revisar'),
          ].map(
            (doc) => Card(
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFE8F4FD),
                  child: Icon(Icons.description_outlined, color: _blue),
                ),
                title: Text(
                  isAdmin ? doc.$1 : doc.$2,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: Text('${doc.$2} · Validade ${doc.$3}'),
                trailing: _StatusTag(
                  label: doc.$4,
                  color: doc.$4 == 'Aprovado'
                      ? const Color(0xFF16A36A)
                      : doc.$4 == 'Pendente'
                      ? const Color(0xFFE69A18)
                      : const Color(0xFFD64E55),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDocumentNotice(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => const DemoFeatureDialog(
        icon: Icons.upload_file_rounded,
        title: 'Envio de documentos',
        description:
            'A área de documentos está pronta para navegação. Para enviar arquivos de verdade, '
            'a próxima etapa é integrar o armazenamento e o serviço de autenticação.',
      ),
    );
  }
}

class MaintenancePage extends StatelessWidget {
  const MaintenancePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _SimpleListPage(
      title: 'Manutenções',
      subtitle: 'Programação e acompanhamento de serviços da frota.',
      items: [
        (
          'Atlas 3050 · ABC-1D23',
          'Troca de mangueira hidráulica',
          'Em andamento',
        ),
        (
          'Munck Mercedes · GHI-7J89',
          'Revisão preventiva · 500 horas',
          'Agendada',
        ),
        ('XCMG QY25K5 · JKL-0M12', 'Inspeção de segurança', 'Concluída'),
      ],
      icon: Icons.build_circle_outlined,
    );
  }
}

class FinancePage extends StatelessWidget {
  const FinancePage({super.key});

  @override
  Widget build(BuildContext context) {
    return _PageBody(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeading(
            title: 'Financeiro',
            subtitle: 'Resumo demonstrativo de receitas e despesas.',
          ),
          const SizedBox(height: 18),
          const _ResponsiveCards(
            children: [
              _MetricCard(
                icon: Icons.trending_up_rounded,
                label: 'Receita do mês',
                value: 'R\$ 284 mil',
                detail: '+12,4% vs. mês anterior',
                color: Color(0xFF16A36A),
              ),
              _MetricCard(
                icon: Icons.trending_down_rounded,
                label: 'Despesas',
                value: 'R\$ 176 mil',
                detail: '61,9% da receita',
                color: Color(0xFFD64E55),
              ),
              _MetricCard(
                icon: Icons.account_balance_outlined,
                label: 'Resultado',
                value: 'R\$ 108 mil',
                detail: 'Margem operacional 38,1%',
                color: _blue,
              ),
            ],
          ),
          const SizedBox(height: 22),
          const _NoticeCard(
            icon: Icons.bar_chart_rounded,
            text:
                'Valores fictícios para visualização. Conecte a fonte financeira para dados reais.',
          ),
          const SizedBox(height: 12),
          const _ProgressMetric(
            label: 'Receita atingida',
            value: .72,
            color: _blue,
          ),
          const _ProgressMetric(
            label: 'Despesas do orçamento',
            value: .54,
            color: Color(0xFFE69A18),
          ),
        ],
      ),
    );
  }
}

class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _PageBody(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeading(
            title: 'Relatórios',
            subtitle: 'Indicadores operacionais do período.',
          ),
          SizedBox(height: 18),
          _NoticeCard(
            icon: Icons.analytics_outlined,
            text:
                'Painel de demonstração. Os gráficos usam números ilustrativos.',
          ),
          SizedBox(height: 14),
          _ProgressMetric(
            label: 'Utilização da frota',
            value: .84,
            color: _blue,
          ),
          _ProgressMetric(
            label: 'Checklists em dia',
            value: .92,
            color: Color(0xFF16A36A),
          ),
          _ProgressMetric(
            label: 'Documentos válidos',
            value: .76,
            color: Color(0xFFE69A18),
          ),
          _ProgressMetric(
            label: 'Operações no prazo',
            value: .88,
            color: Color(0xFF8A57CF),
          ),
        ],
      ),
    );
  }
}

class UsersPage extends StatelessWidget {
  const UsersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _SimpleListPage(
      title: 'Usuários',
      subtitle: 'Aprovações e acessos pendentes.',
      items: [
        ('João Ferreira', 'Operador · Cadastro recebido hoje', 'Pendente'),
        ('Ana Oliveira', 'Motorista · Documentos validados', 'Ativo'),
        ('Carlos Santos', 'Técnico · Cadastro recebido ontem', 'Pendente'),
      ],
      icon: Icons.person_outline_rounded,
    );
  }
}

class WalletPage extends StatelessWidget {
  const WalletPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _SimpleListPage(
      title: 'Minha carteira',
      subtitle: 'Documentos e qualificações do colaborador.',
      items: [
        ('CNH categoria D', 'Válida até 15/08/2026', 'Aprovado'),
        ('Certificado NR-35', 'Válido até 04/11/2026', 'Aprovado'),
        ('Exame médico', 'Atualização necessária', 'Revisar'),
      ],
      icon: Icons.badge_outlined,
    );
  }
}

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _SimpleListPage(
      title: 'Notificações',
      subtitle: 'Avisos recentes do ambiente de demonstração.',
      items: [
        (
          'Checklist disponível',
          'Realize a inspeção antes da próxima operação.',
          'Hoje',
        ),
        (
          'Documento próximo do vencimento',
          'O exame médico vence em 20/07/2026.',
          'Ontem',
        ),
        (
          'Manutenção programada',
          'Revisão preventiva agendada para 25/06/2026.',
          '18 jun',
        ),
      ],
      icon: Icons.notifications_none_rounded,
    );
  }
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({
    required this.name,
    required this.role,
    required this.darkMode,
    required this.onDarkModeChanged,
    required this.onLogout,
    super.key,
  });

  final String name;
  final String role;
  final bool darkMode;
  final ValueChanged<bool> onDarkModeChanged;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return _PageBody(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeading(
            title: 'Configurações',
            subtitle: 'Preferências do aplicativo e conta atual.',
          ),
          const SizedBox(height: 18),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.person_outline_rounded),
                  ),
                  title: Text(name),
                  subtitle: Text('$role · Conta de demonstração'),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  secondary: const Icon(Icons.dark_mode_outlined),
                  title: const Text('Tema escuro'),
                  subtitle: const Text('Altere a aparência neste dispositivo.'),
                  value: darkMode,
                  onChanged: onDarkModeChanged,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(
                    Icons.logout_rounded,
                    color: Color(0xFFD64E55),
                  ),
                  title: const Text('Sair do ambiente de teste'),
                  onTap: onLogout,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SimpleListPage extends StatelessWidget {
  const _SimpleListPage({
    required this.title,
    required this.subtitle,
    required this.items,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final List<(String, String, String)> items;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return _PageBody(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeading(title: title, subtitle: subtitle),
          const SizedBox(height: 18),
          ...items.map(
            (item) => Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFFE8F4FD),
                  child: Icon(icon, color: _blue),
                ),
                title: Text(
                  item.$1,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: Text(item.$2),
                trailing: _StatusTag(
                  label: item.$3,
                  color:
                      item.$3 == 'Aprovado' ||
                          item.$3 == 'Ativo' ||
                          item.$3 == 'Concluída'
                      ? const Color(0xFF16A36A)
                      : const Color(0xFFE69A18),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressMetric extends StatelessWidget {
  const _ProgressMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(17),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                Text(
                  '${(value * 100).round()}%',
                  style: TextStyle(color: color, fontWeight: FontWeight.w900),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: value,
              minHeight: 8,
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoticeCard extends StatelessWidget {
  const _NoticeCard({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFFEAF4FC),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Row(
          children: [
            Icon(icon, color: _blue),
            const SizedBox(width: 11),
            Expanded(child: Text(text, style: const TextStyle(fontSize: 12))),
          ],
        ),
      ),
    );
  }
}

class DemoFeatureDialog extends StatelessWidget {
  const DemoFeatureDialog({
    required this.icon,
    required this.title,
    required this.description,
    super.key,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: Icon(icon, color: _blue, size: 34),
      title: Text(title),
      content: Text(description),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Entendi'),
        ),
      ],
    );
  }
}
