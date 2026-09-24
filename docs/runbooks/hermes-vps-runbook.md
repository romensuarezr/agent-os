# Hermes VPS Runbook

Entorno validado para operar Hermes Desktop local contra un backend remoto en VPS a través de Tailscale, con Hermes Dashboard, Hermes Gateway y Ollama como motor local de inferencia.[cite:605][cite:642]

## Arquitectura

La topología validada separa interfaz y ejecución: Hermes Desktop corre en local, mientras el backend vive en el VPS y se expone de forma privada por la red Tailnet.[cite:255][cite:448]

Componentes:
- Hermes Desktop local, usado como cliente de sesión remoto.[cite:255]
- Hermes Dashboard en el VPS, publicado en la IP de Tailscale y puerto 9119.[cite:605][cite:630]
- Hermes Gateway en el VPS, activo como servicio persistente.[cite:603]
- Ollama local en el VPS, usado como backend LLM mediante endpoint OpenAI-compatible.[cite:642][cite:653]

Flujo operativo:
1. Hermes Desktop se conecta al dashboard remoto por la IP de Tailscale.[cite:255][cite:559]
2. El dashboard autentica al usuario y coordina la sesión.[cite:538][cite:603]
3. Hermes Agent enruta las peticiones de inferencia al backend de Ollama en el VPS.[cite:647][cite:642]
4. Ollama responde usando su interfaz compatible con OpenAI en `/v1`.[cite:653][cite:642]

## Configuración validada

La configuración estable usa un endpoint custom OpenAI-compatible hacia Ollama local, en lugar del flujo `provider: ollama`, para evitar errores de enrutamiento y el `HTTP 404` observado durante la auditoría.[cite:659][cite:642]

Parámetros clave:
- `provider: custom`.[cite:258][cite:659]
- `base_url: http://127.0.0.1:11434/v1`.[cite:642][cite:653]
- Modelo validado: `llama3.1:8b`.[cite:488]
- `context_length: 131072`, alineado con el contexto largo soportado por Ollama para este caso operativo.[cite:651][cite:488]

Comportamiento de red esperado:
- El dashboard escucha en `100.77.82.13:9119`.[cite:605]
- `127.0.0.1:9119` puede devolver `connection refused` si el bind está limitado a la interfaz de Tailscale.[cite:605][cite:448]
- `http://100.77.82.13:9119/` y `/health` pueden responder `302` a `/login` cuando la autenticación del dashboard está activa.[cite:538]

## Verificación operativa

### Estado de servicios

```bash
systemctl --user status hermes-dashboard --no-pager
systemctl --user status hermes-gateway --no-pager
```

Resultado esperado: ambos servicios en estado `active (running)`.[cite:603]

### Listener de red

```bash
ss -tlnp | grep 9119
```

Resultado esperado: listener en `100.77.82.13:9119` asociado al proceso de Hermes.[cite:605]

### Validación del dashboard

```bash
curl -v http://100.77.82.13:9119/
curl -v http://100.77.82.13:9119/health
```

Resultado esperado: respuesta `302 Found` con redirección a `/login` cuando la autenticación está habilitada.[cite:538]

### Validación de Ollama

```bash
curl -sS http://127.0.0.1:11434/api/tags
curl -sS http://127.0.0.1:11434/v1/models
```

Resultado esperado: el backend responde tanto al listado nativo como al endpoint OpenAI-compatible necesario para Hermes.[cite:653][cite:642]

### Prueba funcional del agente

```bash
API_KEY=$(grep "API_SERVER_KEY" ~/.hermes/.env | cut -d= -f2)
curl -v -H "Authorization: Bearer $API_KEY" \
  http://100.77.82.13:8642/v1/chat/completions \
  -d '{"model":"llama3.1:8b","messages":[{"role":"user","content":"hola"}],"stream":false}'
```

Resultado esperado: `HTTP 200` con una respuesta JSON válida del modelo.[cite:636][cite:653]

## Troubleshooting

| Síntoma | Causa probable | Acción recomendada |
|---|---|---|
| `127.0.0.1:9119` falla | Bind solo en Tailscale, comportamiento esperado.[cite:605] | Probar contra `100.77.82.13:9119`. |
| `302 /login` en `9119` | Dashboard operativo con auth activa.[cite:538] | Abrir en navegador y autenticar. |
| `404 page not found` hacia `11434` | Base URL o provider mal configurado; falta `/v1` o se usa el flujo incorrecto.[cite:653][cite:659] | Revisar `provider: custom` y `base_url: http://127.0.0.1:11434/v1`. |
| Desktop no completa handshake | Token, caché local o descubrimiento de capacidades defectuoso.[cite:635][cite:642] | Reabrir Desktop, reintroducir token y limpiar caché local si persiste. |
| El modelo no responde | Modelo no cargado o endpoint LLM incorrecto.[cite:621][cite:653] | Verificar `api/tags`, modelo y logs del gateway. |

## Checklist post-cambio

- Confirmar backup antes de tocar configuración crítica.
- Validar servicios `hermes-dashboard` y `hermes-gateway` tras cada reinicio.
- Probar listener en `9119` después de cambios de red o auth.
- Confirmar `api/tags` y `v1/models` después de cambios de provider.
- Ejecutar una prueba de chat real antes de considerar el sistema estable.[cite:603][cite:653]

## Notas operativas

El dashboard web y el backend LLM no son la misma superficie y deben diagnosticarse por separado: `9119` confirma acceso web y auth, mientras `11434` y `8642` validan inferencia y API del agente.[cite:538][cite:636][cite:653]

La configuración final valida una arquitectura híbrida privada: cómputo en VPS, interfaz en local y exposición limitada a Tailscale, lo que reduce superficie pública sin perder usabilidad operativa.[cite:448][cite:255]
