---
trigger: task-execution
---

# Rule: Agent Sandbox (No-Root)

> Prioridad alta: Daemons, agentes y contenedores operan sin privilegios `root`. Si algo necesita root para arrancar, el diseño está mal.

## Reglas

1. **Proceso no-root**: todo daemon o agente lanzado por el flujo de trabajo corre con el usuario efectivo no cero. Verificación: `id -u` → debe ser distinto de `0`.
2. **Procesos de servicio**: para un proceso en marcha, comprobar el usuario real: `ps -o user=,comm= -p <PID>` (sin asumir nombre de usuario concreto: se valida «no root», no «un usuario específico»).
3. **Contenedores**: si Docker está disponible, el contenedor declara usuario no privilegiado:
   `docker inspect -f '{{.Config.User}}' <nombre>` → no vacío y distinto de `root`.
   Docker ausente → comprobación `SKIP` explícita (nunca `PASS` silencioso).
4. **Prohibido**: `user: root`, `privileged: true`, `--user root` o ausencia de usuario declarado en compose/scripts nuevos.
5. **Escalada justificada**: solo lecturas de sistema que exijan root (p. ej. inspección de puertos) se ejecutan puntuales con `sudo` y jamás como modo por defecto del servicio.

## Comandos de verificación determinista (portables)

```bash
# 1) ¿Soy root ahora? (contexto de ejecución)
id -u                                    # esperado: distinto de 0

# 2) Usuario real de un proceso en marcha
ps -o user=,comm= -p <PID>               # esperado: columna user ≠ root

# 3) Usuario declarado de un contenedor (si Docker existe)
command -v docker >/dev/null 2>&1 && \
  docker inspect -f '{{.Config.User}}' <contenedor> || echo "SKIP sin docker"

# 4) Declaraciones de infraestructura as-code
grep -rnE "user:[[:space:]]*root|privileged:[[:space:]]*true|--user[[:space:]]+root" \
  --include="*.yml" --include="*.yaml" --include="*.sh" . && echo "FAIL" || echo "PASS"
```

## Alcance

Aplica a satélites, servicios de flota y scripts de despliegue del ecosistema Agent OS. No sustituye a `agent-permissions.md` (niveles L1/L2/L3 de permisos del agente): esta regla fija el piso de usuario del proceso; aquella, el alcance de acciones.
