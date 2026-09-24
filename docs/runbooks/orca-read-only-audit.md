# Runbook: Auditoría de Solo Lectura de Orca (Local y Remoto)

> Procedimiento operativo estándar (SOP) para auditar el estado del orquestador Orca, la integridad de su base de datos de orquestación y la conectividad de los relés remotos en los VPS sin alterar el estado del sistema.

---

## 1. Alcance y Principios

- **Modo**: Estrictamente de **solo lectura (Read-Only)**.
- **Prohibiciones**: Prohibido insertar, modificar o eliminar registros en `orchestration.db`, terminar procesos de relay, o crear worktrees de modificación.
- **Targets**: Host Local (`inteligencia-colectiva`), VPS `datamanager` y VPS `oracle`.

---

## 2. Paso 1: Auditoría del Entorno Orca Local

### 1.1 Comprobar proceso de Orca Desktop
Verifica que el entorno Electron de Orca está activo y saludable:
```bash
ps aux | grep -E 'orca-ide' | grep -v grep
```
*Salida esperada:* Proceso `/opt/Orca/orca-ide` con PID activo y subprocesos de GPU/renderers.

### 1.2 Inspeccionar la Base de Datos de Orquestación (`orchestration.db`)
Ejecuta una consulta no destructiva para verificar el estado de las tablas maestras:
```bash
python3 -c "
import sqlite3
con = sqlite3.connect('/home/romen/.config/orca/orchestration.db')
cur = con.cursor()
for table in ['runs', 'tasks', 'decision_gates', 'worker_dispatches']:
    try:
        cur.execute(f'SELECT count(*) FROM {table}')
        print(f'Tabla {table}: {cur.fetchone()[0]} registros')
    except Exception as e:
        print(f'Error en {table}: {e}')
"
```

### 1.3 Comprobar Decision Gates pendientes
Verifica si existen compuertas de decisión esperando intervención humana:
```bash
python3 -c "
import sqlite3
con = sqlite3.connect('/home/romen/.config/orca/orchestration.db')
cur = con.cursor()
try:
    cur.execute('SELECT id, status, prompt FROM decision_gates WHERE status = \"pending\"')
    rows = cur.fetchall()
    print(f'Gates pendientes: {len(rows)}')
    for r in rows:
        print(f' - ID: {r[0]} | Prompt: {r[2]}')
except Exception as e:
    print(f'Sin tabla decision_gates o error: {e}')
"
```

---

## 3. Paso 2: Auditoría de Relés Remotos en VPS

### 2.1 Verificar Relay en VPS `datamanager`
Verifica que el agente relé de Orca está conectado y escuchando sobre su socket UNIX privado:
```bash
ssh -o BatchMode=yes datamanager "ps aux | grep 'relay.js' | grep -v grep"
```
*Salida esperada:* Proceso `node relay.js --connect --sock-path /home/ubuntu/.orca-remote/relay-.../relay-....sock`.

### 2.2 Verificar Relay en VPS `oracle`
Verifica el estado del relé en el servidor de infraestructura:
```bash
ssh -o BatchMode=yes oracle "ps aux | grep 'relay.js' | grep -v grep"
```
*Salida esperada:* Proceso `node relay.js --connect --sock-path /home/ubuntu/.orca-remote/relay-.../relay-....sock`.

### 2.3 Diagnóstico de Salud de Sockets
Si algún relé no aparece listado en los procesos:
- **No reinicies de forma autónoma.**
- Notifica al operador humano para que abra la sesión remota desde Orca Desktop, lo que regenera automáticamente el túnel E2EE.

---

## 4. Paso 3: Auditoría de Espacio en Workspaces Efímeros

Orca genera entornos de trabajo en carpetas temporales. Es crítico vigilar que no acumulen artefactos de compilación masivos:

### 4.1 En Host Local:
```bash
du -sh /home/romen/orca/workspaces/* 2>/dev/null || echo "Sin workspaces locales"
```

### 4.2 En VPS `oracle` (Control de Espacio al 72%):
```bash
ssh -o BatchMode=yes oracle "df -h / && ls -la /home/ubuntu/.orca-remote/ 2>/dev/null"
```
*Alerta de Seguridad:* Si el uso de disco en `oracle` supera el **75%**, escala de inmediato al usuario para ejecutar limpieza manual de contenedores huérfanos. Prohibido desplegar nuevos worktrees en `oracle` mientras supere dicho umbral.

---

## 5. Resumen de Salida para el Agente

Al finalizar la auditoría, genera un resumen conciso:
- **Orca Local**: [Activo / Inactivo]
- **Decision Gates Pendientes**: [Número de gates]
- **Relay datamanager**: [Conectado (PID) / Desconectado]
- **Relay oracle**: [Conectado (PID) / Desconectado]
- **Espacio en disco oracle**: [Porcentaje %]
