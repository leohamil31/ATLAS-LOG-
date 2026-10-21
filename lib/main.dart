import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/theme.dart';
import 'models/models.dart';
import 'pages/logistics_pages.dart';
import 'services/store.dart';
import 'widgets/atlas_logo_3d.dart';
import 'widgets/button3d.dart';
import 'widgets/common.dart';

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
        title: 'ATLAS-LOG',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(dark: true),
        home: const Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    final route = Uri.base.fragment;
    final routeUri = Uri.tryParse(route);
    final publicTracking = routeUri?.path == '/rastreio';
    final trackingCode = routeUri?.queryParameters['codigo'] ?? '';

    return MaterialApp(
      title: 'ATLAS-LOG',
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
          return Stack(
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(-0.85, -0.9),
                      radius: 1.6,
                      colors: [
                        colors.accent.withValues(
                          alpha: colors.dark ? 0.2 : 0.12,
                        ),
                        colors.bg,
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: -110,
                left: -100,
                child: _ambientGlow(colors, 320),
              ),
              Positioned(
                right: -130,
                bottom: -150,
                child: _ambientGlow(colors, 380),
              ),
              SafeArea(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(mobile ? 16 : 40),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1200),
                      child: _welcomePanel(colors, mobile: mobile),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _ambientGlow(AtlasColors colors, double size) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: colors.accent.withValues(alpha: 0.05),
      boxShadow: [
        BoxShadow(
          color: colors.accent.withValues(alpha: 0.12),
          blurRadius: 100,
          spreadRadius: 32,
        ),
      ],
    ),
  );

  Widget _welcomePanel(AtlasColors colors, {required bool mobile}) => Container(
    constraints: BoxConstraints(minHeight: mobile ? 0 : 560),
    padding: EdgeInsets.all(mobile ? 20 : 42),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(mobile ? 26 : 34),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: colors.dark
            ? const [Color(0xFF0B314B), Color(0xFF071B2D), Color(0xFF061625)]
            : [colors.surface, colors.bg, const Color(0xFFDDEFF5)],
      ),
      border: Border.all(color: colors.accent.withValues(alpha: 0.42)),
      boxShadow: [
        BoxShadow(
          color: colors.accent.withValues(alpha: colors.dark ? 0.2 : 0.12),
          blurRadius: 58,
          spreadRadius: 1,
          offset: const Offset(0, 18),
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: colors.dark ? 0.35 : 0.08),
          blurRadius: 30,
          offset: const Offset(0, 20),
        ),
      ],
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
              const SizedBox(width: 48),
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
      AtlasLogo3D(size: mobile ? 126 : 184),
      SizedBox(height: mobile ? 10 : 4),
      Text(
        'ATLAS-LOG',
        textAlign: mobile ? TextAlign.center : TextAlign.start,
        style: TextStyle(
          color: colors.text,
          fontSize: mobile ? 30 : 42,
          fontWeight: FontWeight.w900,
          letterSpacing: mobile ? 1 : 1.4,
          height: 1.1,
          shadows: [
            Shadow(
              color: colors.accent.withValues(alpha: 0.42),
              blurRadius: 20,
            ),
          ],
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
      SizedBox(height: mobile ? 18 : 28),
      Wrap(
        alignment: mobile ? WrapAlignment.center : WrapAlignment.start,
        spacing: 10,
        runSpacing: 10,
        children: const [
          _FeaturePill(icon: Icons.route_rounded, label: 'Rotas'),
          _FeaturePill(icon: Icons.inventory_2_rounded, label: 'Pedidos'),
          _FeaturePill(icon: Icons.insights_rounded, label: 'Métricas'),
        ],
      ),
    ],
  );

  Widget _loginForm(BuildContext context, AtlasColors colors) => Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(24),
      boxShadow: [
        BoxShadow(
          color: colors.accent.withValues(alpha: colors.dark ? 0.2 : 0.12),
          blurRadius: 38,
          spreadRadius: 1,
        ),
      ],
    ),
    child: Glass(
      radius: 24,
      blur: 24,
      opacity: colors.dark ? 0.82 : 0.94,
      padding: EdgeInsets.all(MediaQuery.sizeOf(context).width < 420 ? 20 : 28),
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
    ),
  );
}

class _FeaturePill extends StatelessWidget {
  const _FeaturePill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.ac;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: colors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: colors.accent),
            const SizedBox(width: 7),
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
