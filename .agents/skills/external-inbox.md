---
name: external-inbox
description: Integra código externo (AI Studio, Gemini CLI, prototipos) o auditorías técnicas externas al proyecto.
---

# External Inbox Integrator

## Propósito
Facilitar la integración segura de código y hallazgos generados fuera del flujo estándar de Antigravity en {{PROJECT_NAME}}.

---

## MODO A — Integración de código externo

### Flujo de Entrada

#### 1. Pegado directo en el chat
Si el usuario pega código en el mensaje:
1. Crea automáticamente `docs/external-inbox/YYYY-MM-DD-[descripcion].md`.
2. Procede al Paso 1 del protocolo.

#### 2. Depositado en `docs/external-inbox/`
Requiere que el usuario complete el manifiesto basado en `docs/external-inbox/manifest-template.md`.

### Protocolo de Integración

#### Paso 1: Mapeo y Análisis
- Identifica qué hace el código y qué archivos del codebase actual toca o solapa.
- Verifica contra la arquitectura del proyecto (ej: DRY).

#### Paso 2: Auditoría Previa
- ¿Duplica lógica existente?
- ¿Sigue las convenciones de naming y tipado del proyecto?

#### Paso 3: Plan de Ejecución
- Presenta un plan de integración archivo por archivo.
- Si afecta a más de 3 archivos, requiere aprobación explícita del plan.

#### Paso 4: Integración y Verificación
- Integra un archivo a la vez.
- Verifica que el build/servidor no se rompa tras cada cambio.

---

## MODO B — Procesamiento de Auditorías (AUDIT-)

Se activa cuando existen archivos con prefijo `AUDIT-` en `docs/idea-inbox/` o `docs/external-inbox/audits/`.

### Protocolo de Procesamiento

1. **Inventario**: Lista todos los hallazgos con su impacto estimado.
2. **Validación**: Filtra duplicados con el `ROADMAP.md` y falsos positivos.
3. **Clasificación**: Propone el destino en el roadmap (Crítico, Alto, Medio, Bajo, Backlog).
4. **Actualización**: Tras aprobación, integra los hallazgos en el `ROADMAP.md`.

---

## Triggers
- "Tengo código para integrar en external-inbox"
- "Procesa esta auditoría de [herramienta]"
- "Añade este componente que hice en AI Studio"
