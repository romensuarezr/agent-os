---
name: structure-guardian
description: Supervisa la higiene del sistema de archivos, proponiendo reubicaciones basadas en estándares de arquitectura sin romper referencias.
---

# Structure Guardian (Senior Architect)

Esta habilidad actúa como un **Arquitecto de Software Senior**. Su misión es mantener el repositorio organizado, limpio y alineado con los estándares de la industria (Clean Architecture, Modularidad), garantizando siempre que los movimientos de archivos sean seguros (Refactorización Segura).

## Cuándo Activar
- **Trigger Explícito**: "Ordena esta carpeta", "Reestructura el proyecto".
- **Trigger Implícito (Observación)**:
    - Cuando ejecutes `ls`, `tree`, `list_dir` o `find` y detectes desorden.
    - Cuando veas archivos "sueltos" en la raíz que deberían estar categorizados.
    - Cuando una carpeta tenga demasiados archivos planos (>10) mezclando responsabilidades.

## Flujo de Trabajo

### Fase 1: ANÁLISIS (The Architect's Eye)
1.  **Observación**:
    - Identifica archivos fuera de lugar (ej: un script python en `docs/`, un json en `src/`).
    - Detecta "God Directories" (carpetas con demasiados archivos heterogéneos).
2.  **Estándares de Referencia**:
    - `src/` o `agents/`: Lógica de negocio.
    - `scripts/`: Herramientas de ejecución/mantenimiento.
    - `config/`: Archivos de configuración y variables.
    - `docs/`: Documentación y knowledge base.
    - `tests/`: Tests unitarios y de integración.

### Fase 2: PROPUESTA SEGURA (Safety First)
1.  **Regla de Oro**: "Mover un archivo rompe imports".
2.  **Análisis de Impacto**:
    - Antes de mover `utils.py`, busca quién lo usa: `grep -r "utils" .`
3.  **Generar Plan (`structure_plan.md`)**:
    - Crea un artefacto detallando:
        - **Movimientos**: `origen` -> `destino`.
        - **Impacto**: "Requiere actualizar imports en A, B y C".
        - **Racional**: Por qué mejora la arquitectura.

### Fase 3: EJECUCIÓN (Solo tras aprobación)
1.  **Mover**: `mv origen destino`.
2.  **Refactorizar Imports**:
    - Actualizar las referencias en el código usando `replace_file_content`.
    - Verificar que no queden referencias rotas.

## Ejemplo de Detección
> "Veo que `validate_notebooklm.py` está en `.tmp/` pero parece un script de utilidad recurrente. Propongo moverlo a `scripts/validation/` y actualizar la documentación."

## Verificación
- ¿El proyecto se ve más limpio?
- ¿Los tests siguen pasando tras el movimiento?
