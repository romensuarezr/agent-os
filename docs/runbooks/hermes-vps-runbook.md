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
│  Nodo VPS (datamanager / oracle)                            │
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

En nodos donde Hermes opera como demonio (ej. `datamanager`):

```bash
# Ver estado de los servicios
systemctl --user status hermes-dashboard --no-pager
systemctl --user status hermes-gateway --no-pager

# Reiniciar Dashboard tras cambios de interfaz o red
systemctl --user restart hermes-dashboard

# Reiniciar Gateway tras cambios en ~/.hermes/config.yaml
# NOTA: Provoca una desconexión transitoria de ~3 segundos en mensajería
systemctl --user restart hermes-gateway

# Consultar logs en tiempo real
journalctl --user -u hermes-gateway -n 50 -f
journalctl --user -u hermes-dashboard -n 50 -f
```

---

## 5. Detección y Limpieza de Procesos Huérfanos

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

## 6. Verificación Operativa y Health Checks

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

## 7. Troubleshooting

| Síntoma | Causa probable | Acción correctiva |
|---|---|---|
| `connection refused` en `127.0.0.1:9119` | Bind exclusivo a la interfaz Tailscale. | Conectar directamente a `http://<TAILSCALE_IP>:9119`. |
| `HTTP 302 Found` al consultar `9119` | Comportamiento normal con autenticación web habilitada. | Abrir en navegador y completar login de sesión. |
| `HTTP 403 / 402` en consultas LLM | Modelo comercial invocado sin saldo en OpenRouter. | Restringir el modelo al sufijo `:free` o conmutar a `custom:omniroute`. |
| `hermes: command not found` vía SSH no login | `~/.local/bin` o el virtualenv no están en el `PATH` no interactivo. | Invocar con `PATH=$HOME/.local/bin:$HOME/.hermes/hermes-agent/venv/bin:$PATH hermes`. |
| Subdominio `trycloudflare.com` caído | Túnel efímero expirado. | Migrar la `base_url` a `http://<TAILSCALE_IP>:20128/v1` en Tailscale. |
| Cron jobs en estado "config drifted" | `hermes-gateway` ejecutándose con configuración desfasada. | Ejecutar `systemctl --user restart hermes-gateway`. |

---

## 8. Checklist Post-Cambio

- [ ] Backup previo de `~/.hermes/config.yaml` guardado con timestamp.
- [ ] Bind de puertos verificado en `<TAILSCALE_IP>` o `0.0.0.0` (nunca restringido a `127.0.0.1` para servicios de red).
- [ ] Servicios `hermes-dashboard` y `hermes-gateway` en estado `active (running)`.
- [ ] Procesos huérfanos eliminados tras auditoría de TTY.
- [ ] Credenciales inyectadas efímeramente vía Infisical sin archivos `.env` en repositorios.
- [ ] Test de inferencia `hermes -z "ping" --yolo` verificado retornando `pong`.
