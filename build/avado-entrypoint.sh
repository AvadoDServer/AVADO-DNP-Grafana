#!/bin/sh
# Sets a random admin password on first start instead of Grafana's admin/admin.
#
# - The password is generated once, stored in /var/lib/grafana/avado-admin-password
#   (the data volume) and printed to the log once.
# - If the user sets GF_SECURITY_ADMIN_PASSWORD in the package environment, that
#   password wins: it is applied on every start and the generated file is removed.
set -eu

PW_FILE=/var/lib/grafana/avado-admin-password
DB_FILE=/var/lib/grafana/grafana.db
GRAFANA_CLI="grafana cli --homepath ${GF_PATHS_HOME:-/usr/share/grafana} --config ${GF_PATHS_CONFIG:-/etc/grafana/grafana.ini}"

reset_admin_password() {
  # Only possible on an existing database (the admin user must exist).
  if $GRAFANA_CLI admin reset-admin-password "$1" >/tmp/avado-reset.log 2>&1; then
    echo "[avado] admin password updated"
  else
    echo "[avado] WARNING: could not update the admin password:" >&2
    cat /tmp/avado-reset.log >&2
  fi
}

if [ -n "${GF_SECURITY_ADMIN_PASSWORD:-}" ]; then
  echo "[avado] using the admin password from GF_SECURITY_ADMIN_PASSWORD"
  if [ -f "$DB_FILE" ]; then
    reset_admin_password "$GF_SECURITY_ADMIN_PASSWORD"
  fi
  # The generated password is no longer valid; remove it so it cannot mislead.
  # (If the variable is cleared later, a new password is generated and printed.)
  rm -f "$PW_FILE"
else
  if [ ! -s "$PW_FILE" ]; then
    NEW_PW=$(head -c 64 /dev/urandom | base64 | tr -dc 'A-Za-z0-9' | head -c 20)
    umask 077
    printf '%s\n' "$NEW_PW" >"$PW_FILE"
    echo "[avado] ============================================================"
    echo "[avado] Grafana admin login: admin / $NEW_PW"
    echo "[avado] (stored in $PW_FILE)"
    echo "[avado] ============================================================"
    if [ -f "$DB_FILE" ]; then
      # Upgrade from a package version that used admin/admin.
      reset_admin_password "$NEW_PW"
    fi
  fi
  GF_SECURITY_ADMIN_PASSWORD=$(cat "$PW_FILE")
  export GF_SECURITY_ADMIN_PASSWORD
fi

exec /run.sh "$@"
