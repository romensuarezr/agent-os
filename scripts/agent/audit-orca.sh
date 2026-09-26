#!/usr/bin/env bash
# audit-orca.sh — Diagnóstico integral y no destructivo del orquestador Orca (Local y Remoto)
# Uso: bash scripts/agent/audit-orca.sh
#
# Propósito: Inspeccionar en una sola llamada y con 0 tokens de inferencia:
# 1. Proceso activo de Orca Desktop (local)
# 2. Estado y tablas de orchestration.db (runs, tasks, decision_gates pendientes) en modo RO
# 3. Conectividad y sockets de los relés de Orca en VPS datamanager y oracle
# 4. Consumo de disco en workspaces efímeros

set -euo pipefail

DB_PATH="/home/romen/.config/orca/orchestration.db"

echo "=== 🐳 AUDITORÍA DEL ORQUESTADOR ORCA ==="
echo "Timestamp: $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
echo ""

# 1. ORCA LOCAL PROCESS
echo "🖥️  ORCA LOCAL PROCESS:"
ORCA_PIDS=$(pgrep -f "/opt/Orca/orca-ide" 2>/dev/null || true)
if [ -n "$ORCA_PIDS" ]; then
  MAIN_PID=$(echo "$ORCA_PIDS" | head -1)
  PROC_COUNT=$(echo "$ORCA_PIDS" | wc -l)
  MEM_MB=$(ps -o rss= -p "$MAIN_PID" 2>/dev/null | awk '{printf "%.1f MB", $1/1024}')
  UPTIME=$(ps -o etime= -p "$MAIN_PID" 2>/dev/null | xargs)
  echo "  Status: ACTIVO ✅ (Main PID: $MAIN_PID, Subprocesos: $PROC_COUNT)"
  echo "  Memoria: $MEM_MB | Uptime: $UPTIME"
else
  echo "  Status: INACTIVO ❌ (Orca Desktop no está en ejecución)"
fi

echo ""

# 2. ORCHESTRATION DATABASE (READ-ONLY)
echo "💾 BASE DE DATOS DE ORQUESTACIÓN:"
if [ -f "$DB_PATH" ]; then
  python3 -c "
import sqlite3, sys

try:
    con = sqlite3.connect('file:$DB_PATH?mode=ro', uri=True)
    cur = con.cursor()
    
    # Recuento de tablas clave
    stats = {}
    for table in ['runs', 'tasks', 'decision_gates', 'worker_dispatches', 'mutation_receipts']:
        try:
            cur.execute(f'SELECT count(*) FROM {table}')
            stats[table] = cur.fetchone()[0]
        except Exception:
            stats[table] = 'N/A'
    
    print(f'  Ubicación: $DB_PATH (Modo Solo Lectura ✅)')
    print(f'  Runs: {stats.get(\"runs\", 0)} | Tareas: {stats.get(\"tasks\", 0)} | Dispatches: {stats.get(\"worker_dispatches\", 0)}')
    print(f'  Mutation Receipts: {stats.get(\"mutation_receipts\", 0)}')
    
    # Decision Gates
    cur.execute('SELECT count(*) FROM decision_gates WHERE status = \"pending\"')
    pending_count = cur.fetchone()[0]
    total_gates = stats.get('decision_gates', 0)
    print(f'  Decision Gates: {total_gates} totales | {pending_count} PENDIENTES 🔒')
    
    if pending_count > 0:
        cur.execute('SELECT id, question, status FROM decision_gates WHERE status = \"pending\" LIMIT 5')
        for row in cur.fetchall():
            print(f'    ↳ Gate {row[0]}: \"{row[1]}\" [{row[2]}]')
            
except Exception as e:
    print(f'  Error consultando orchestration.db: {e}')
"
else
  echo "  No encontrada en $DB_PATH"
fi

echo ""

# 3. REMOTE RELAYS EN VPS
echo "🌐 RELAYS REMOTOS:"
# datamanager
DM_RELAY=$(ssh -n -o BatchMode=yes -o ConnectTimeout=3 datamanager \
  "ps aux | grep -E 'relay\.js' | grep -v grep | head -1" 2>/dev/null || echo "")
if [ -n "$DM_RELAY" ]; then
  DM_PID=$(echo "$DM_RELAY" | awk '{print $2}')
  echo "  datamanager: ONLINE ✅ (PID: $DM_PID)"
else
  echo "  datamanager: OFFLINE ❌ (Sin proceso relay.js)"
fi

# oracle
ORA_RELAY=$(ssh -n -o BatchMode=yes -o ConnectTimeout=3 oracle \
  "ps aux | grep -E 'relay\.js' | grep -v grep | head -1" 2>/dev/null || echo "")
if [ -n "$ORA_RELAY" ]; then
  ORA_PID=$(echo "$ORA_RELAY" | awk '{print $2}')
  echo "  oracle:       ONLINE ✅ (PID: $ORA_PID)"
else
  echo "  oracle:       OFFLINE ❌ (Sin proceso relay.js)"
fi

echo ""

# 4. WORKSPACES Y ESPACIO TEMPORAL
echo "📁 ESPACIO EN WORKSPACES:"
if [ -d "/home/romen/orca/workspaces" ]; then
  LOCAL_WS_SIZE=$(du -sh /home/romen/orca/workspaces 2>/dev/null | awk '{print $1}')
  echo "  Local (/home/romen/orca/workspaces): $LOCAL_WS_SIZE"
else
  echo "  Local: Sin carpeta workspaces activa"
fi

ORA_REMOTE_SIZE=$(ssh -n -o BatchMode=yes -o ConnectTimeout=3 oracle \
  "du -sh /home/ubuntu/.orca-remote 2>/dev/null | awk '{print \$1}'" 2>/dev/null || echo "N/A")
echo "  oracle (~/.orca-remote): $ORA_REMOTE_SIZE"

echo ""
echo "=== FIN AUDITORÍA ORCA ==="
