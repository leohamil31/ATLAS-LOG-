# ATLAS-LOG

Dashboard responsivo de demonstração para gestão de pedidos, rastreamento e
operação logística. O app Flutter funciona na web, Android e iOS.

## Acessar o app

[Abrir ATLAS-LOG no navegador](https://leohamil31.github.io/ATLAS-LOG-/)

## Funcionalidades

- Dashboard com KPIs, fluxo diário, distribuição por status, atividade e alertas.
- Cadastro, edição, busca, filtro, rastreamento e cancelamento de pedidos.
- Timeline de rastreio, etiqueta com QR Code/código de barras, simulador de
  frete e atalho para WhatsApp.
- Cadastro de motoristas, vínculo de cargas, mapa de posições estimadas e
  sugestão de sequência de paradas.
- Relatórios CSV/PDF, indicadores financeiros demonstrativos e backup JSON.
- Preferências, tema escuro, notificações e troca demonstrativa de perfil.
- Página pública de rastreio em `/rastreio?codigo=ATL-2400`.
- PWA instalável com cache de recursos do Flutter e dados operacionais salvos
  localmente no dispositivo.

## Executar

Na pasta `guindastesribas_flutter`:

```powershell
flutter pub get
flutter run -d chrome
```

Para testar e compilar a versão web:

```powershell
flutter test
flutter analyze
flutter build web
```

## Demonstração e limitações

Entre com qualquer nome e perfil de demonstração. Os pedidos, motoristas,
configurações e notificações são mantidos no armazenamento local do navegador
ou dispositivo. Use **Configurações → Exportar backup JSON** para baixar uma
cópia e **Resetar dados de teste** para restaurar o conjunto de exemplo.

O mapa mostra posições aproximadas derivadas das cidades conhecidas e precisa
de conexão para carregar os mapas do OpenStreetMap. O otimizador usa distâncias
aproximadas em linha reta; não é um serviço de roteamento rodoviário. O
assistente realiza buscas locais por linguagem simples e não chama um modelo
externo. Perfis RBAC, login, notificações e comprovante de foto são
demonstrativos; não substituem autenticação, armazenamento de arquivos ou
backend de produção. No fluxo de POD, a assinatura é capturada localmente; a
opção de foto simula a anexação.

O rastreamento público expõe somente o status e os dados logísticos que o app
de demonstração possui. Não armazene informações reais de clientes sem
integrar controles de acesso e um serviço seguro.
