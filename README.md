# STRK

Aplicação Flutter para acompanhar hábitos com Firebase.

## Início rápido

1. Instala dependências:

```bash
flutter pub get
```

2. Executa no simulador/emulador ou dispositivo:

```bash
flutter run
```

3. Executa análise e testes:

```bash
flutter analyze
flutter test
```

## Firebase

Este projecto usa Firebase. IMPORTANT: não comites ficheiros sensíveis no repositório:

- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`
- `macos/Runner/GoogleService-Info.plist`

Opções seguras:

- Mantém esses ficheiros fora do repo e partilha-os por um canal seguro.
- Usa `GitHub Secrets` para credenciais e variáveis de ambiente.
- Cria estes Secrets no GitHub Actions:
  - `GOOGLE_SERVICES_JSON`
  - `GOOGLE_SERVICE_INFO_PLIST`

### Voltar a gerar a configuração

O identificador da app é `com.strk.habittracker` em todas as plataformas.
Para voltar a gerar `lib/firebase_options.dart` e os ficheiros nativos:

```bash
LC_ALL=en_US.UTF-8 flutterfire configure --project=strk-thebestone \
  --platforms=android,ios,macos,web,windows \
  --ios-bundle-id=com.strk.habittracker --macos-bundle-id=com.strk.habittracker \
  --android-package-name=com.strk.habittracker --yes
```

Depois disso, confirma com `git diff`:

- o `LC_ALL` evita um erro de codificação do Ruby ao ler o `project.pbxproj`;
- o `flutterfire` acrescenta uma fase "upload-crashlytics-symbols" ao Xcode; remove-a, porque já existe a nossa, que salta os builds de simulador;
- se o login Google mudar de cliente, atualiza o `CFBundleURLSchemes` em `ios/Runner/Info.plist` e `macos/Runner/Info.plist` com o `REVERSED_CLIENT_ID` do plist novo.
## Emuladores (testar sem tocar na produção)

Para experimentar a app com contas e dados falsos, só no teu computador:

```bash
firebase emulators:start --only auth,firestore,storage --project strk-thebestone
flutter run -d chrome --dart-define=USE_EMULATORS=true
```

- As regras do Firestore e do Storage usadas são as do repositório.
- A interface dos emuladores fica em http://localhost:4000.
- Conta de teste usada nos testes manuais (só existe enquanto os emuladores correm; cria-a no ecrã de registo): `teste@strk.test` / `StrkEmulador-2026`.
- Limitação conhecida: na web, com os emuladores, a sessão não sobrevive a um F5. Em produção isto tem de ser verificado à parte.

## Web

- A chave do App Check na web passa-se ao compilar: `flutter build web --dart-define=APPCHECK_WEB_KEY=<chave reCAPTCHA v3>`. Sem chave, o App Check não é ativado na web.
- Em ecrãs largos a app fica numa coluna centrada (`lib/web_frame.dart`).
- Os lembretes não existem na web (o browser não tem notificações locais), por isso o switch fica escondido.

## Publicar (Firebase Hosting)

A versão web é publicada no Firebase Hosting do projeto `strk-thebestone`
(plano gratuito). A configuração está em `firebase.json` (`hosting`).

```bash
APPCHECK_WEB_KEY=<chave reCAPTCHA v3> ./scripts/deploy_web.sh
```

O script corre o `analyze` e os testes, compila com
`--no-web-resources-cdn` (o CanvasKit é servido pelo próprio site) e publica.

Para experimentar localmente com os mesmos cabeçalhos da produção:

```bash
flutter build web --release --no-web-resources-cdn
firebase emulators:start --only hosting   # http://127.0.0.1:5002
```

**Cabeçalhos:** `X-Frame-Options`, `nosniff`, `Referrer-Policy`, HSTS,
`Permissions-Policy` e uma Content Security Policy em modo
**Report-Only**: o browser avisa na consola quando algo a violaria, mas não
bloqueia. Depois do primeiro deploy, usa a app (login com email e Google,
foto de perfil, com App Check ligado) com a consola aberta. Quando não houver
avisos "violates the following Content Security Policy directive", troca
`Content-Security-Policy-Report-Only` por `Content-Security-Policy`.

**Fontes:** o Flutter vai buscar a Roboto e a Noto Sans Symbols ao Google
Fonts, porque o tema usa `SF Pro Display`, que não existe na web. Por isso a
CSP permite `fonts.gstatic.com`. Para não haver pedidos à Google só por causa
das fontes, a STRK deve passar a incluir a sua própria fonte nos assets.

### Antes do primeiro deploy (na consola do Firebase)

1. **App Check → Apps → STRK (Web)**: registar com reCAPTCHA v3 e guardar a chave do site.
2. **Authentication → Settings → Authorized domains**: acrescentar o domínio final (por exemplo `strk.diogofreire.is-a.dev`).
3. **Hosting → Add custom domain**: o Firebase indica os registos DNS a pôr no is-a.dev.

## CI

O workflow `.github/workflows/ci.yml` corre `flutter analyze --fatal-infos` e `flutter test` em cada push para `main` e em cada PR.

Não precisa dos ficheiros Firebase nativos: a análise e os testes só usam o código Dart. Os Secrets `GOOGLE_SERVICES_JSON` e `GOOGLE_SERVICE_INFO_PLIST` só serão necessários quando o CI passar a compilar a app (devem ser guardados em base64).

## Segurança e boas práticas

- Nunca comites ficheiros de configuração que contenham chaves ou segredos.
- Adiciona ficheiros sensíveis ao `.gitignore` (o ficheiro já contém entradas para isso).
- Para integrar Firebase em CI, usa `GitHub Secrets` para credenciais e scripts de implantação.
