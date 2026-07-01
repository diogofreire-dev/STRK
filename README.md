# Strk (habit_tracker)

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

Um workflow de exemplo está incluído em `.github/workflows/ci.yml` — corre `flutter analyze` e `flutter test` em pushes/PRs.

O workflow agora reconstrói os ficheiros Firebase a partir dos Secrets antes do build.

## Segurança e boas práticas

- Nunca comites ficheiros de configuração que contenham chaves ou segredos.
- Adiciona ficheiros sensíveis ao `.gitignore` (o ficheiro já contém entradas para isso).
- Para integrar Firebase em CI, usa `GitHub Secrets` para credenciais e scripts de implantação.
