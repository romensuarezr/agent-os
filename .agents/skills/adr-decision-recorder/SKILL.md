---
name: adr-decision-recorder
description: Captura decisiones arquitectónicas críticas usando formato ADR estándar. Se activa cuando hay trade-offs significativos en arquitectura, tecnología o estrategia de producto.
---

# ADR Decision Recorder

Esta skill estandariza la memoria arquitectónica del proyecto para que decisiones con impacto a largo plazo queden justificadas, trazables y fáciles de cargar por futuros agentes.

## Cuándo activar
- Siempre que haya trade-offs significativos entre A vs B.
- Cambios estructurales relevantes: backend, DB, auth, IA, reglas de seguridad, sincronización, despliegue.
- Decisiones que afectarán al proyecto dentro de 6 meses.

## Flujo exacto
1. **Detección**
   - El agente identifica una decisión con consecuencias a largo plazo.
   - Se pregunta: “¿Esto afectará al proyecto en 6 meses?”.
2. **Propuesta**
   - Genera en chat una propuesta ADR usando el template obligatorio.
   - Si no conoce el siguiente número, lee `docs/adrs/README.md`.
3. **Revisión bloqueante por aprobación humana**
   - El agente no escribe el ADR todavía.
   - Espera un comando explícito del usuario: `/adr-aprobar` o equivalente.
4. **Integración**
   - Solo tras aprobación:
     - Lee `docs/adrs/README.md`.
     - Calcula el nuevo ID con padding de 3 dígitos.
     - Crea `docs/adrs/ADR-[NNN]-[titulo-kebab].md`.
     - Actualiza `docs/adrs/README.md`.
     - Si sustituye a otro ADR, actualiza el anterior a `Superseded`.
     - Sugiere commit: `docs(adr): add ADR-[NNN] [titulo]`.

## Template obligatorio

```markdown
# ADR [NNN]: [Título]

**Estado:** [Proposed | Accepted | Deprecated | Superseded]
**Fecha:** [YYYY-MM-DD]
**Contexto:** [Tarea en la que se está trabajando o sprint en curso]

## Contexto
[Descripción del problema, restricciones y trade-offs]

## Decisión
[Descripción de la decisión tomada]

### Componentes Clave
1. ...

## Consecuencias

### Positivas (Pros)
* ...

### Negativas (Cons)
* ...

### Riesgos y Mitigaciones
* [Riesgo]: [Probabilidad] -> [Mitigación]

## Referencias
* ...
```

## Verificación
- El archivo debe quedar en `docs/adrs/`.
- El índice `docs/adrs/README.md` debe quedar actualizado.
- Si no hay aprobación humana, no se escribe nada.
