# Strk (habit_tracker)

Aplicação Flutter para acompanhar hábitos.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:


For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

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

## Criar repositório (exemplo seguro)

```bash
# Inicializar repo local
cd habit_tracker
git init
git add .
git commit -m "chore: initial project files"

# Criar repo remoto (GitHub CLI) — substitui os valores
gh repo create your-username/habit_tracker --private --source=. --remote=origin

# Push
git push -u origin main
```

Se preferires UI do GitHub, cria o repo lá e adiciona o `remote` manualmente:

```bash
git remote add origin git@github.com:your-username/habit_tracker.git
git push -u origin main
```

## CI

Um workflow de exemplo está incluído em `.github/workflows/ci.yml` — corre `flutter analyze` e `flutter test` em pushes/PRs.

## Segurança e boas práticas

- Nunca comites ficheiros de configuração que contenham chaves ou segredos.
- Adiciona ficheiros sensíveis ao `.gitignore` (o ficheiro já contém entradas para isso).
- Para integrar Firebase em CI, usa `GitHub Secrets` para credenciais e scripts de implantação.

Se quiseres, posso inicializar o repo localmente e criar o repo remoto com `gh` (peço confirmação antes de executar comandos que alterem o teu ambiente).
