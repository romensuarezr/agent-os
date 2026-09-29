# Hermes VPS Runbook

Entorno validado para operar Hermes Desktop local contra un backend remoto en VPS a través de Tailscale, con Hermes Dashboard, Hermes Gateway y Ollama como motor local de inferencia.

## Arquitectura

La topología validada separa interfaz y ejecución: Hermes Desktop corre en local, mientras el backend vive en el VPS y se expone de forma privada por la red Tailnet (`config/fleet.yaml`).

Componentes:
- Hermes Desktop local, usado como cliente de sesión remoto.
- Hermes Dashboard en el VPS, publicado en la IP de Tailscale y puerto 9119.
- Hermes Gateway en el VPS, activo como servicio persistente.
- Ollama local en el VPS, usado como backend LLM mediante endpoint OpenAI-compatible.

Flujo operativo:
1. Hermes Desktop se conecta al dashboard remoto por la IP de Tailscale (`<TAILSCALE_IP>`).
2. El dashboard autentica al usuario y coordina la sesión.
3. Hermes Agent enruta las peticiones de inferencia al backend de Ollama en el VPS.
4. Ollama responde usando su interfaz compatible con OpenAI en `/v1`.

## Configuración validada

La configuración estable usa un endpoint custom OpenAI-compatible hacia Ollama local, en lugar del flujo `provider: ollama`, para evitar errores de enrutamiento y el `HTTP 404` observado durante la auditoría.

Parámetros clave:
- `provider: custom`.
- `base_url: http://127.0.0.1:11434/v1`.
- Modelo validado: `llama3.1:8b` (o equivalente local).
- `context_length: 131072`, alineado con el contexto soportado por Ollama para este caso operativo.

Comportamiento de red esperado:
- El dashboard escucha en `<TAILSCALE_IP>:9119`.
- `127.0.0.1:9119` puede devolver `connection refused` si el bind está limitado a la interfaz de Tailscale.
- `http://<TAILSCALE_IP>:9119/` y `/health` pueden responder `302` a `/login` cuando la autenticación del dashboard está activa.

## Verificación operativa

### Estado de servicios

```bash
systemctl --user status hermes-dashboard --no-pager
systemctl --user status hermes-gateway --no-pager
```

Resultado esperado: ambos servicios en estado `active (running)`.

### Listener de red

```bash
ss -tlnp | grep 9119
```

Resultado esperado: listener en `<TAILSCALE_IP>:9119` asociado al proceso de Hermes.

### Validación del dashboard

```bash
curl -v http://<TAILSCALE_IP>:9119/
curl -v http://<TAILSCALE_IP>:9119/health
```

Resultado esperado: respuesta `302 Found` con redirección a `/login` cuando la autenticación está habilitada.

### Validación de Ollama

```bash
curl -sS http://127.0.0.1:11434/api/tags
curl -sS http://127.0.0.1:11434/v1/models
```

Resultado esperado: el backend responde tanto al listado nativo como al endpoint OpenAI-compatible necesario para Hermes.

### Prueba funcional del agente

```bash
API_KEY=$(grep "API_SERVER_KEY" ~/.hermes/.env | cut -d= -f2)
curl -v -H "Authorization: Bearer $API_KEY" \
  http://<TAILSCALE_IP>:8642/v1/chat/completions \
  -d '{"model":"llama3.1:8b","messages":[{"role":"user","content":"hola"}],"stream":false}'
```

Resultado esperado: `HTTP 200` con una respuesta JSON válida del modelo.

## Troubleshooting

| Síntoma | Causa probable | Acción recomendada |
|---|---|---|
| `127.0.0.1:9119` falla | Bind solo en Tailscale, comportamiento esperado. | Probar contra `<TAILSCALE_IP>:9119`. |
| `302 /login` en `9119` | Dashboard operativo con auth activa. | Abrir en navegador y autenticar. |
| `404 page not found` hacia `11434` | Base URL o provider mal configurado; falta `/v1` o se usa el flujo incorrecto. | Revisar `provider: custom` y `base_url: http://127.0.0.1:11434/v1`. |
| Desktop no completa handshake | Token, caché local o descubrimiento de capacidades defectuoso. | Reabrir Desktop, reintroducir token y limpiar caché local si persiste. |
| El modelo no responde | Modelo no cargado o endpoint LLM incorrecto. | Verificar `api/tags`, modelo y logs del gateway. |

## Checklist post-cambio

- Confirmar backup antes de tocar configuración crítica.
- Validar servicios `hermes-dashboard` y `hermes-gateway` tras cada reinicio.
- Probar listener en `9119` después de cambios de red o auth.
- Confirmar `api/tags` y `v1/models` después de cambios de provider.
- Ejecutar una prueba de chat real antes de considerar el sistema estable.
