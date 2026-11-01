import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/theme.dart';
import 'design/design_gallery.dart';
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
        title: 'ATLAS LOG',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(dark: false),
        builder: (context, child) => AtlasBackdrop(child: child!),
        home: const Scaffold(body: _Splash()),
      );
    }

    final route = Uri.base.fragment;
    final routeUri = Uri.tryParse(route);
    final publicTracking = routeUri?.path == '/rastreio';
    final trackingCode = routeUri?.queryParameters['codigo'] ?? '';
    // DESIGN: galeria de componentes para designers (/#/design).
    final designGallery = routeUri?.path == '/design';

    return MaterialApp(
      title: 'ATLAS LOG',
      debugShowCheckedModeBanner: false,
      themeMode: store.settings.darkMode ? ThemeMode.dark : ThemeMode.light,
      theme: buildTheme(dark: false),
      darkTheme: buildTheme(dark: true),
      // AtlasColors é ThemeExtension: a troca claro/escuro vira crossfade.
      themeAnimationDuration: AtlasMotion.slow,
      themeAnimationCurve: AtlasMotion.standard,
      builder: (context, child) => AtlasBackdrop(child: child!),
      home: AnimatedSwitcher(
        duration: AtlasMotion.slow,
        reverseDuration: AtlasMotion.fast,
        switchInCurve: AtlasMotion.enter,
        switchOutCurve: AtlasMotion.exit,
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween(begin: 1.015, end: 1.0).animate(animation),
            child: child,
          ),
        ),
        child: designGallery
          ? const DesignGalleryPage()
          : publicTracking
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
          return SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(mobile ? 16 : 40),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - (mobile ? 32 : 80),
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1120),
                    child: FadeSlideIn(
                      scale: 0.98,
                      offset: const Offset(0, 18),
                      child: _welcomePanel(colors, mobile: mobile),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _welcomePanel(AtlasColors colors, {required bool mobile}) => Glass(
    radius: AtlasRadius.xl,
    highlight: true,
    padding: EdgeInsets.all(mobile ? 22 : 52),
    child: ConstrainedBox(
      constraints: BoxConstraints(minHeight: mobile ? 0 : 500),
      child: mobile
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _brandContent(colors, mobile: true),
                const SizedBox(height: 28),
                FadeSlideIn(index: 4, child: _loginForm(context, colors)),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(child: _brandContent(colors, mobile: false)),
                const SizedBox(width: 64),
                SizedBox(
                  width: 400,
                  child: FadeSlideIn(
                    index: 3,
                    offset: const Offset(24, 0),
                    child: _loginForm(context, colors),
                  ),
                ),
              ],
            ),
    ),
  );

  Widget _brandContent(AtlasColors colors, {required bool mobile}) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: mobile
        ? CrossAxisAlignment.center
        : CrossAxisAlignment.start,
    children: staggered([
      Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AtlasRadius.lg),
          color: colors.surface.withValues(alpha: 0.7),
          border: Border.all(color: colors.border),
          boxShadow: AtlasShadows.glow(colors.accent2, strength: 0.6),
        ),
        child: AtlasLogo3D(size: mobile ? 60 : 76, sway: true),
      ),
      SizedBox(height: mobile ? 16 : 22),
      ShaderMask(
        blendMode: BlendMode.srcIn,
        shaderCallback: (rect) => LinearGradient(
          colors: [colors.text, Color.lerp(colors.text, colors.accent3, 0.55)!],
        ).createShader(rect),
        child: Text(
          'ATLAS LOG',
          textAlign: mobile ? TextAlign.center : TextAlign.start,
          style: TextStyle(
            fontSize: mobile ? 30 : 44,
            fontWeight: FontWeight.w800,
            letterSpacing: -1.2,
            height: 1.05,
          ),
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
            fontSize: mobile ? 15 : 18,
            height: 1.5,
          ),
        ),
      ),
      SizedBox(height: mobile ? 20 : 30),
      Wrap(
        alignment: mobile ? WrapAlignment.center : WrapAlignment.start,
        spacing: 10,
        runSpacing: 10,
        children: const [
          _FeatureItem(icon: Icons.route_rounded, label: 'Rotas'),
          _FeatureItem(icon: Icons.inventory_2_rounded, label: 'Pedidos'),
          _FeatureItem(icon: Icons.insights_rounded, label: 'Métricas'),
        ],
      ),
    ]),
  );

  Widget _loginForm(BuildContext context, AtlasColors colors) => Container(
    padding: EdgeInsets.all(MediaQuery.sizeOf(context).width < 420 ? 20 : 30),
    decoration: BoxDecoration(
      color: colors.card.withValues(alpha: colors.dark ? 0.85 : 0.96),
      border: Border.all(color: colors.border),
      borderRadius: BorderRadius.circular(AtlasRadius.lg),
      boxShadow: AtlasShadows.raised(colors),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Bem-vindo',
          style: TextStyle(
            fontSize: 27,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.6,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Acesse seu ambiente de gestão logística.',
          style: TextStyle(color: colors.muted),
        ),
        const SizedBox(height: 26),
        TextField(
          controller: _name,
          onChanged: widget.onNameChanged,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => widget.onLogin(),
          decoration: const InputDecoration(
            labelText: 'Seu nome',
            prefixIcon: Icon(Icons.person_outline_rounded),
          ),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<UserRole>(
          isExpanded: true,
          initialValue: widget.role,
          borderRadius: BorderRadius.circular(AtlasRadius.md),
          dropdownColor: colors.surface,
          decoration: const InputDecoration(
            labelText: 'Perfil de acesso',
            prefixIcon: Icon(Icons.badge_outlined),
          ),
          items: [
            for (final role in UserRole.values)
              DropdownMenuItem(value: role, child: Text(role.label)),
          ],
          onChanged: (role) {
            if (role != null) widget.onRoleChanged(role);
          },
        ),
        const SizedBox(height: 24),
        Button3D(
          label: 'Entrar no ambiente de teste',
          icon: Icons.arrow_forward_rounded,
          onPressed: widget.onLogin,
        ),
        if (widget.startupError != null) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colors.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AtlasRadius.sm),
              border: Border.all(color: colors.warning.withValues(alpha: 0.3)),
            ),
            child: Text(
              'O armazenamento do navegador não está disponível. As alterações desta sessão não serão persistidas.',
              style: TextStyle(color: colors.warning, fontSize: 12),
            ),
          ),
        ],
        const SizedBox(height: 18),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline_rounded, size: 13, color: colors.muted),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                'Dados de demonstração. Não informe senhas ou dados reais.',
                textAlign: TextAlign.center,
                style: TextStyle(color: colors.muted, fontSize: 11),
              ),
            ),
          ],
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
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 6, 14, 6),
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(AtlasRadius.pill),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors.accent2.withValues(alpha: 0.12),
            ),
            child: Icon(icon, size: 15, color: colors.accent),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

/// Tela de carregamento inicial: logo com "respiração" suave.
class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FadeSlideIn(scale: 0.9, child: AtlasLogo3D(size: 64, sway: true)),
          SizedBox(height: 22),
          SizedBox(
            width: 120,
            child: LinearProgressIndicator(minHeight: 3),
          ),
        ],
      ),
    );
  }
}
