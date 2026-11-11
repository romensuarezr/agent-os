---
name: idea-validator
description: Filtro de viabilidad objetiva para docs/idea-inbox/ con veredicto numérico 1–10 basado en prospección determinista SearXNG y scout OSS, con reglas anti-sycophancy.
---

# Skill: Idea Validator (Viabilidad Objetiva de Ideas)

Emite un veredicto numérico 1–10 sobre una idea de `docs/idea-inbox/` mediante prospección determinista ($0), neutralizando el sesgo de complacencia. Insumo advisory: la decisión soberana es la del operador en el Paso 7 del sprint-planning.

---

## 1. Cuándo Activar este Skill

- Validación de una idea en `docs/idea-inbox/` antes de proponerla en el Paso 5/7 de `sprint-planning.md`.
- Petición explícita del operador ("valida esta idea", "¿viabilidad de X?").
- NO para: decisiones de cierre de sprint, estimación de esfuerzo de tareas ya aprobadas ni sustitución de la aprobación humana.

## 2. Método de Prospección (Coste $0, Soberano)

Solo dos fuentes deterministas; prohibido LLM-judge externo, APIs comerciales y scraping de terceros:

```bash
# Demanda y competencia (SearXNG soberano)
bash scripts/agent/lib/searxng-client.sh "<consulta de demanda/competencia>"

# Alternativas OSS existentes (GitHub/npm/PyPI)
bash scripts/agent/scout.sh "<consulta de alternativas>"
```

Mínimo 1 consulta por criterio 1 y 2. Si alguna fuente falla → ese criterio se puntúa `INSUFICIENTE_DATOS` y el veredicto compuesto pasa a `INSUFICIENTE_DATOS` (nunca se puntúa en ausencia de evidencia).

## 3. Criterios Fijos de Puntuación (cada uno 1–10)

| # | Criterio | Qué se mide | Evidencia requerida |
|---|---|---|---|
| 1 | Demanda | Señales de necesidad real (resultados, discusiones, búsquedas) | ≥2 resultados con evidencia de demanda |
| 2 | Competencia / alternativas OSS | Soluciones existentes y su madurez (scout) | ≥1 fuente scout o web de contraste |
| 3 | Alineación con el hito actual | Coincidencia con `roadmap.md` y sprint activo | Referencia literal al hito |
| 4 | Esfuerzo estimado | S=8–10, M=5–7, L=1–4 (inverso) | Tamaño del alcance declarado |

`veredicto = round((c1+c2+c3+c4) / 4)` → entero 1–10. Cada criterio lleva justificación en una línea.

## 4. Reglas Anti-Sycophancy (obligatorias)

1. **Sin veredicto ≥7 sin ≥2 fuentes de contraste** independientes para los criterios 1 y 2.
2. **Evidencia negativa obligatoria**: la sección `## Hallazgos` incluye al menos un hallazgo en contra (competidor fuerte, demanda débil, riesgo). Si no existe, buscar de nuevo hasta encontrarlo o degradar el veredicto.
3. **Auto-confirmación prohibida**: no puntuar una idea en función de que el operador la haya propuesto; el número se deriva solo de la tabla de criterios.
4. **`INSUFICIENTE_DATOS` > número inventado**: ante prospección fallida o evidencia ambigua, emitir `INSUFICIENTE_DATOS` con recomendación `descartar` (o re-intento), jamás una puntuación adivinada.

## 5. Formato de Salida (Markdown insertable en el informe)

```markdown
## Hallazgos
- Demanda: <evidencia + fuente>
- Competencia/alternativas: <hallazgo scout/web>
- Contra: <al menos un hallazgo en contra>
- Alineación: <hito del roadmap citado>
- Esfuerzo: <S/M/L>

## Veredicto
| Criterio | Score (1–10) | Justificación |
|---|---|---|
| Demanda | n | <una línea> |
| Competencia | n | <una línea> |
| Alineación | n | <una línea> |
| Esfuerzo | n | <una línea> |
| **Compuesto** | **n** | round(media) |

## Recomendación
- **sprint** (≥7) | **backlog** (4–6) | **descartar** (<4 o INSUFICIENTE_DATOS)
```

## 6. Límites (declarar siempre)

- Advisory: el número es insumo; la decisión soberana es la del operador en el Paso 7 de `sprint-planning.md`.
- Solo prospección de lectura con scripts del core; sin ejecución de código de terceros ni llamadas de red fuera de `searxng-client.sh`/`scout.sh`.
- No evalúa viabilidad financiera legal ni seguridad: fuera de alcance.
- Dependencias: `scripts/agent/lib/searxng-client.sh`, `scripts/agent/scout.sh`. Sin paquetes nuevos.

## 7. Contrato de Dependencias (frontmatter `tools`)

```yaml
tools:
  - searxng-client.sh
  - scout.sh
```
