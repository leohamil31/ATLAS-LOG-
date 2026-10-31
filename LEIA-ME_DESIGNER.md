# ATLAS LOG: pacote de front-end para design

Esta é a camada visual do app **ATLAS LOG** (Flutter/Dart, versão web),
separada para redesign, 3D e animação.

> **Para o Claude Designer:** o app é Flutter, não HTML/React. Toda a
> interface está em `lib/`. Mude a aparência em `lib/core/theme.dart` e
> `lib/widgets/`, e o layout das telas em `lib/pages/`. **Não altere** os
> arquivos marcados `DATA-BOUNDARY`. Mantenha os nomes e parâmetros públicos
> dos widgets, porque as telas e os testes dependem deles.

## Rodar

```bash
flutter pub get
flutter run -d chrome          # app completo (login → dashboard)
```

- **Galeria de componentes:** abra `http://localhost:<porta>/#/design`.
  Ela mostra todos os componentes e estados numa tela só, com alternância
  claro/escuro, sem login e com dados fixos.
- **Rastreio público:** `/#/rastreio?codigo=ATL-2400`.
- Não há backend: os dados são de demonstração e ficam no navegador.

Antes de entregar, rode:

```bash
dart format lib && flutter analyze && flutter test
```

## Estrutura

```
atlas-log-frontend/
├── LEIA-ME_DESIGNER.md      ← este guia
├── DESIGN.md                sistema de design detalhado (tokens, luz, movimento, regras)
├── design-tokens.json       cores (claro/escuro), raios, durações, curvas, breakpoints
├── pubspec.yaml             dependências (nenhuma de animação extra necessária)
├── web/                     index.html, manifest PWA, ícones, logo SVG
├── test/                    testes de widget (textos e layouts que não podem quebrar)
└── lib/
    ├── main.dart            app, fundo ambiente, login, rotas (/design, /rastreio)
    ├── core/
    │   └── theme.dart       ★ TOKENS: AtlasColors, AtlasLight, AtlasShadows,
    │                          AtlasRadius, AtlasMotion, AtlasBreakpoints, ThemeData
    ├── design/
    │   └── design_gallery.dart  ★ galeria /#/design
    ├── widgets/             ★ COMPONENTES (sem dependência do store)
    │   ├── common.dart      Glass, GlassCard, KpiCard, StatusChip, Skeleton,
    │   │                    EmptyState, DialogShell, toast, SectionHeader
    │   ├── motion.dart      FadeSlideIn, staggered, PressScale, AtlasBackdrop,
    │   │                    showAtlasDialog, AtlasPageSwitcher,
    │   │                    AtlasPageTransitionsBuilder, AnimatedItems
    │   ├── depth.dart       Tilt3D (inclinação 3D + reflexo)
    │   ├── atlas_logo_3d.dart   logo extrudado com brilho
    │   ├── button3d.dart    botão "tecla física"
    │   ├── icon3d.dart      ícone em ladrilho iluminado
    │   ├── order_dialogs.dart · extras_dialogs.dart   formulários e diálogos
    ├── pages/
    │   ├── logistics_pages.dart   índice (imports + parts)
    │   ├── logistics/       shell · dashboard_page · orders_page ·
    │   │                    fleet_page · public_tracking_page
    │   └── management_pages.dart  relatórios · notificações · configurações · assistente
    │
    ├── models/  services/  core/format.dart  core/geo.dart   ← DATA-BOUNDARY
```

As pastas `android/`, `ios/` e `.github/` ficaram de fora porque não são
necessárias para o design web. Para recriá-las, rode `flutter create .`.

## Onde mexer: marcadores no código

Para listar todos os marcadores:

```bash
grep -rn "DESIGN-SLOT\|MOTION-HOOK\|DATA-BOUNDARY" lib
```

| Marcador | Significado |
|---|---|
| `DESIGN-SLOT[id]` | Área visual pensada para ser redesenhada ou receber 3D |
| `MOTION-HOOK[id]` | Animação existente que pode ser ajustada |
| `DATA-BOUNDARY` | Dados e lógica. Não precisa mexer para redesenhar |

**Slots principais:** `hero` e `kpis` (dashboard), `sidebar` e `topbar`
(shell), `order-card` (pedidos), `map` e `driver-card` (frota),
`tracking-hero` e `timeline` (rastreio), `finance` (relatórios) e `logo`
(galeria).

**Movimento:** `page-switch`, `palette`, `stagger`, `list` (entrada e saída),
`dialog`, `tilt`, `count-up`, `button` e `chat`.

## Regras do sistema visual

1. **Cores, raios, durações e sombras vêm de `theme.dart`.** Não use cores
   soltas. Leia sempre a paleta com `context.ac`.
2. **A luz vem de cima-esquerda** (`AtlasLight`). Brilhos ficam no topo e
   sombras embaixo-direita. Uma luz inconsistente quebra o 3D.
3. **Toda duração passa por `AtlasMotion.of(context, …)`**, para respeitar o
   ajuste "reduzir movimento" do sistema.
4. **Use blur (`Glass`) só em barras, painéis e diálogos**, nunca em listas
   longas, por desempenho.
5. **Use `Tilt3D` só em elementos clicáveis.** A inclinação comunica "isso é
   clicável".
6. **Não use animações infinitas em listas longas.** `loop: true` no
   `Icon3D` é aceitável em poucos itens.
7. **Mantenha estes textos, porque os testes procuram por eles:** "Bem-vindo",
   "Entrar no ambiente de teste", "Olá, <nome>", "Veículos ativos",
   "Entregas em andamento", "Atrasos", "Em manutenção",
   "CENTRAL DE OPERAÇÕES", "Pedidos e rastreamento" e
   "Buscar pedido, motorista ou placa...". O login deve ter um único
   `TextField` e um único `AtlasLogo3D`.

## Próximos passos possíveis

- **Fundo ambiente animado:** `AtlasBackdrop` hoje é estático. Ele poderia
  ganhar um drift lento com `AnimationController` ou um `FragmentProgram`
  (shader).
- **Logo em 3D real:** usar `model_viewer_plus` com um arquivo `.glb`, ou
  `flutter_scene` (experimental).
- **Transições entre telas:** usar `Hero` com `flightShuttleBuilder` para
  levar o card do pedido até o diálogo de detalhes.
- **Gráficos:** animar a entrada dos gráficos do `fl_chart` usando os
  parâmetros de duração e curva da própria biblioteca, com os valores do
  `AtlasMotion`.
- **Pacotes opcionais:** `flutter_animate` (encadear efeitos) e `rive`
  (ilustrações animadas).
