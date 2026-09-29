# Runbook: Auditoría de Solo Lectura y Decision Gates de Orca ADE

> **Fecha**: 2026-09-24  
> **Objetivo**: Establecer el procedimiento estándar de diagnóstico no destructivo para verificar el estado de Orca Desktop, su base de datos de orquestación, los relays remotos SSH y las compuertas de decisión (Decision Gates).  
> **Herramienta**: `scripts/agent/audit-orca.sh`

---

## 1. Paso 1: Verificación de Procesos Locales de Orca Desktop

Orca opera como una aplicación Electron con múltiples subprocesos de renderizado y terminales embebidos.

### 1.1 Comprobar ejecución activa
```bash
ps aux | grep -E 'orca-ide' | grep -v grep
```
*Salida esperada:* Proceso `orca-ide` con PID activo y subprocesos de GPU/renderers.

### 1.2 Inspeccionar la Base de Datos de Orquestación (`orchestration.db`)
Ejecuta una consulta no destructiva para verificar el estado de las tablas maestras:
```bash
python3 -c "
import sqlite3, os
db_path = os.path.expanduser('~/.config/orca/orchestration.db')
if os.path.exists(db_path):
    con = sqlite3.connect(db_path)
    cur = con.cursor()
    for table in ['runs', 'tasks', 'decision_gates', 'worker_dispatches']:
        try:
            cur.execute(f'SELECT count(*) FROM {table}')
            print(f'Tabla {table}: {cur.fetchone()[0]} registros')
        except Exception as e:
            print(f'Error en {table}: {e}')
else:
    print('Base de datos no encontrada en ~/.config/orca/orchestration.db')
"
```

### 1.3 Comprobar Decision Gates pendientes
Verifica si existen compuertas de decisión esperando intervención humana:
```bash
python3 -c "
import sqlite3, os
db_path = os.path.expanduser('~/.config/orca/orchestration.db')
if os.path.exists(db_path):
    con = sqlite3.connect(db_path)
    cur = con.cursor()
    try:
        cur.execute('SELECT id, status, prompt FROM decision_gates WHERE status = \"pending\"')
        rows = cur.fetchall()
        print(f'Gates pendientes: {len(rows)}')
        for r in rows:
            print(f' - ID: {r[0]} | Pregunta: {r[2]}')
    except Exception as e:
        print(f'Error al consultar gates: {e}')
"
```

---

## 2. Paso 2: Auditoría Rápida vía `audit-orca.sh`

El script determinista unifica todas las comprobaciones en un digest:

```bash
bash scripts/agent/audit-orca.sh
```

---

## 3. Verificación de Conectividad con Servidores Remotos

Orca delega la ejecución de agentes en servidores configurados en `config/fleet.yaml` o `~/.ssh/config`:

```bash
# Diagnóstico de conexión desatendida (sin prompt interactivo):
ssh -o BatchMode=yes -o ConnectTimeout=5 <worker-node> "echo 'Conexión OK'"
ssh -o BatchMode=yes -o ConnectTimeout=5 <infra-node> "echo 'Conexión OK'"
```

---

## 4. Auditoría de Espacio en Workspaces Efímeros

Orca genera entornos de trabajo en carpetas temporales. Es crítico vigilar que no acumulen artefactos de compilación masivos:

### 4.1 En Host Local:
```bash
du -sh ~/.orca/workspaces/* 2>/dev/null || echo "Sin workspaces locales"
```

### 4.2 En Nodo Remoto:
```bash
ssh -o BatchMode=yes <infra-node> "df -h / && ls -la ~/.orca-remote/ 2>/dev/null"
```
*Alerta de Seguridad:* Si el uso de disco supera el **75%**, escala al operador para ejecutar limpieza de contenedores o capas huérfanas antes de despachar nuevos worktrees.

---

## 5. Protocolo de Decision Gates (Nivel L3)

De acuerdo con la directiva declarativa [.agents/rules/global/agent-permissions.md](file:///.agents/rules/global/agent-permissions.md), el control plane clasifica las operaciones de Orca en 3 niveles:
- **L1 (Solo Lectura / Diagnóstico)**: Ejecución autónoma sin interrupción (`audit-orca.sh`, `scout.sh`, inspección de procesos).
- **L2 (Plan Previo Aprobado)**: Edición de código dentro de un workspace o rama git dedicada.
- **L3 (Decision Gate Obligatorio)**: Mutaciones de infraestructura en servidores remotos, comandos de borrado, alteración de firewalls o despliegues en producción.

### Mecanismo de Bloqueo en Orca:
1. Cuando un worker o runner detecta una acción clasificada como **L3**, suspende la ejecución y registra una entrada en la tabla `decision_gates`:
   - `status = 'pending'`
   - `question`: Descripción del impacto y comando propuesto.
   - `options`: Opciones disponibles para el operador humano.
2. La interfaz gráfica de **Orca Desktop** despliega una notificación modal bloqueante requiriendo la confirmación explícita del usuario.
3. El proceso queda en espera (`await`) hasta que el usuario aprueba o cancela la acción desde la UI.
4. El agente supervisor puede comprobar en cualquier momento si hay compuertas abiertas ejecutando `bash scripts/agent/audit-orca.sh`.

---

## 6. Resultados Validados del Diagnóstico

El formato estructurado emitido por el script `audit-orca.sh`:

```text
=== 🐳 AUDITORÍA DEL ORQUESTADOR ORCA ===
🖥️  ORCA LOCAL PROCESS:
  Status: ACTIVO ✅ (Main PID: 9642, Subprocesos: 12)
  Memoria: 67.6 MB | Uptime: 6-04:16:29

💾 BASE DE DATOS DE ORQUESTACIÓN:
  Ubicación: ~/.config/orca/orchestration.db (Modo Solo Lectura ✅)
  Runs: 1 | Tareas: 0 | Dispatches: 0
  Decision Gates: 0 totales | 0 PENDIENTES 🔒

🌐 RELAYS REMOTOS:
  <worker-node> (<TAILSCALE_IP>): ONLINE ✅
  <infra-node> (<TAILSCALE_IP>):  ONLINE ✅

📁 ESPACIO EN WORKSPACES:
  Local (~/.orca/workspaces): 2.9G
  Remoto (~/.orca-remote): 67M
=== FIN AUDITORÍA ORCA ===
```
