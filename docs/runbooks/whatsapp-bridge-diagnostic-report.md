# 📋 Informe Técnico de Diagnóstico: Inoperatividad de whatsapp-bridge

> **Tipo**: Diagnóstico Forense Determinista (Solo Lectura — Cero Arreglo a Ciegas)  
> **Tarea**: T-176 (Sprint 31)  
> **Fecha**: 2026-11-09  
> **Objetivo**: Aislar la causa raíz exacta de la inoperatividad de `whatsapp-bridge` con evidencia verificable sin aplicar modificaciones de código ni reinicios destructivos.  
> **Estado**: Diagnóstico completado — Pendiente de decisión del operador  

---

## 1. Resumen Ejecutivo

- **Estado Actual del Servicio**: ❌ **INOPERATIVO** (Ciclo de terminación y reintento continuo en segundo plano).
- **Causa Raíz Principal**: **Sesión de WhatsApp desvinculada/revocada en origen (`DisconnectReason.loggedOut` — HTTP 401)**.
- **Modo de Fallo**: El proceso Node.js (`bridge.js`) arranca bajo la supervisión de `hermes-gateway.service`, carga la sesión persistida en disco y recibe de los servidores de WhatsApp un rechazo de autenticación por cierre de sesión (`logged_out`). El proceso emite el aviso `❌ Logged out. Delete session and restart to re-authenticate.` y finaliza inmediatamente con código de salida `1`. `hermes-gateway` reintenta el ciclo cada ~5 minutos sin éxito.
- **Puerto de Escucha**: El puerto real de escucha configurado en la ejecución activa de `hermes-gateway` es el **puerto `:3000`** (actualmente libre debido a la muerte del proceso). El puerto `:3001` (indicado en la unidad legacy systemd) está ocupado por el contenedor Docker `freellmapi`.
- **Mutaciones ejecutadas en el host**: **0** (Principio de cero parche a ciegas estrictamente cumplido; estado del sistema 100% inalterado).

---

## 2. Topología y Componentes Inspeccionados

La inspección se llevó a cabo en el nodo de inferencia y mensajería de la flota (`<nodo-inferencia>`):

| Componente | Tipo | Estado Observado | Observaciones |
| :--- | :--- | :--- | :--- |
| **`hermes-gateway.service`** | `systemd --user` | `active (running)` | Gateway principal activo; supervisa la conexión de mensajería (Telegram y WhatsApp). |
| **`whatsapp-bridge.service`** | `systemd --user` | `inactive (dead)` / `disabled` | Unidad independiente heredada (detenida desde el 12 de julio por conflicto 440 con puerto 3001). |
| **`whatsapp-groups-watcher.service`** | `systemd --user` | `active (running)` | Demonio de supervisión de grupos de WhatsApp. |
| **`bridge.js` (`@whiskeysockets/baileys`)** | Proceso hijo de Node.js | Termina con exit code 1 | Invocado por `hermes-gateway` vía socket relay local. |

---

## 3. Evidencia Empírica Capturada

### 3.1. Estado de la Unidad `systemd` y Conflicto Histórico
La consulta al servicio independiente `whatsapp-bridge.service` revela que se encuentra deshabilitado y detenido:

```text
○ whatsapp-bridge.service - WhatsApp bridge (independiente, puerto 3001)
     Loaded: loaded (/home/ubuntu/.config/systemd/user/whatsapp-bridge.service; disabled; vendor preset: enabled)
     Active: inactive (dead)
Jul 12 12:39:09 <nodo-inferencia> node[...]: {"reasonNode":{"tag":"conflict","attrs":{"type":"replaced"}},"msg":"stream errored out"}
Jul 12 12:39:09 <nodo-inferencia> node[...]: ⚠️  Connection closed (reason: 440). Reconnecting in 3s...
Jul 12 12:39:15 <nodo-inferencia> systemd[...]: Stopping WhatsApp bridge (independiente, puerto 3001)...
Jul 12 12:39:15 <nodo-inferencia> systemd[...]: Stopped WhatsApp bridge (independiente, puerto 3001).
```

*Hallazgo*: En julio de 2026, existió una colisión de sesiones concurrentes (código 440 `conflict replaced`) provocada por tener dos entidades intentando conectarse a la misma sesión de WhatsApp. El servicio independiente fue desactivado en favor del supervisor integrado en `hermes-gateway.service`.

### 3.2. Sockets y Puertos de Escucha (`ss -tulpn`)
La verificación determinista de puertos en `<nodo-inferencia>` arrojó:

```text
Netid State  Recv-Q Send-Q   Local Address:Port      Process
tcp   LISTEN 0      4096     <TAILSCALE_IP>:3001     users:(("docker-proxy",...))  # freellmapi
tcp   LISTEN 0      4096     <TAILSCALE_IP>:3005     users:(("docker-proxy",...))  # open-webui
tcp   LISTEN 0      4096     <TAILSCALE_IP>:20128    users:(("docker-proxy",...))  # omniroute
tcp   LISTEN 0      2048     <TAILSCALE_IP>:9119     users:(("hermes",...))        # hermes-dashboard
tcp   LISTEN 0      128      0.0.0.0:8642            users:(("hermes",...))        # hermes-gateway
```

- **Puerto `:3001`**: Ocupado por el proxy de inferencia `freellmapi`.
- **Puerto `:3000`**: Totalmente libre (no hay ningún proceso escuchando). Este es el puerto asignado por defecto al subproceso `bridge.js` de Hermes.

### 3.3. Logs del Gateway Activo (`hermes-gateway.service`)
El volcado de los eventos recientes de `journalctl --user -u hermes-gateway -n 50` evidencia el fallo repetitivo cada 5 minutos:

```text
Nov 09 18:17:21 <nodo-inferencia> python[...]: [Whatsapp] Bridge process died (exit code 1)
Nov 09 18:17:21 <nodo-inferencia> python[...]: [Whatsapp] Check log: /home/ubuntu/.hermes/whatsapp/bridge.log
Nov 09 18:17:22 <nodo-inferencia> python[...]: [Whatsapp] Disconnected
Nov 09 18:22:30 <nodo-inferencia> python[...]: [Whatsapp] Bridge process died (exit code 1)
Nov 09 18:22:30 <nodo-inferencia> python[...]: [Whatsapp] Check log: /home/ubuntu/.hermes/whatsapp/bridge.log
Nov 09 18:22:31 <nodo-inferencia> python[...]: [Whatsapp] Disconnected
Nov 09 18:27:39 <nodo-inferencia> python[...]: [Whatsapp] Bridge process died (exit code 1)
Nov 09 18:32:47 <nodo-inferencia> python[...]: [Whatsapp] Bridge process died (exit code 1)
```

### 3.4. Causa Raíz en el Log del Puente (`bridge.log`)
La inspección de `/home/ubuntu/.hermes/whatsapp/bridge.log` aisló con absoluta certeza el punto exacto de interrupción:

```text
🌉 WhatsApp bridge listening on port 3000 (mode: bot)
📁 Session stored in: /home/ubuntu/.hermes/whatsapp/session
🔒 Allowed users: <REDACTED_USER_1>, <REDACTED_USER_2>
🔒 Allowed groups: <REDACTED_GROUP>

❌ Logged out. Delete session and restart to re-authenticate.
```

Al cotejar con la implementación en `scripts/whatsapp-bridge/bridge.js` (líneas 418-428):

```javascript
if (connection === 'close') {
  const reason = new Boom(lastDisconnect?.error)?.output?.statusCode;
  connectionState = 'disconnected';

  if (reason === DisconnectReason.loggedOut) {
    emitPairEvent({ event: 'error', error: 'logged_out', reason });
    if (!PAIR_JSON) {
      console.log('❌ Logged out. Delete session and restart to re-authenticate.');
    }
    process.exit(1);
  }
  ...
}
```

---

## 4. Taxonomía y Diagnóstico de Causa Raíz

1. **Incompatibilidad de Sesión**: La sesión criptográfica multi-archivo almacenada en `/home/ubuntu/.hermes/whatsapp/session` fue invalidada o desvinculada por WhatsApp (desconexión manual desde el teléfono del operador en "Dispositivos vinculados", o revocación por expiración prolongada).
2. **Ciclo de Reinicio Inerte**: Al estar la credencial revocada, Baileys no genera un nuevo código QR de forma desatendida mientras existan archivos de sesión antiguos en el directorio; simplemente aborta con `DisconnectReason.loggedOut` para evitar bucles de conexión no autorizados.
3. **Aclaración del Puerto**:
   - El puerto real para este puente integrado es `:3000` (el cual está disponible y sin colisiones).
   - El puerto `:3001` pertenece a `freellmapi` y no debe ser utilizado por el bridge para evitar solapamientos.

---

## 5. Opciones de Remediación (Para Decisión del Operador)

De acuerdo con el mandato de gobernanza, **no se ha aplicado ninguna acción correctiva**. Se presentan las siguientes opciones para que el operador decida el siguiente paso:

### Opción 1: Re-autenticación Limpia de Sesión (Recomendada)
1. Realizar un respaldo preventivo de la carpeta de sesión actual:
   `mv /home/ubuntu/.hermes/whatsapp/session /home/ubuntu/.hermes/whatsapp/session.bak.$(date +%Y%m%d)`
2. Crear un directorio vacío para la nueva sesión:
   `mkdir -p /home/ubuntu/.hermes/whatsapp/session`
3. Iniciar el emparejamiento interactivo para escanear el nuevo código QR o código de 8 dígitos desde el teléfono del operador.
4. Una vez emparejado, `hermes-gateway` mantendrá la conexión de forma continua y estable sobre el puerto `:3000`.

### Opción 2: Migración a Pasarela Centralizada (Evolution API)
Si se desea desacoplar totalmente a Baileys del runtime de Hermes, conectar el canal de WhatsApp a la instancia de Evolution API disponible en `<nodo-orquestacion>`, gestionando las sesiones y webhooks desde un panel PaaS centralizado.

---

## 6. Dictamen de la Auditoría
- **Veredicto**: `DIAGNÓSTICO_COMPLETADO`
- **Requiere Código/Parche en Core**: No (el código del core y los scripts de Agent OS están intactos).
- **Acción Pendiente**: Autorización y ejecución de la re-autenticación HITL (Human-in-the-Loop) de WhatsApp en la sesión de Hermes.
