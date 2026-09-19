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

### Servidores conocidos en el ecosistema

| Alias | Red / Tipo | Usuario | Uso principal |
|---|---|---|---|
| `datamanager` | Tailscale (`100.77.82.13`) | `ubuntu` | Inferencia LLM, Ollama, Qdrant, FreeLLMAPI |
| `oracle` | Pública (`158.179.213.240`) | `ubuntu` | Producción bots (Polybot, etc.) |
| `bot3-clouding` | Pública (`187.33.146.24`) | `romen` | Servicios Clouding |

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
