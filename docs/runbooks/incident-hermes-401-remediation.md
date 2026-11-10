# 📋 Nota de Incidente: Remediación de Error HTTP 401 en Hermes (Reversión a OmniRoute)

> **Tipo**: Remediación Operativa & Post-Mortem de Incidente  
> **Fecha**: 2026-11-10  
> **Servicio Afectado**: Hermes Gateway & Hermes CLI / Inferencia LLM  
> **Nodo**: `<nodo-inferencia>`  
> **Resolución**: Opción C (Reversión inmediata a OmniRoute — `custom:omniroute` / `auto/best-coding`)  
> **Estado**: 🟢 RESUELTO Y VALIDADO EN PRODUCCIÓN  

---

## 1. Resumen Ejecutivo

Durante la operación matutina del 2026-11-10, las llamadas de inferencia dirigidas a Hermes Agent comenzaron a fallar con `HTTP 401 Unauthorized` (`Invalid API key`).

Por decisión del operador (Opción C), se ejecutó la reversión inmediata del bloque raíz de modelo a la pasarela estable **OmniRoute** (`custom:omniroute`, modelo `auto/best-coding`), posponiendo la rotación formal de credenciales de FreeLLMAPI (Opción B) a una ventana de mantenimiento planificada posterior.

La intervención se realizó de forma quirúrgica sobre `~/.hermes/config.yaml`, preservando intacta la configuración de `custom_providers` (incluida la entrada de FreeLLMAPI) y sin tocar `freeapi.db`. Tras el reinicio de `hermes-gateway.service`, la inferencia fue validada con `pong` (código 0) y una consulta matemática real (`42`, código 0), restableciendo la conectividad completa sin errores 401.

---

## 2. Investigación Causa Raíz: Origen del Cambio de Proveedor (10:30 UTC)

### 2.1. Marcas Temporales en Disco
La auditoría forense determinista de ficheros modificados en `<nodo-inferencia>` (`/home/ubuntu`) entre las 10:25 y 10:35 UTC aisló los siguientes artefactos:

| Archivo | Fecha de Modificación (mtime) | Descripción |
|---|---|---|
| `~/.hermes/config.yaml` | `2026-11-10 10:30:37 UTC` | Fichero de configuración principal de Hermes. |
| `~/.hermes/models_dev_cache.json` | `2026-11-10 10:30:37 UTC` | Caché del catálogo de modelos remotos de Hermes. |
| `~/.hermes/models_dev_cache.etag` | `2026-11-10 10:30:37 UTC` | ETag de sincronización del catálogo. |
| `.../.hermes-ssh-runtime-a7e346b868b280aa` | `2026-11-10 10:30:18 UTC` | Socket/fichero de runtime SSH remoto de Hermes Desktop. |
| `~/.hermes/sessions/request_dump_...json` | `2026-11-10 10:33:08 UTC` | Volcado forense automático tras el primer fallo HTTP 401. |

### 2.2. Vector de Modificación
1. **Conexión Remota de Hermes Desktop**: A las `10:30:17 UTC`, se registró una conexión SSH vía clave pública desde la estación de trabajo del operador (`<nodo-operador>`):
   ```text
   Nov 10 10:30:17 <nodo-inferencia> sshd[3010952]: Accepted publickey for ubuntu from <TAILSCALE_IP> port 46070
   Nov 10 10:30:17 <nodo-inferencia> systemd-logind[958401]: New session 736 of user ubuntu.
   ```
2. **Sincronización de Catálogo y Escritura de Configuración**: La sesión remota de Hermes Desktop desplegó el runtime SSH (`.hermes-ssh-runtime-...`) y, al inicializar la interfaz de usuario/selector de modelos, sincronizó el catálogo (`models_dev_cache.json`) y actualizó `~/.hermes/config.yaml` conmutando el bloque raíz `model:` al proveedor FreeLLMAPI:
   ```yaml
   model:
     default: auto
     provider: custom:freellmapi
     base_url: http://<TAILSCALE_IP>:3001/v1
   ```
3. **Detonación del Fallo 401**: A las `10:33:04 UTC`, se emitió una petición de usuario a través del cliente Desktop. Hermes invocó `POST http://<TAILSCALE_IP>:3001/v1/chat/completions`, resultando en rechazo inmediato capturado en el volcado de sesión `request_dump_20261110_103304_0367ab_20261110_103308_487610.json`:
   ```json
   {
     "error": {
       "type": "authentication_error",
       "message": "Error code: 401 - {'error': {'message': 'Invalid API key', 'type': 'authentication_error'}}",
       "status_code": 401
     }
   }
   ```

---

## 3. Acciones de Remediación Ejecutadas

### 3.1. Respaldo Preventivo con Marca Temporal
Antes de aplicar cualquier modificación, se generó una copia íntegra con timestamp de la configuración activa:
```bash
cp -p /home/ubuntu/.hermes/config.yaml /home/ubuntu/.hermes/config.yaml.bak.20261110_150340
```

### 3.2. Reversión Quirúrgica del Bloque Raíz `model:`
Se sustituyeron estrictamente las líneas 1-5 de `~/.hermes/config.yaml`, restaurando la configuración de OmniRoute previa a las 10:30 UTC:

```diff
--- config.yaml.bak.20261110_150340
+++ config.yaml
@@ -1,7 +1,7 @@
 model:
-  default: auto
-  provider: custom:freellmapi
-  base_url: http://<TAILSCALE_IP>:3001/v1
+  default: auto/best-coding
+  provider: custom:omniroute
+  base_url: http://<TAILSCALE_IP>:20128/v1
   api_key: [REDACTED_OMNIROUTE_API_KEY]
 web:
   backend: firecrawl
```

**Guardias de Inalterabilidad**:
- La entrada `freellmapi` dentro de `custom_providers` permanece intacta.
- La base de datos `freeapi.db` no fue tocada en ningún momento.
- Permisos del archivo preservados en `0600` (`-rw-------`).

### 3.3. Reinicio Controlado del Demonio Gateway
Conforme al runbook operativo (desconexión transitoria ~3s):
```bash
systemctl --user restart hermes-gateway.service
```

---

## 4. Evidencia Empírica de Verificación

### 4.1. Ping Determinista de Inferencia
Ejecución en shell de login sobre `<nodo-inferencia>`:
```text
$ hermes -z ping
pong
[Exit Code: 0]
```

### 4.2. Llamada Real de Inferencia Operativa
Prueba de razonamiento sintético directo:
```text
$ hermes -z "Responde en una linea: Cuanto es 15+27?"
42
[Exit Code: 0]
```

### 4.3. Estado y Logs de `hermes-gateway.service`
- **Estado del Servicio**:
  ```text
  ● hermes-gateway.service - Hermes Agent Gateway - Messaging Platform Integration
       Active: active (running)
     Main PID: 3064189 (hermes)
  ```
- **Conectividad de Mensajería**:
  ```text
  [Telegram] Connected to Telegram (polling mode)
  ```
- **Ausencia de Errores 401**: Cero registros de error de autenticación HTTP 401 en los logs posteriores al reinicio.
- **WhatsApp**: Mantiene el estado esperado `disconnected` debido a la sesión revocada en origen (objeto del diagnóstico previo en T-176).

---

## 5. Acciones de Seguimiento

1. **Rotación Formal de FreeLLMAPI (Opción B)**: Agendada como ítem técnico formal en el backlog para realizar el aprovisionamiento y rotación coordinada de claves con Infisical y FreeLLMAPI.
2. **Re-autenticación de WhatsApp Bridge**: Pendiente de ejecución interactiva del operador para escanear el nuevo código/QR de emparejamiento.
