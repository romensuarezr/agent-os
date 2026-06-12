# Rule: No Destructive Without Audit

> El agente NUNCA ejecuta operaciones destructivas sin confirmación y auditoría de impacto.

## Protocolo Obligatorio

Antes de ejecutar `rm`, `deleteDoc`, `git reset --hard`, o purgas de datos:

1. **Listar Impacto**: Enumera exactamente qué archivos, registros o ramas serán afectados.
2. **Confirmación Explícita**: Espera a que el usuario diga "sí, elimina" o equivalente. No asumas aprobación por silencio.
3. **Verificación Post-Acción**: Tras la operación, muestra el estado resultante para confirmar que no hubo daños colaterales.

## Ámbito
- Sistemas de archivos (`rm`, `mv`).
- Bases de datos (Firestore, SQL).
- Control de versiones (Git).
- Configuraciones críticas (Cloud rules, infra).
