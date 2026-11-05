#!/usr/bin/env bash
# Publica a STRK web no Firebase Hosting.
#
#   APPCHECK_WEB_KEY=<chave do Fraud Defense> ./scripts/deploy_web.sh
#
# A chave do Fraud Defense não é um segredo (fica visível no browser), mas não
# está no repositório: cada deploy tem de a passar.
set -euo pipefail
cd "$(dirname "$0")/.."

if [[ -z "${APPCHECK_WEB_KEY:-}" ]]; then
  echo "Falta APPCHECK_WEB_KEY (chave do Fraud Defense, antigo reCAPTCHA Enterprise)." >&2
  exit 1
fi

echo "› A verificar o código…"
flutter analyze --fatal-infos
flutter test

echo "› A compilar a versão web…"
# --no-web-resources-cdn: o CanvasKit é servido pelo próprio site em vez do
# CDN da Google, por isso abrir a app não faz pedidos a terceiros.
flutter build web --release --no-web-resources-cdn \
  --dart-define=APPCHECK_WEB_KEY="$APPCHECK_WEB_KEY"

echo "› A publicar…"
firebase deploy --only hosting --project strk-thebestone
