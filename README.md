# Atlas

Aplicativo Flutter responsivo para web, Android e iOS.

## Executar no VS Code

Instale as extensões **Flutter** e **Dart**, abra esta pasta no VS Code e rode
no terminal:

```powershell
flutter pub get
flutter run -d chrome
```

Para Android, instale o Android Studio e as Android SDK Command-line Tools,
aceite as licenças com `flutter doctor --android-licenses` e execute `flutter
run` com um emulador ou aparelho conectado.

Para compilar o app iOS nativo, é necessário usar macOS com Xcode. No Windows,
é possível testar a versão web no navegador do iPhone, mas não gerar um
instalador iOS.

## Publicar no GitHub Pages

1. Use o repositório [leohamil31/ATLAS-LOG-](https://github.com/leohamil31/ATLAS-LOG-).
2. Envie **o conteúdo desta pasta** para a raiz do repositório.
3. No GitHub, abra **Settings → Pages** e escolha **GitHub Actions** como
   origem de publicação.
4. Envie a branch `main`. O workflow em `.github/workflows/pages.yml` testa e
   compila o app Flutter e publica o site automaticamente.
5. Se a primeira execução terminou antes de o Pages ser habilitado, abra
   **Actions → Publish Atlas to GitHub Pages** e selecione **Re-run jobs**.

Como o repositório está vazio, execute no terminal desta pasta:

```powershell
git init -b main
git add .
git commit -m "Publica o app Atlas"
git remote add origin https://github.com/leohamil31/ATLAS-LOG-.git
git push -u origin main
```

Depois da execução bem-sucedida do workflow, o site ficará disponível em
`https://leohamil31.github.io/ATLAS-LOG-/`.

## Escopo da demonstração

Login por perfil, navegação, dashboard, operações, checklist, cadastro de
veículos, documentos, manutenção, carteira, notificações, usuários, financeiro,
relatórios e tema claro/escuro estão disponíveis com dados de exemplo mantidos
na memória durante a sessão.

Autenticação real, sincronização e persistência, upload de documentos, GPS,
leitura de QR pela câmera precisam ser conectados a serviços
antes de uso em produção. Não informe dados ou senhas reais neste protótipo.
