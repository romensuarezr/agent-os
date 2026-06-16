# Task-019: Soporte multi-stack documentado en lib/detect-stack.sh

## Objetivo
Documentar exhaustivamente en `scripts/agent/lib/detect-stack.sh` el flujo de detección automática de stack (Python, JS, TS), el comportamiento del override manual con `stack.env` y el diseño del componente para mejorar la universalidad y la DX del agente.

## Contexto técnico
El core de `agent-os` utiliza `lib/detect-stack.sh` para identificar dinámicamente el stack técnico de cualquier proyecto hijo. Exporta rutas, extensiones, patrones de complejidad y excepciones. Para mantener la universalidad, el script requiere documentación arquitectónica inline que detalle su API y el flujo de resolución de overrides mediante `.agents/context/stack.env`.

## Caja de archivos
Archivos autorizados para modificación:
- `scripts/agent/lib/detect-stack.sh`

## Criterios de done
- [ ] Documentación inline detallada en la cabecera de `detect-stack.sh` sobre el diseño del componente.
- [ ] Documentación inline de la lógica de detección de stack por prioridad (override de stack.env -> dependencias/carpetas).
- [ ] Documentación inline en las funciones de parsing y exportación de variables.
- [ ] Verificación de sintaxis del script bash sin errores (`bash -n`).

## Estado de aprobación
> Este bloque lo rellena el agente durante /session-start.
> No modificar manualmente.

- [ ] Plan presentado al usuario (Fase 3.5)
- [ ] APROBADO recibido — fecha/hora: ___
- [ ] Rama creada: ___
- [ ] Lock activo: ___
- [ ] Sesión cerrada correctamente
