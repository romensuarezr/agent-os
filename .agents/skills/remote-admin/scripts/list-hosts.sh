#!/usr/bin/env bash
# list-hosts.sh — Descubrimiento ultracompacto de hosts SSH para remote-admin
# Uso: bash .agents/skills/remote-admin/scripts/list-hosts.sh [--check]

set -euo pipefail

# Buscar archivo de configuración SSH
SSH_CONFIG=""
CANDIDATES=(
  "${HOME}/.ssh/config"
  "/home/${USER:-$(whoami)}/.ssh/config"
  "/home/romen/.ssh/config"
)

for c in "${CANDIDATES[@]}"; do
  if [ -f "$c" ]; then
    SSH_CONFIG="$c"
    break
  fi
done

if [ -z "$SSH_CONFIG" ]; then
  echo "⚠️ No se encontró archivo .ssh/config en el entorno."
  exit 0
fi

CHECK_STATUS=false
if [ "${1:-}" = "--check" ]; then
  CHECK_STATUS=true
fi

# Extraer hosts no-git y no-wildcards
parse_hosts() {
  awk '
  BEGIN { IGNORECASE=1 }
  /^Host [^*?]/ {
    if (host != "" && host !~ /^(github|gitlab|bitbucket)/) {
      print host "|" (user ? user : "default") "|" (hostname ? hostname : "-")
    }
    host = $2; hostname = ""; user = ""
  }
  /^[[:space:]]+HostName[[:space:]]+/ { hostname = $2 }
  /^[[:space:]]+User[[:space:]]+/ { user = $2 }
  END {
    if (host != "" && host !~ /^(github|gitlab|bitbucket)/) {
      print host "|" (user ? user : "default") "|" (hostname ? hostname : "-")
    }
  }' "$SSH_CONFIG"
}

if [ "$CHECK_STATUS" = true ]; then
  printf "%-18s %-10s %-18s %s\n" "ALIAS" "USER" "HOST/IP" "STATUS"
  printf "%-18s %-10s %-18s %s\n" "-----" "----" "-------" "------"
  while IFS="|" read -r host user hostname; do
    [ -z "$host" ] && continue
    if ssh -n -o BatchMode=yes -o ConnectTimeout=2 -o StrictHostKeyChecking=no "$host" exit 2>/dev/null; then
      status="ONLINE ✅"
    else
      status="OFFLINE ❌"
    fi
    printf "%-18s %-10s %-18s %s\n" "$host" "$user" "$hostname" "$status"
  done < <(parse_hosts)
else
  printf "%-18s %-10s %s\n" "ALIAS" "USER" "HOST/IP"
  printf "%-18s %-10s %s\n" "-----" "----" "-------"
  while IFS="|" read -r host user hostname; do
    [ -z "$host" ] && continue
    printf "%-18s %-10s %s\n" "$host" "$user" "$hostname"
  done < <(parse_hosts)
fi
