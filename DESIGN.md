# ATLAS LOG: design system and motion

No new packages. Everything is built on Flutter's own animation primitives
(`AnimationController`, implicit `Animated*` widgets, `BackdropFilter`).
`flutter pub get` is not needed for this redesign.

## Tokens (`lib/core/theme.dart`)

| Token | Purpose |
|---|---|
| `AtlasColors` | Palette, now a `ThemeExtension`. Switching between light and dark is a smooth crossfade (`themeAnimationDuration`). New colors: `accent3` (second gradient stop), `glass` (translucent fill), `shadow` (tinted shadow base), plus `brandGradient`. |
| `AtlasRadius` | `xs 6 · sm 10 · md 14 · lg 18 · xl 24 · pill` |
| `AtlasShadows` | `soft()` at rest, `raised()` for hover and floating surfaces, `glow(color)` for primary actions |
| `AtlasMotion` | `instant 90 · fast 150 · base 240 · slow 380 · entrance 460 ms`. Curves: `enter`, `exit`, `standard`, `pop`. `AtlasMotion.of(context, d)` returns zero when reduced motion is on. |
| `AtlasBreakpoints` | `phone 600 · tablet 940 · desktop 1100 · contentMax 1480` |

Read colors with `context.ac`, as before.

## Motion primitives (`lib/widgets/motion.dart`, re-exported by `common.dart`)

| API | Use |
|---|---|
| `FadeSlideIn(index:, offset:, scale:)` | Plays once when the widget mounts. The delay is part of the animation itself (no `Timer`s), so it is safe in widget tests. |
| `staggered([...])` | Wraps each child in `FadeSlideIn` with an increasing delay. It keeps each child's `key`, so a `ValueKey(id)` makes only *new* rows animate. |
| `PressScale` | Shrinks the child slightly while pressed (tactile feedback). |
| `AtlasBackdrop` | Static gradient mesh behind the whole app (`MaterialApp.builder`). |
| `showAtlasDialog` | Drop-in replacement for `showDialog`. The background blurs as the dialog opens; the dialog fades, scales and rises in, then leaves on a faster exit curve. |

## Components (`lib/widgets/common.dart`, same public APIs)

- `Glass`: real backdrop blur, translucent fill, light edge highlight. Options: `highlight:` (gradient wash) and `blur: 0` (cheaper, no blur).
- `GlassCard`: on hover, tinted border and raised shadow; it also lifts 3 px if it is clickable. Clickable cards shrink slightly when pressed.
- `Button3D`: brand-gradient fill and glow, built as a keycap (see "Depth and lighting" below). Async actions crossfade from idle to spinner to a green ✓.
- `StatusChip`: pill shape. A status change crossfades with a small pop; the in-transit dot glows.
- `Skeleton` / `PageSkeleton`: moving shimmer; the layout adapts to screen width.
- `EmptyState`: icon in a halo, with a soft entrance.
- `toast`: floating, fixed width on wide screens, with an icon that pops in.
- `Icon3D`: tinted tile at 40 px and up. The `motion` and `loop` parameters now animate, and hover plays the motion once.

## Depth and lighting (round 2)

**One light source.** `AtlasLight` in `theme.dart` defines a light coming from the top-left. All 3D widgets use it, so their highlights and shadows agree:

| Helper | Use |
|---|---|
| `AtlasLight.volume(color)` | Face shading: lit top-left, self-shadow bottom-right |
| `AtlasLight.sheen()` | Specular reflection along the top edge (plastic/glass) |
| `AtlasLight.edge(color)` | Colour of an object's extruded side |
| `AtlasLight.elevation(tint, 0..1)` | Layered tinted shadows: short contact shadow + long ambient shadow |

**3D widgets**

- `AtlasLogo3D`: the mark is extruded (layers offset away from the light) and the face is lit with gradients. A light sweep runs on load and on hover. At 56 px and up it tilts toward the pointer. New options: `extrude:`, `interactive:`.
- `Button3D`: built like a keycap. A lit face sits on top of a darker edge. Hover lifts the face 1 px; pressing sinks it into the edge. It also has a 2 px keyboard focus ring.
- `Icon3D`: tile with a volume gradient, a glossy reflection, a relief shadow under the glyph, and a coloured shadow that grows on hover.
- `Tilt3D` (`widgets/depth.dart`): perspective tilt toward the pointer with a moving glare. It is used on clickable KPI cards. It does nothing on touch screens or with reduced motion.

**Transitions**

- `AtlasPageSwitcher`: switching tabs feels like moving through depth. The new page rises in; the old one recedes and fades quickly.
- `AtlasPageTransitionsBuilder`: registered in the theme, so every `Navigator.push` / `MaterialPageRoute` uses the same depth transition. The page underneath recedes too.
- `AnimatedItems<T>`: a list that animates both entries and exits, diffed automatically by key. You just pass the new list. It is used for orders (deleting, filtering, paging) and notifications (marking read, clearing).

**Structure.** `pages/logistics_pages.dart` is now just a library file. The screens live in `pages/logistics/` (shell, dashboard, orders, fleet, public tracking) as `part` files, so private widgets stay private and no imports changed. Reusable widgets in `widgets/` (`common`, `motion`, `depth`, `button3d`, `icon3d`, `atlas_logo_3d`) don't depend on `AtlasStore`.

## Rules of thumb

1. Every duration goes through `AtlasMotion.of(context, …)` so reduced motion is respected.
2. Never put an always-on animation in a long list. `loop: true` on `Icon3D` is fine for a few items.
3. Use `Glass` for chrome and overlays, and `GlassCard` for content. Avoid blur inside scrolling lists.
4. Give list items a `ValueKey(id)` so filtering or paging animates only the items that change. For lists that also need exit animations, use `AnimatedItems`.
5. Use `AtlasLight` for highlights and shadows instead of loose colours. If the light comes from different directions, the depth breaks.
6. Use `Tilt3D` only on clickable elements. Tilt tells the user "this does something".

## Marca e Expo Glass (rodada 3)

**Logo novo (`widgets/atlas_logo_3d.dart`).** Mesma API (`size`, `showWordmark`, `extrude`, `interactive`) + novo `sway`.

- Desenho: "A" lapidado (cada perna com face escura e face clara) atravessado por uma flecha que sobe para a direita. Onde a flecha cruza o "A" há um recorte real (`BlendMode.clear`).
- Movimento: entrada girando em Y (1,1 s, easeOutCubic) → reflexo de luz (1,4 s) → `sway` opcional (balanço de ±18° em 10 s). Hover repete o reflexo; ≥ 56 px inclina com o ponteiro (`Tilt3D`).
- `sway: true` está ligado no login, na tela de carregamento e na galeria. Menu lateral fica sem balanço.
- Wordmark: **ATLAS** (marinho / branco no escuro) + **LOG** (verde-azulado), legenda "CONNECTING THE WORLD".

**Paleta da marca** (`AtlasColors`, `design-tokens.json → brand`): marinho `#0E3A6B`, azul `#1F6FA8`, verde-azulado `#2BB3B1`. O violeta anterior saiu dos dois temas.

**Expo Glass.** Todo `Glass` (barras, painéis, diálogos, paleta de comandos) ganhou reflexo especular no topo (branco 45% → 0 em 32% da altura; 10% no escuro), somado ao blur e à borda clara que já existiam.

**Web.** `favicon.png`, `Icon-192/512`, `Icon-maskable-192/512` e `atlas-logo.svg` agora usam a marca nova. `theme_color` = `#0E3A6B`.
