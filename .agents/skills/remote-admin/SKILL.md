---
name: remote-admin
description: Ejecución remota de comandos, diagnósticos y gestión de contenedores Docker en servidores/VPS vía SSH de forma segura.
---

# Remote Admin (Universal VPS / SSH)

Habilidad estándar de `agent-os` para interactuar con servidores remotos (VPS, instancias cloud o nodos privados) para diagnósticos de salud, inspección de logs y gestión de contenedores Docker.

## Prerrequisitos
- Acceso SSH configurado en el entorno local (típicamente en `~/.ssh/config`).
- Claves privadas accesibles y con permisos correctos (`chmod 600`).

## Invocación Estándar

La habilidad opera directamente mediante el cliente `ssh`, utilizando los alias de host configurados en el sistema:

```bash
ssh <alias-servidor> "<comando>"
```

> **Recomendación de robustez**: Añadir `-o ConnectTimeout=5` en scripts o comandos automatizados para evitar bloqueos por problemas de red.

### Descubrimiento de Servidores (Optimizado en tokens)

Para listar los alias SSH disponibles en cualquier entorno sin tener que leer archivos extensos de configuración:

```bash
# Listado ultracompacto (alias, usuario, host/IP)
bash .agents/skills/remote-admin/scripts/list-hosts.sh

# Listado con verificación de conectividad activa
bash .agents/skills/remote-admin/scripts/list-hosts.sh --check
```

### Auditoría Remota Integral en 1 Llamada (Ahorro de tokens)

Para auditar un servidor remoto completo (salud, memoria, disco, contenedores y volúmenes Docker, clasificación de sockets expuestos y firewall) en **una única llamada SSH** evitando múltiples turnos de conversación:

```bash
bash .agents/skills/remote-admin/scripts/audit-host.sh <alias-servidor>
```

El script genera directamente una salida markdown estructurada con secciones parseadas, optimizando el consumo de contexto.

### Diagnóstico de Conectividad Git/GitHub SSH en 1 Llamada (Ahorro de tokens)

Para verificar si un host remoto tiene `github.com` en su `known_hosts`, inventario de claves SSH públicas en `~/.ssh/*.pub` (sin exponer privadas) y resultado del handshake contra `git@github.com`:

```bash
bash .agents/skills/remote-admin/scripts/check-git-remote.sh <alias-servidor>
```

## Operaciones Comunes

### 1. Diagnóstico de Salud y Recursos
```bash
# Carga de CPU, memoria RAM y espacio en disco
ssh <alias> "uptime; free -m; df -h /"
```

### 2. Gestión de Contenedores Docker
```bash
# Listar contenedores activos y puertos mapeados
ssh <alias> "docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'"

# Inspeccionar logs recientes (sin streaming bloqueante)
ssh <alias> "docker logs --tail 50 <nombre-contenedor>"

# Ver uso de recursos en tiempo real (snapshot sin bloqueo)
ssh <alias> "docker stats --no-stream"
```

### 3. Inspección de Archivos y Servicios
```bash
# Ver estado de un servicio systemd
ssh <alias> "systemctl --user status <servicio> --no-pager"

# Verificar puertos en escucha
ssh <alias> "ss -tlnp"
```

## Protocolo de Seguridad Obligatorio

1. **Sólo Lectura por Defecto**: Priorizar siempre comandos no destructivos (`cat`, `grep`, `docker ps`, `docker logs`, `uptime`, `free`, `df`).
2. **Confirmación Previa para Modificaciones**: NUNCA ejecutar comandos destructivos o que alteren el estado del servidor (`docker stop`, `docker rm`, `docker compose down`, `prune`, `reboot`, `rm -rf`) sin confirmación explícita del usuario.
3. **Comandos Interactivos Prohibidos**: No ejecutar herramientas interactivas (`htop`, `nano`, `vim`, `docker logs -f` indefinido). Usar snapshots (`top -b -n 1`, `docker logs --tail N`).
4. **Aislamiento de Red**: En servidores accesibles vía Tailscale o VPN privada, evitar exponer puertos administrativos a la interfaz pública (`0.0.0.0`).
