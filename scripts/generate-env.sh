#!/usr/bin/env bash
#
# Erzeugt .env mit zufaelligen Geheimnissen fuer docker-compose.yml.
#
# Der Grund, warum es dieses Skript gibt: config/passwords.yaml steht zu
# Recht nicht im Repository, ein frischer Clone hat also keine. Statt zu
# verlangen, dass man sich selbst welche ausdenkt, werden sie hier erzeugt.

set -euo pipefail

cd "$(dirname "$0")/.."

if [ -e .env ]; then
  echo ".env existiert bereits — es wird nichts ueberschrieben." >&2
  echo "Zum Neuerzeugen erst loeschen. Achtung: bestehende Sitzungen und" >&2
  echo "die Datenbankverbindung haengen an den alten Werten." >&2
  exit 1
fi

# 32 Zeichen aus [A-Za-z0-9]. Bewusst ohne Sonderzeichen: die Werte landen
# in einer .env, in YAML und in einer Redis-Kommandozeile, und jede dieser
# Ebenen hat eigene Vorstellungen davon, was zitiert werden muss.
rand() {
  LC_ALL=C tr -dc 'A-Za-z0-9' < /dev/urandom | head -c 32
}

umask 077
cat > .env <<EOF
# Erzeugt von scripts/generate-env.sh — enthaelt Geheimnisse, gehoert
# nicht ins Repository (steht in .gitignore).

# Adresse, unter der die App diesen Server erreicht. Bei Betrieb hinter
# einem Reverse Proxy mit TLS: PREPPSUITE_SCHEME=https und
# PREPPSUITE_PUBLIC_PORT=443 setzen.
PREPPSUITE_HOST=localhost
PREPPSUITE_SCHEME=http
PREPPSUITE_PORT=8080
PREPPSUITE_PUBLIC_PORT=8080

POSTGRES_PASSWORD=$(rand)
REDIS_PASSWORD=$(rand)

SERVERPOD_SERVICE_SECRET=$(rand)
EMAIL_SECRET_HASH_PEPPER=$(rand)
JWT_PRIVATE_KEY=$(rand)
JWT_REFRESH_PEPPER=$(rand)

# Optional: Firebase-Dienstkontoschluessel als einzeiliges JSON, fuer
# Push-Benachrichtigungen. Leer heisst Push aus. Siehe
# docs/push-notifications.md.
FIREBASE_SERVICE_ACCOUNT=
EOF

chmod 600 .env
echo ".env erzeugt. Weiter mit:  docker compose up -d"
