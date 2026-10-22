import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/theme.dart';
import 'models/models.dart';
import 'pages/logistics_pages.dart';
import 'services/store.dart';
import 'widgets/atlas_logo_3d.dart';
import 'widgets/button3d.dart';

void main() {
  runApp(const AtlasLogApp());
}

class AtlasLogApp extends StatefulWidget {
  const AtlasLogApp({super.key});

  @override
  State<AtlasLogApp> createState() => _AtlasLogAppState();
}

class _AtlasLogAppState extends State<AtlasLogApp> {
  AtlasStore? _store;
  Object? _startupError;
  bool _signedIn = false;
  String _name = '';
  UserRole _loginRole = UserRole.admin;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final store = AtlasStore(prefs: preferences);
      await store.load();
      if (!mounted) {
        store.dispose();
        return;
      }
      store.addListener(_onStoreChanged);
      setState(() => _store = store);
    } catch (error, stackTrace) {
      debugPrint('Falha ao iniciar a persistência local do Atlas: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;
      final store = AtlasStore(loadDelay: Duration.zero);
      await store.load();
      store.addListener(_onStoreChanged);
      setState(() {
        _store = store;
        _startupError = error;
      });
    }
  }

  void _onStoreChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _store?.removeListener(_onStoreChanged);
    _store?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = _store;
    if (store == null) {
      return MaterialApp(
        title: 'ATLAS LOG',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(dark: false),
        home: const Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    final route = Uri.base.fragment;
    final routeUri = Uri.tryParse(route);
    final publicTracking = routeUri?.path == '/rastreio';
    final trackingCode = routeUri?.queryParameters['codigo'] ?? '';

    return MaterialApp(
      title: 'ATLAS LOG',
      debugShowCheckedModeBanner: false,
      themeMode: store.settings.darkMode ? ThemeMode.dark : ThemeMode.light,
      theme: buildTheme(dark: false),
      darkTheme: buildTheme(dark: true),
      home: publicTracking
          ? PublicTrackingPage(store: store, initialCode: trackingCode)
          : _signedIn
          ? LogisticsShell(store: store, userName: _name)
          : _LoginPage(
              name: _name,
              role: _loginRole,
              startupError: _startupError,
              onNameChanged: (value) => _name = value,
              onRoleChanged: (value) => setState(() => _loginRole = value),
              onLogin: () {
                store.updateSettings((settings) {
                  settings
                    ..userName = _name.trim().isEmpty
                        ? 'Operador Atlas'
                        : _name.trim()
                    ..role = _loginRole;
                });
                setState(() => _signedIn = true);
              },
            ),
    );
  }
}

class _LoginPage extends StatefulWidget {
  const _LoginPage({
    required this.name,
    required this.role,
    required this.startupError,
    required this.onNameChanged,
    required this.onRoleChanged,
    required this.onLogin,
  });

  final String name;
  final UserRole role;
  final Object? startupError;
  final ValueChanged<String> onNameChanged;
  final ValueChanged<UserRole> onRoleChanged;
  final VoidCallback onLogin;

  @override
  State<_LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<_LoginPage> {
  late final TextEditingController _name = TextEditingController(
    text: widget.name,
  );

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.ac;
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final mobile = constraints.maxWidth < 980;
          return ColoredBox(
            color: colors.bg,
            child: SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(mobile ? 16 : 40),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1080),
                    child: _welcomePanel(colors, mobile: mobile),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _welcomePanel(AtlasColors colors, {required bool mobile}) => Container(
    constraints: BoxConstraints(minHeight: mobile ? 0 : 520),
    padding: EdgeInsets.all(mobile ? 22 : 48),
    decoration: BoxDecoration(
      color: colors.surface,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: colors.border),
    ),
    child: mobile
        ? Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _brandContent(colors, mobile: true),
              const SizedBox(height: 28),
              _loginForm(context, colors),
            ],
          )
        : Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: _brandContent(colors, mobile: false)),
              const SizedBox(width: 64),
              SizedBox(width: 390, child: _loginForm(context, colors)),
            ],
          ),
  );

  Widget _brandContent(AtlasColors colors, {required bool mobile}) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: mobile
        ? CrossAxisAlignment.center
        : CrossAxisAlignment.start,
    children: [
      AtlasLogo3D(size: mobile ? 72 : 96),
      SizedBox(height: mobile ? 14 : 18),
      Text(
        'ATLAS LOG',
        textAlign: mobile ? TextAlign.center : TextAlign.start,
        style: TextStyle(
          color: colors.text,
          fontSize: mobile ? 28 : 34,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.1,
          height: 1.1,
        ),
      ),
      const SizedBox(height: 12),
      ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Text(
          'Gestão logística, rastreamento e operação em um só lugar.',
          textAlign: mobile ? TextAlign.center : TextAlign.start,
          style: TextStyle(
            color: colors.muted,
            fontSize: mobile ? 14 : 17,
            height: 1.5,
          ),
        ),
      ),
      SizedBox(height: mobile ? 20 : 28),
      Wrap(
        alignment: mobile ? WrapAlignment.center : WrapAlignment.start,
        spacing: 22,
        runSpacing: 12,
        children: const [
          _FeatureItem(icon: Icons.route_rounded, label: 'Rotas'),
          _FeatureItem(icon: Icons.inventory_2_rounded, label: 'Pedidos'),
          _FeatureItem(icon: Icons.insights_rounded, label: 'Métricas'),
        ],
      ),
    ],
  );

  Widget _loginForm(BuildContext context, AtlasColors colors) => Container(
    padding: EdgeInsets.all(MediaQuery.sizeOf(context).width < 420 ? 20 : 28),
    decoration: BoxDecoration(
      color: colors.card,
      border: Border.all(color: colors.border),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Bem-vindo',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 5),
        Text(
          'Acesse seu ambiente de gestão logística.',
          style: TextStyle(color: colors.muted),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _name,
          onChanged: widget.onNameChanged,
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(
            labelText: 'Seu nome',
            prefixIcon: Icon(Icons.person_outline_rounded),
          ),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<UserRole>(
          isExpanded: true,
          initialValue: widget.role,
          decoration: const InputDecoration(labelText: 'Perfil de acesso'),
          items: [
            for (final role in UserRole.values)
              DropdownMenuItem(value: role, child: Text(role.label)),
          ],
          onChanged: (role) {
            if (role != null) widget.onRoleChanged(role);
          },
        ),
        const SizedBox(height: 22),
        Button3D(
          label: 'Entrar no ambiente de teste',
          icon: Icons.login_rounded,
          onPressed: widget.onLogin,
        ),
        if (widget.startupError != null) ...[
          const SizedBox(height: 14),
          Text(
            'O armazenamento do navegador não está disponível. As alterações desta sessão não serão persistidas.',
            style: TextStyle(color: colors.warning, fontSize: 12),
          ),
        ],
        const SizedBox(height: 16),
        Text(
          'Dados de demonstração. Não informe senhas ou dados reais.',
          textAlign: TextAlign.center,
          style: TextStyle(color: colors.muted, fontSize: 11),
        ),
      ],
    ),
  );
}

class _FeatureItem extends StatelessWidget {
  const _FeatureItem({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.ac;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: colors.accent2),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
      ],
    );
  }
}
