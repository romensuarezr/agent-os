# Task-021: Mejoras de DX del agente (mensajes de error claros y guías inline)

## Objetivo
Mejorar la experiencia de desarrollo (DX) del agente en Agent OS proporcionando mensajes de error y advertencia (warnings) más claros y detallados con colores ANSI en caso de fallo, mientras que los mensajes de éxito e información se mantienen en texto plano para evitar riesgos en entornos no interactivos.

## Contexto técnico
- Los scripts en `scripts/agent/` automatizan tareas críticas como comprobar la sesión, el sprint, sincronizar y cerrar tareas.
- Actualmente, algunos scripts no manejan errores de forma lo suficientemente descriptiva o usan colores ANSI para todo.
- Restricción del usuario: los colores ANSI SOLO deben usarse en mensajes de ERROR y WARNING. Los mensajes de éxito e información deben ser en texto plano.

## Caja de archivos
Archivos autorizados para modificación:
- `scripts/agent/check-session.sh`
- `scripts/agent/check-sprint.sh`
- `scripts/agent/close-task.sh`
- `scripts/agent/close-sprint.sh`
- `scripts/agent/install.sh`
- `scripts/agent/sync.sh`

## Criterios de done
- [x] Implementar colores ANSI en mensajes de ERROR y WARNING en los scripts autorizados.
- [x] Asegurar que los mensajes de éxito (`success`, `ok`, etc.) e información (`info`, `status`, etc.) se emiten en texto plano.
- [x] Mejorar la claridad y asertividad de los mensajes de error, añadiendo guías de resolución rápida inline.
- [x] Verificar el comportamiento local ejecutando los scripts.
- [x] Compilación/Verificación sin errores.

## Estado de aprobación
- [x] Plan presentado al usuario (Fase 3.5)
- [x] APROBADO recibido — fecha/hora: 2026-06-16T13:13:20+01:00
- [x] Rama creada: feat/T-021-agent-dx-improvements
- [x] Lock activo: .agent-session.lock
- [x] Sesión cerrada correctamente
