---
name: skill-inspector
description: Escáner estático determinista para auditar la seguridad, higiene y confianza de las habilidades (.agents/skills) mediante patrones de NVIDIA SkillSpector (Stage 1).
---

# Skill: Skill Inspector (Auditoría Estática de Seguridad en Skills)

Proporciona auditoría de seguridad estática, confianza e higiene para el catálogo de habilidades (`.agents/skills/`) de Agent OS. Está basado en una adaptación determinista de los patrones de Stage 1 de **NVIDIA SkillSpector**, ejecutándose 100% en local, sin consumo de tokens (sin LLM) y sin dependencias externas pesadas.

---

## 1. Cuándo Activar este Skill

- **Creación o edición de skills**: Antes de dar por finalizada una nueva habilidad o modificar una existente.
- **Validación de seguridad en CI / Pre-commit**: Como barrera de control (*quality gate*) para evitar inyecciones o código peligroso.
- **Auditoría periódica de flota**: Al sincronizar habilidades entre el core y proyectos satélite vía `sync.sh` o `install.sh`.
- **Invocación explícita**: Peticiones como *"audita las skills"*, *"analiza la seguridad de la skill X"* o `bash scripts/agent/inspect-skills.sh`.

---

## 2. Invocación y Parámetros CLI

El motor determinista se encuentra en `scripts/agent/inspect-skills.sh`:

```bash
# Escaneo completo del catálogo local con salida visual interactiva
bash scripts/agent/inspect-skills.sh

# Escaneo de una skill específica
bash scripts/agent/inspect-skills.sh --path .agents/skills/remote-admin

# Salida estructurada en JSON para pipelines y CI
bash scripts/agent/inspect-skills.sh --json

# Uso de un archivo de baseline alternativo
bash scripts/agent/inspect-skills.sh --baseline path/to/custom-baseline.json
```

---

## 3. Familias de Patrones Estáticos y Severidades

El escáner discrimina las amenazas en 4 familias de seguridad de alta señal y una categoría independiente de higiene estructural:

| Familia | Descripción | Severidad | Bloquea Gate |
| :--- | :--- | :---: | :---: |
| **`PROMPT_INJECTION`** | Evasión de directivas de seguridad, intentos de forzar modo sin restricciones (jailbreak/unrestricted mode) o inyección de etiquetas de rol de sistema (&lt;system&gt;). | `CRITICAL` / `HIGH` | Sí (exit 1) |
| **`DATA_EXFILTRATION`** | Envío de variables de entorno, claves o credenciales en cargas HTTP hacia URLs externas, volcados de entorno a red (env canalizado a curl/wget), o sockets crudos netcat a IPs. | `CRITICAL` / `HIGH` | Sí (exit 1) |
| **`DANGEROUS_CODE`** | Descarga y ejecución remota ciega (canalización curl hacia intérprete bash sin verificación), comandos destructivos sobre raíz (rm -rf /), fork bombs, código ofuscado o eval dinámico no saneado. | `CRITICAL` / `HIGH` | Sí (exit 1) |
| **`MCP_POISONING`** | Directivas que intentan suplantar o interceptar llamadas a herramientas MCP o forzar la omisión de confirmación humana obligatoria en acciones de riesgo. | `HIGH` | Sí (exit 1) |
| **`SKILL_HYGIENE`** | Integridad del archivo `SKILL.md`: presencia de archivo no vacío, delimitadores frontmatter `---`, y metadatos obligatorios `name` y `description`. | `LOW` | No (exit 0) |

---

## 4. Gate de Severidad y Códigos de Salida

El gate de severidad está activo por defecto para garantizar que ninguna vulnerabilidad crítica o de alto impacto se introduzca inadvertidamente:

- **Exit Code `0` (Conforme ✅)**:
  - No existe ningún hallazgo `CRITICAL` o `HIGH` activo (o todos los existentes están debidamente suprimidos en el baseline).
  - Los hallazgos de severidad `LOW` (como avisos de formato o higiene) o `MED` **nunca bloquean** la ejecución.
- **Exit Code `1` (Bloqueado ❌)**:
  - Se detectó al menos un hallazgo de severidad `CRITICAL` o `HIGH` no suprimido.
  - El pipeline o proceso debe detenerse hasta corregir el archivo o justificar el falso positivo en el baseline.
- **Exit Code `2` (Error de CLI ⚠️)**:
  - Argumentos inválidos en la línea de comandos, sintaxis errónea o directorio objetivo no existente.

---

## 5. Algoritmo de Puntuación (Scoring 0–100)

Cada skill comienza con una puntuación base de **100 puntos**. Se aplican deducciones exclusivamente sobre hallazgos **no suprimidos**:
- `CRITICAL`: -40 puntos
- `HIGH`: -20 puntos
- `MED`: -10 puntos
- `LOW`: -5 puntos

La puntuación mínima está acotada en **0**. La puntuación global del catálogo es el promedio aritmético de las puntuaciones individuales.

---

## 6. Mecanismo de Supresión por Baseline

Para evitar alertas repetitivas y falsos positivos en skills operativas de bajo nivel (por ejemplo, herramientas de gestión de infraestructura que documentan comandos de administración legítimos), el escáner utiliza un archivo de baseline (`.agents/skills/skill-inspector/baseline.json`).

### Formato de `baseline.json`:
```json
{
  "version": "1.0.0",
  "updated_at": "2026-09-30T12:00:00Z",
  "description": "Baseline de hallazgos justificados en el catálogo de Agent OS",
  "suppressions": [
    {
      "fingerprint": "infisical-secrets:DANGEROUS_CODE:SKILL.md:CODE_BLIND_EVAL",
      "skill": "infisical-secrets",
      "category": "DANGEROUS_CODE",
      "rule_id": "CODE_BLIND_EVAL",
      "severity": "HIGH",
      "reason": "Uso documentado de eval para inyección efímera de variables de entorno desde CLI.",
      "approved_by": "core-reviewer",
      "approved_at": "2026-09-30"
    }
  ]
}
```

### Regla para Añadir una Supresión:
1. Verifica que el hallazgo es genuinamente un uso seguro, documentado o intencional.
2. Copia el `fingerprint` exacto emitido por `inspect-skills.sh` (`skill:CATEGORY:file:RULE_ID`).
3. Añade la entrada al archivo de baseline con un `reason` descriptivo y fecha de aprobación.
4. Vuelve a ejecutar el escáner: el hallazgo se reportará como `⚪ [SUPPRESSED]`, su penalización será de 0 puntos y no bloqueará el gate.
