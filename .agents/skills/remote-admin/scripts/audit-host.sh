#!/usr/bin/env bash
# audit-host.sh — Diagnóstico y auditoría remota no destructiva en 1 sola llamada SSH
# Uso: bash .agents/skills/remote-admin/scripts/audit-host.sh <alias-ssh>
#
# Propósito: Extraer salud del host, uso de disco, métricas de Docker, puertos clasificados
# y estado del firewall en una única llamada SSH para minimizar latencia y consumo de tokens.

set -euo pipefail

TARGET_HOST="${1:-}"

if [ -z "$TARGET_HOST" ]; then
  echo "❌ Error: Debes especificar un alias o host SSH."
  echo "Uso: bash .agents/skills/remote-admin/scripts/audit-host.sh <alias-ssh>"
  echo "Ejemplo: bash .agents/skills/remote-admin/scripts/audit-host.sh oracle"
  exit 1
fi

SSH_OPTS=(-o BatchMode=yes -o ConnectTimeout=5 -o StrictHostKeyChecking=accept-new)

# Payload remoto ejecutado en el host en una única invocación
REMOTE_SCRIPT=$(cat << 'EOF'
set -u

echo "=== SECTION: HOST_INFO ==="
echo "HOSTNAME: $(hostname 2>/dev/null || uname -n)"
echo "KERNEL: $(uname -srm 2>/dev/null)"
if [ -f /etc/os-release ]; then
  . /etc/os-release
  echo "OS: ${PRETTY_NAME:-$NAME}"
else
  echo "OS: Desconocido"
fi
echo "UPTIME: $(uptime 2>/dev/null)"

echo "=== SECTION: MEMORY ==="
free -h 2>/dev/null || free -m 2>/dev/null

echo "=== SECTION: DISK_SUMMARY ==="
df -h -x tmpfs -x devtmpfs -x squashfs 2>/dev/null || df -h

echo "=== SECTION: DOCKER_SUMMARY ==="
if command -v docker >/dev/null 2>&1; then
  if docker info >/dev/null 2>&1; then
    echo "DOCKER_AVAILABLE: true"
    echo ""
    echo "--- DOCKER_SYSTEM_DF ---"
    docker system df 2>/dev/null || true
    echo ""
    echo "--- TOP 10 DOCKER IMAGES BY SIZE ---"
    docker images --format "table {{.Repository}}:{{.Tag}}\t{{.Size}}\t{{.CreatedSince}}" 2>/dev/null | head -11 || true
    echo ""
    echo "--- DOCKER CONTAINERS (RUNNING & EXITED) ---"
    docker ps -a --format "table {{.Names}}\t{{.Status}}\t{{.Size}}" 2>/dev/null | head -35 || true
    echo ""
    echo "--- DOCKER VOLUMES COUNT ---"
    echo "VOLUMES_TOTAL: $(docker volume ls -q 2>/dev/null | wc -l)"
    echo "VOLUMES_DANGLING: $(docker volume ls -qf dangling=true 2>/dev/null | wc -l)"
    echo ""
    echo "--- COOLIFY DATA DIR SIZES ---"
    if [ -d /data/coolify ]; then
      du -sh /data/coolify/* 2>/dev/null | sort -h || du -sh /data/coolify 2>/dev/null || true
    else
      echo "/data/coolify no existe o no es accesible"
    fi
    echo ""
    echo "--- DOCKER CONTAINER LOGS (TOP 10 BY SIZE) ---"
    if [ -d /var/lib/docker/containers ]; then
      find /var/lib/docker/containers -name "*-json.log" -type f -exec ls -lh {} + 2>/dev/null | sort -k5 -rh | head -10 | awk '{print $5, $9}' || echo "Requiere elevación sudo para /var/lib/docker/containers"
    else
      echo "/var/lib/docker/containers no encontrado"
    fi
  else
    echo "DOCKER_AVAILABLE: false (daemon no accesible sin sudo o no iniciado)"
  fi
else
  echo "DOCKER_AVAILABLE: false (docker no instalado)"
fi

echo "=== SECTION: LISTENING_PORTS ==="
if command -v ss >/dev/null 2>&1; then
  ss -tulpn 2>/dev/null || ss -tuln 2>/dev/null
elif command -v netstat >/dev/null 2>&1; then
  netstat -tulpn 2>/dev/null || netstat -tuln 2>/dev/null
else
  echo "Ni ss ni netstat están disponibles"
fi

echo "=== SECTION: FIREWALL ==="
if command -v ufw >/dev/null 2>&1; then
  UFW_OUT=$(sudo -n ufw status 2>/dev/null || ufw status 2>/dev/null || echo "UFW instalado pero requiere sudo interactivo")
  echo "$UFW_OUT"
elif command -v iptables >/dev/null 2>&1; then
  echo "UFW no instalado. Verificando iptables..."
  sudo -n iptables -S 2>/dev/null | head -10 || echo "iptables presente (requiere sudo para listar)"
else
  echo "Sin herramienta de firewall estándar detectada"
fi

echo "=== SECTION: TAILSCALE ==="
if command -v tailscale >/dev/null 2>&1; then
  echo "TAILSCALE_IPV4: $(tailscale ip -4 2>/dev/null || echo 'Tailscale no responde')"
  echo "TAILSCALE_STATUS: $(tailscale status 2>/dev/null | head -5 || echo 'Sin status')"
else
  echo "Tailscale CLI no encontrado"
fi

echo "=== END AUDIT ==="
EOF
)

# Ejecución remota capturada en variable (sin -n para permitir stdin heredoc)
RAW_OUTPUT=$(ssh "${SSH_OPTS[@]}" "$TARGET_HOST" "bash -s" <<< "$REMOTE_SCRIPT" 2>/dev/null) || {
  echo "❌ Error: Falló la conexión SSH con el host '$TARGET_HOST'."
  echo "Verifica que el alias esté en ~/.ssh/config y que la conectividad esté activa."
  exit 1
}

# Procesar secciones de salida
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
# 🛡️ Auditoría Remota de Host: \`$TARGET_HOST\`
> Generado automáticamente por \`remote-admin:audit-host.sh\` el $TIMESTAMP

## 1. Información del Sistema
\`\`\`text
$(parse_section "HOST_INFO")
\`\`\`

## 2. Memoria y Swap
\`\`\`text
$(parse_section "MEMORY")
\`\`\`

## 3. Almacenamiento y Particiones
\`\`\`text
$(parse_section "DISK_SUMMARY")
\`\`\`

## 4. Estado de Docker
\`\`\`text
$(parse_section "DOCKER_SUMMARY")
\`\`\`

## 5. Puertos y Sockets en Escucha
\`\`\`text
$(parse_section "LISTENING_PORTS")
\`\`\`

## 6. Seguridad de Red (Firewall & Tailscale)
\`\`\`text
$(parse_section "FIREWALL")
$(parse_section "TAILSCALE")
\`\`\`
EOF
