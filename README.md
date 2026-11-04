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

Opções seguras:

- Mantém esses ficheiros fora do repo e partilha-os por um canal seguro.
- Usa `GitHub Secrets` para credenciais e variáveis de ambiente.
- Cria estes Secrets no GitHub Actions:
  - `GOOGLE_SERVICES_JSON`
  - `GOOGLE_SERVICE_INFO_PLIST`

## CI

O workflow `.github/workflows/ci.yml` corre `flutter analyze --fatal-infos` e `flutter test` em cada push para `main` e em cada PR.

Não precisa dos ficheiros Firebase nativos: a análise e os testes só usam o código Dart. Os Secrets `GOOGLE_SERVICES_JSON` e `GOOGLE_SERVICE_INFO_PLIST` só serão necessários quando o CI passar a compilar a app (devem ser guardados em base64).

## Segurança e boas práticas

- Nunca comites ficheiros de configuração que contenham chaves ou segredos.
- Adiciona ficheiros sensíveis ao `.gitignore` (o ficheiro já contém entradas para isso).
- Para integrar Firebase em CI, usa `GitHub Secrets` para credenciais e scripts de implantação.
