# Hermes VPS Runbook

Entorno validado para operar Hermes Desktop y Hermes Agent headless en nodos VPS a través de la malla privada de Tailscale, integrando pasarelas de inferencia de coste cero ($0) —OmniRoute y FreeLLMAPI—, aislamiento de modelos `:free` y persistencia con `systemd --user`.

> [!IMPORTANT]
> **Frontera portable de configuración**: Este runbook versionado utiliza exclusivamente el placeholder `<TAILSCALE_IP>`. La correspondencia `<TAILSCALE_IP>` → IP real se define en el archivo gitignored `.agents/config/fleet.yaml` (sección `nodes`) o en el entorno local del operador. Ninguna IP literal de Tailscale debe confirmarse en el repositorio core.

---

## 1. Arquitectura y Topología de Red

La arquitectura desacopla interfaz, mensajería y pasarelas de inferencia en la red privada de Tailscale:

```
[Cliente / Desktop / SSH]
           │
           ▼ (Tailscale Mesh)
┌─────────────────────────────────────────────────────────────┐
│  Nodo VPS (<nodo-inferencia> / <nodo-orquestacion>)                            │
│                                                             │
│  • Hermes Dashboard:   http://<TAILSCALE_IP>:9119           │
│  • Hermes Gateway:     systemd --user (Telegram/WhatsApp)   │
│                                                             │
│  Pasarelas de inferencia gratuita ($0):                     │
│  ├── OmniRoute:        http://<TAILSCALE_IP>:20128/v1       │
│  │   └─ Modelo: auto/best-coding (multi-provider unificado) │
│  ├── FreeLLMAPI:       http://<TAILSCALE_IP>:3001/v1        │
│  │   └─ UI Dashboard + enrutador libre                      │
│  ├── OpenRouter Free:  https://openrouter.ai/api/v1         │
│  │   └─ Whitelist estricta: sufijo :free únicamente         │
│  └── Ollama Local:     http://127.0.0.1:11434/v1 (in-host)  │
└─────────────────────────────────────────────────────────────┘
```

### Componentes y Puertos

| Servicio | Host / Bind | Puerto | Descripción |
|---|---|---|---|
| **Hermes Dashboard** | `<TAILSCALE_IP>` | `9119` | Panel web y API de administración con autenticación de sesión. |
| **Hermes Gateway** | `0.0.0.0` / Local | — | Servicio daemon de fondo que conecta bridges de Telegram / WhatsApp. |
| **OmniRoute** | `<TAILSCALE_IP>` | `20128` | Proxy agregador de modelos gratuitos ($0) con auth Bearer. |
| **FreeLLMAPI** | `<TAILSCALE_IP>` | `3001` | Pasarela y dashboard de modelos rotativos gratuitos. |
| **Ollama Local** | `127.0.0.1` | `11434` | Motor local de respaldo in-host (ej. `llama3.1:8b`, `qwen2.5:7b`). |

---

## 2. Configuración Validada (~/.hermes/config.yaml)

Configuración recomendada para operar con inferencia resiliente de coste cero:

```yaml
model:
  default: auto/best-coding
  provider: custom:omniroute
  base_url: http://<TAILSCALE_IP>:20128/v1
  api_key: "${OMNIROUTE_API_KEY}"

custom_providers:
  - name: omniroute
    base_url: http://<TAILSCALE_IP>:20128/v1
    api_key: "${OMNIROUTE_API_KEY}"
    model: auto/best-coding
  - name: freellmapi
    base_url: http://<TAILSCALE_IP>:3001/v1
    api_key: freeapi
    model: auto
  - name: openrouter-free
    base_url: https://openrouter.ai/api/v1
    api_key: "${OPENROUTER_API_KEY}"
    model: meta-llama/llama-3.3-70b-instruct:free
```

> [!WARNING]
> **Aislamiento OpenRouter Free-Only**: Si se utiliza OpenRouter como proveedor alternativo, el modelo debe contener obligatoriamente el sufijo `:free` (ej. `meta-llama/llama-3.3-70b-instruct:free`). Invocar modelos comerciales sin sufijo consumirá saldo de prepago y provocará errores `HTTP 403 / 402` cuando el crédito se agote.

---

## 3. Manejo Seguro de Secretos con Infisical

Queda terminantemente prohibido almacenar contraseñas o tokens de API en ficheros `.env` rastreados o parámetros CLI en texto plano.

### Autenticación Universal Auth en Memoria

```bash
# Canje de token efímero mediante Machine Identity (sin prompts interactivos)
export INFISICAL_TOKEN=$(infisical login \
  --domain="${INFISICAL_API_URL}" \
  --method=universal-auth \
  --client-id="${INFISICAL_CLIENT_ID}" \
  --client-secret="${INFISICAL_CLIENT_SECRET}" \
  --plain)

# Inyección efímera en subshell para tareas de validación
eval $(infisical export --token="${INFISICAL_TOKEN}" --domain="${INFISICAL_API_URL}" --projectId="${INFISICAL_PROJECT_ID}" --env=prod --format=dotenv-export)
```

---

## 4. Gestión de Servicios (systemd --user)

En nodos donde Hermes opera como demonio (ej. `<nodo-inferencia>`):

```bash
# Ver estado de los servicios
systemctl --user status hermes-dashboard --no-pager
systemctl --user status hermes-gateway --no-pager

# Reiniciar Dashboard tras cambios de interfaz o red
systemctl --user restart hermes-dashboard

# Reiniciar Gateway tras cambios en ~/.hermes/config.yaml
# NOTA: Provoca una desconexión transitoria de ~3 segundos en mensajería.
# Para cambios exclusivos en habilidades o symlinks, NO reinicies el gateway: utiliza /reload-skills.
systemctl --user restart hermes-gateway

# Consultar logs en tiempo real
journalctl --user -u hermes-gateway -n 50 -f
journalctl --user -u hermes-dashboard -n 50 -f
```

### Protocolo de Actualización Segura de Hermes en VPS (Upstream v0.23+)

Ante la disponibilidad de nuevas versiones upstream (auditadas mediante `check-tooling-updates.sh`), seguir estrictamente este flujo de 5 pasos para no comprometer servicios ni parches locales:

1. **Inspección de parches locales**:
   ```bash
   # Comprobar si existen commits locales (carried commits) en el repo clonado
   git -C ~/.hermes/hermes-agent status
   git -C ~/.hermes/hermes-agent log -n 3 --oneline
   ```
2. **Respaldo preventivo de configuración**:
   ```bash
   cp ~/.hermes/config.yaml ~/.hermes/config.yaml.bak.$(date +%Y%m%d_%H%M%S)
   ```
3. **Actualización del binario / virtualenv**:
   ```bash
   # Si no hay parches locales:
   PATH=$HOME/.local/bin:$HOME/.hermes/hermes-agent/venv/bin:$PATH hermes update

   # Si existen carried commits, preferir pull con rebase:
   git -C ~/.hermes/hermes-agent pull --rebase origin main
   ~/.hermes/hermes-agent/venv/bin/pip install -e ~/.hermes/hermes-agent
   ```
4. **Reinicio coordinado de servicios**:
   ```bash
   systemctl --user restart hermes-gateway hermes-dashboard
   ```
5. **Verificación funcional de inferencia**:
   ```bash
   PATH=$HOME/.local/bin:$HOME/.hermes/hermes-agent/venv/bin:$PATH hermes -z "ping" --yolo
   # Verificación esperada: respuesta "pong" con código de salida 0.
   ```

---

## 5. Recarga en Caliente de Habilidades y Slash Commands (/reload-skills)

Hermes Agent incluye soporte para recarga en caliente de herramientas y comandos de barra diagonal (`/`) sin reiniciar el proceso del gateway ni provocar micro-desconexiones en los bridges de mensajería (WhatsApp / Telegram).

### Mecánica de Detección y Recarga

1. **Modificaciones de archivos existentes**: Hermes detecta cambios en el sistema de archivos (`SKILL.md` o scripts ya enlazados) automáticamente en el siguiente turno de conversación.
2. **Nuevas habilidades o symlinks añadidos**: Cuando se incorpora una nueva habilidad al directorio `~/.hermes/skills/` (ej. vía symlink), el registro de herramientas en memoria debe actualizarse invocando el comando de pasarela:
   ```text
   /reload-skills
   ```
   (o su alias canónico `/reload_skills`).

### Canales de Invocación

- **Desde WhatsApp o Telegram**: Envía `/reload-skills` en el chat directo con Hermes. El gateway responderá confirmando las herramientas recargadas.
- **Desde la CLI de Hermes**:
  ```bash
  PATH=$HOME/.local/bin:$HOME/.hermes/hermes-agent/venv/bin:$PATH hermes -z "/reload-skills" --yolo
  ```

---

## 6. Sincronización Automática del Core y Cronjobs a $0 Tokens

Para mantener el repositorio del Core de Agent OS y sus habilidades sincronizadas en `<nodo-inferencia>` sin intervención humana ni coste de tokens LLM, se utiliza el patrón de watchdogs nativos de Hermes (`no_agent: true`).

### Arquitectura de Sincronización Determinista

```
┌────────────────────────────────────────────────────────┐
│  Cronjob Nativo de Hermes (0 6,18 * * *)               │
│  "no_agent": true — Omite llamada al LLM ($0 tokens)  │
└──────────────────────────┬─────────────────────────────┘
                           │
                           ▼
┌────────────────────────────────────────────────────────┐
│  ~/.hermes/scripts/sync_agent_os_core.sh               │
│  1. git fetch & git pull --ff-only origin multi-agent  │
│  2. Sincroniza symlinks en ~/.hermes/skills/agent-os/  │
│  3. Aplica permisos de ejecución (+x) a scripts        │
│  4. Registra estado en last_core_update.json           │
└──────────────────────────┬─────────────────────────────┘
                           │
            ┌──────────────┴──────────────┐
            ▼                             ▼
   [Sin cambios detectados]      [Novedades / Nueva versión]
   • Salida vacía                • Emite reporte estructurado
   • Hermes: Modo Silencioso     • Hermes entrega alerta directa
     (0 mensajes en WhatsApp)      por WhatsApp al operador
```

### Ejecución Manual y Diagnóstico

```bash
# Sincronización interactiva con salida verbose
bash ${HOME}/scripts/sync_agent_os_core.sh --verbose

# Consultar estado de la última sincronización
cat ${HOME}/.hermes/runtime/last_core_update.json

# Verificar tareas programadas en Hermes
PATH=$HOME/.local/bin:$HOME/.hermes/hermes-agent/venv/bin:$PATH hermes cron list
```

### Telemetría Matutina de Flota en WhatsApp (08:30 AM)

El briefing diario (`~/.hermes/scripts/fleet_morning_briefing.py`) se ejecuta cada mañana a las 08:30 AM bajo el mismo régimen determinista (`no_agent: true`). Lee de forma autónoma `last_core_update.json` y consolida:
- Versión actual del Core y conteo de habilidades activas.
- Indicador visual si el Core fue actualizado en las últimas 24 horas (`🚀 actualizado hoy`).
- Telemetría de memoria, disco y contenedores activos.

---

## 7. Contrato Operativo de Conserjería (AGENTS.md) y Gobernanza

En consonancia con la arquitectura de Nous Research, las directivas de Hermes se dividen estrictamente en dos capas:

1. **`~/.hermes/SOUL.md` (Identidad y Tono)**: Define la personalidad del modelo (comunicación directa, concisa, sin adulaciones ni sycophancy, profundidad ganada).
2. **`${HOME}/AGENTS.md` (Instrucciones de Trabajo y Matriz de Enrutamiento)**: Se ubica en la raíz de ejecución de Hermes (`TERMINAL_CWD`) y se inyecta automáticamente en el contexto operativo de cada turno.

### Matriz de Enrutamiento del Conserje

| Tipo de Tarea | Destino Operativo | Protocolo |
|---|---|---|
| **Código / Tareas de Sprint / Bugs** | Coordinador Antigravity VPS | `hermes-concierge` (`concierge_bridge.py`) hacia `${HOME}/projects/` |
| **Infraestructura / Satélites Coolify** | Admin de Ops / Docker | `coolify-admin` (`coolify.sh`) y `remote-admin` |
| **Monitoreo y Salud de Flota** | Scripts Locales Deterministas | `fleet_morning_briefing.py` / `fleet_exception_watcher.py` |
| **Mantenimiento del Core** | Script Determinista | `sync_agent_os_core.sh` y `/reload-skills` |

### Protocolo de Despacho de Código a Antigravity

Hermes nunca edita código de aplicaciones de satélites directamente. Ante una solicitud de desarrollo, despacha la orden a través del puente de conserjería:

```bash
python3 ~/.hermes/skills/hermes-concierge/scripts/concierge_bridge.py \
  --prompt "<Instrucción exacta del operador>" \
  --repo "${HOME}/projects/<proyecto-destino>" \
  --notify-whatsapp "<USER_PHONE>@lid"
```

El puente conmuta automáticamente entre perfiles Google Pro (`agy` → `agy2`) en caso de saturación de cuota y entrega el resultado directamente por WhatsApp.

---

## 8. Detección y Limpieza de Procesos Huérfanos

Sesiones interactivas desatendidas (ej. `hermes --tui --yolo`) lanzadas en terminales desconectados (`pts/X`) pueden permanecer activas indefinidamente consumiendo memoria y CPU.

### Inspección Dinámica Viva

```bash
# Inspeccionar procesos activos de Hermes y gateways asociados
ps -eo pid,user,tty,etime,args | grep -E 'hermes|tui_gateway' | grep -v grep
```

### Protocolo de Terminación Segura

1. Identificar PIDs correspondientes a sesiones huérfanas en TTYs cerrados o con tiempo de ejecución acumulado anormal.
2. Enviar señal de terminación limpia:
   ```bash
   kill -15 <PID_1> <PID_2> ...
   ```
3. Si los subprocesos de Node.js o TUI Gateway no responden al SIGTERM:
   ```bash
   kill -9 <PID_1> <PID_2> ...
   ```
4. Verificar que no queden procesos residuales:
   ```bash
   ps -eo pid,user,args | grep -E 'hermes|tui_gateway' | grep -v grep
   ```

---

## 9. Verificación Operativa y Health Checks

### Comprobación de Listener de Red (9119)

```bash
ss -tlnp | grep 9119
# Esperado: LISTEN en <TAILSCALE_IP>:9119 asociado al proceso hermes
```

### Validación del Dashboard

```bash
curl -I http://<TAILSCALE_IP>:9119/
# Esperado: HTTP/1.1 302 Found (redirección a /login?next=%2F)
```

### Verificación de Pasarelas de Inferencia ($0)

```bash
# OmniRoute
curl -s -H "Authorization: Bearer ${OMNIROUTE_API_KEY}" http://<TAILSCALE_IP>:20128/v1/models | grep -o "auto/best-coding"

# FreeLLMAPI
curl -s http://<TAILSCALE_IP>:3001/health
```

### Test Funcional de Turno no Interactivo

```bash
# Ejecutar un turno rápido validando respuesta sin consumir tokens de pago
PATH=$HOME/.local/bin:$HOME/.hermes/hermes-agent/venv/bin:$PATH hermes -z "ping" --yolo
# Esperado: pong (código de salida 0)
```

---

## 10. Troubleshooting

| Síntoma | Causa probable | Acción correctiva |
|---|---|---|
| `connection refused` en `127.0.0.1:9119` | Bind exclusivo a la interfaz Tailscale. | Conectar directamente a `http://<TAILSCALE_IP>:9119`. |
| `HTTP 302 Found` al consultar `9119` | Comportamiento normal con autenticación web habilitada. | Abrir en navegador y completar login de sesión. |
| `HTTP 403 / 402` en consultas LLM | Modelo comercial invocado sin saldo en OpenRouter. | Restringir el modelo al sufijo `:free` o conmutar a `custom:omniroute`. |
| `HTTP 401 Invalid API Key` en inferencia | Proveedor conmutado a pasarela sin autenticar (ej. FreeLLMAPI). | Revertir bloque `model` a `custom:omniroute` y reiniciar `hermes-gateway`. Ver [Nota de Incidente](incident-hermes-401-remediation.md). |
| `hermes: command not found` vía SSH no login | `~/.local/bin` o el virtualenv no están en el `PATH` no interactivo. | Invocar con `PATH=$HOME/.local/bin:$HOME/.hermes/hermes-agent/venv/bin:$PATH hermes`. |
| Subdominio `trycloudflare.com` caído | Túnel efímero expirado. | Migrar la `base_url` a `http://<TAILSCALE_IP>:20128/v1` en Tailscale. |
| Cron jobs en estado "config drifted" | `hermes-gateway` ejecutándose con configuración desfasada. | Ejecutar `systemctl --user restart hermes-gateway`. |
| Habilidad nueva no visible tras git pull | El registro en memoria de herramientas no ha sido refrescado. | Enviar `/reload-skills` en WhatsApp o ejecutar `hermes -z "/reload-skills" --yolo`. |
| Cron de auto-sync falla con "Blocked: script path resolves outside..." | El script en `~/.hermes/scripts/` es un symlink a un destino exterior. | Mantener el archivo físico en `~/.hermes/scripts/sync_agent_os_core.sh` y enlazar simbólicamente hacia `${HOME}/scripts/`. |
| Puente WhatsApp sin respuesta | Bridge Node.js desconectado o sesión QR expirada. | Inspeccionar `journalctl --user -u hermes-gateway -n 50` y reiniciar el servicio de gateway si procede. |

---

## 11. Checklist Post-Cambio

- [ ] Backup previo de `~/.hermes/config.yaml` guardado con timestamp.
- [ ] Bind de puertos verificado en `<TAILSCALE_IP>` o `0.0.0.0` (nunca restringido a `127.0.0.1` para servicios de red).
- [ ] Servicios `hermes-dashboard` y `hermes-gateway` en estado `active (running)`.
- [ ] Cronjob de auto-sincronización `Agent OS Core Sync` verificado en `hermes cron list` con `no_agent: true`.
- [ ] Briefing matutino en WhatsApp (`fleet_morning_briefing.py`) verificado reportando versión y skills del Core.
- [ ] Contrato `${HOME}/AGENTS.md` desplegado y alineado con `SOUL.md`.
- [ ] Procesos huérfanos eliminados tras auditoría de TTY.
- [ ] Credenciales inyectadas efímeramente vía Infisical sin archivos `.env` en repositorios.
- [ ] Test de inferencia `hermes -z "ping" --yolo` verificado retornando `pong`.
