#!/usr/bin/env bash
# check-git-remote.sh — Diagnóstico de autenticación Git/GitHub SSH en host remoto en 1 sola llamada
# Uso: bash .agents/skills/remote-admin/scripts/check-git-remote.sh <alias-ssh>
#
# Propósito: Inspeccionar de forma 100% segura y no destructiva:
# 1. Presencia de github.com en ~/.ssh/known_hosts
# 2. Inventario de claves SSH públicas en ~/.ssh/*.pub (huellas y comentarios, CERO claves privadas)
# 3. Configuraciones para github.com en ~/.ssh/config
# 4. Resultado del handshake de prueba hacia git@github.com
# 5. Configuración global de git (user.name, user.email)

set -euo pipefail

TARGET_HOST="${1:-}"

if [ -z "$TARGET_HOST" ]; then
  echo "❌ Error: Debes especificar un alias o host SSH."
  echo "Uso: bash .agents/skills/remote-admin/scripts/check-git-remote.sh <alias-ssh>"
  echo "Ejemplo: bash .agents/skills/remote-admin/scripts/check-git-remote.sh datamanager"
  exit 1
fi

SSH_OPTS=(-o BatchMode=yes -o ConnectTimeout=5 -o StrictHostKeyChecking=accept-new)

REMOTE_SCRIPT=$(cat << 'EOF'
set -u

echo "=== SECTION: HOST_USER ==="
echo "USER: $(whoami 2>/dev/null || id -un)"
echo "HOME: $HOME"

echo "=== SECTION: KNOWN_HOSTS ==="
if [ -f "$HOME/.ssh/known_hosts" ]; then
  echo "KNOWN_HOSTS_FILE: Exists ($HOME/.ssh/known_hosts)"
  if ssh-keygen -F github.com -f "$HOME/.ssh/known_hosts" >/dev/null 2>&1; then
    echo "GITHUB_KNOWN: true"
    ssh-keygen -F github.com -f "$HOME/.ssh/known_hosts" 2>/dev/null | head -5
  else
    echo "GITHUB_KNOWN: false (github.com no está registrado en known_hosts)"
  fi
else
  echo "KNOWN_HOSTS_FILE: Not found"
  echo "GITHUB_KNOWN: false"
fi

echo "=== SECTION: PUBLIC_KEYS ==="
found_keys=0
for pub in "$HOME"/.ssh/*.pub; do
  if [ -f "$pub" ]; then
    found_keys=1
    fname=$(basename "$pub")
    fprint=$(ssh-keygen -lf "$pub" 2>/dev/null || echo "No se pudo leer huella")
    echo "KEY: $fname | $fprint"
  fi
done
[ $found_keys -eq 0 ] && echo "No se encontraron claves públicas (.pub) en ~/.ssh/"

echo "=== SECTION: SSH_CONFIG ==="
if [ -f "$HOME/.ssh/config" ]; then
  echo "SSH_CONFIG: Exists"
  grep -A 4 -i "Host .*github" "$HOME/.ssh/config" 2>/dev/null || echo "Sin bloque específico para github en ~/.ssh/config"
else
  echo "SSH_CONFIG: Not found"
fi

echo "=== SECTION: GITHUB_HANDSHAKE ==="
# Intentar handshake sin interacción
# Código 1 es normal en GitHub ("Hi user! You've successfully authenticated, but GitHub does not provide shell access.")
HANDSHAKE=$(ssh -o BatchMode=yes -o ConnectTimeout=5 -T git@github.com 2>&1 || true)
echo "$HANDSHAKE"

echo "=== SECTION: GIT_CONFIG ==="
echo "GIT_USER_NAME: $(git config --global user.name 2>/dev/null || echo 'No configurado')"
echo "GIT_USER_EMAIL: $(git config --global user.email 2>/dev/null || echo 'No configurado')"

echo "=== END AUDIT ==="
EOF
)

RAW_OUTPUT=$(ssh "${SSH_OPTS[@]}" "$TARGET_HOST" "bash -s" <<< "$REMOTE_SCRIPT" 2>/dev/null) || {
  echo "❌ Error: Falló la conexión SSH con el host '$TARGET_HOST'."
  exit 1
}

parse_section() {
  local section_name="$1"
  echo "$RAW_OUTPUT" | awk -v s="=== SECTION: $section_name ===" '
    $0 ~ s { found=1; next }
    /^=== (SECTION:|END AUDIT)/ { if (found) exit }
    found { print }
  '
}

TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

cat << EOF
# 🔑 Diagnóstico GitHub SSH en Host: \`$TARGET_HOST\`
> Generado por \`remote-admin:check-git-remote.sh\` el $TIMESTAMP

## 1. Identidad en el Host
\`\`\`text
$(parse_section "HOST_USER")
\`\`\`

## 2. Registro de \`known_hosts\` para GitHub
\`\`\`text
$(parse_section "KNOWN_HOSTS")
\`\`\`

## 3. Claves Públicas Detectadas (\`~/.ssh/*.pub\`)
\`\`\`text
$(parse_section "PUBLIC_KEYS")
\`\`\`

## 4. Configuración SSH (\`~/.ssh/config\`)
\`\`\`text
$(parse_section "SSH_CONFIG")
\`\`\`

## 5. Prueba de Handshake (\`ssh -T git@github.com\`)
\`\`\`text
$(parse_section "GITHUB_HANDSHAKE")
\`\`\`

## 6. Configuración Git Global
\`\`\`text
$(parse_section "GIT_CONFIG")
\`\`\`
EOF
