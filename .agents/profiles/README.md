# Perfiles Declarativos de Agentes — Agent OS

Este directorio define las identidades, facultades, restricciones y políticas operativas de los agentes de la flota.

---

## Esquemas de Perfil y Precedencia Canónica

Agent OS utiliza dos formatos complementarios para definir un perfil de agente:

### 1. Esquema de Control Plane (`.yaml`)
- **Propósito**: Define los límites operativos, hosts permitidos, herramientas habilitadas y niveles de inferencia para el plano de control (`.agents/config/agent-registry.yaml`, `orca-orchestrate.sh`).
- **Campos mínimos requeridos**:
  `id`, `purpose`, `allowed_tools`, `allowed_hosts`, `preferred_model_tier`, `fallback_model_tier`, `forbidden_actions`, `escalation_triggers`, `human_approval_required`.
- **Ámbito**: Orquestación estricta y gobernanza de infraestructura.

### 2. Esquema Declarativo de Agente Autónomo (`.md`)
- **Propósito**: Define el system prompt, la misión operativa, las skills permitidas/prohibidas y las compuertas de decisión que guían el razonamiento del agente durante su ciclo de vida.
- **Campos en Frontmatter YAML**:
  `name`, `role` / `role_type`, `skills` (`primary`, `forbidden`), `tooling` (`allowed`, `forbidden`), `decision_gates`.
- **Ámbito**: Razonamiento cognitivo, contexto de ejecución y decisión autónoma.

---

## Regla Canónica de Precedencia

Ante cualquier discrepancia entre ambos esquemas para un mismo rol:

1. **Límites de Infraestructura, Red y Modelos (`.yaml` prevalece)**:
   - Si un archivo `.md` intenta invocar herramientas o acceder a nodos que no figuren en `allowed_tools` o `allowed_hosts` del `.yaml` correspondiente, la política de infraestructura del `.yaml` deniega la acción.
   - El `.yaml` define el límite de seguridad perimetral innegociable.

2. **Misión, Decision Gates y Comportamiento Cognitivo (`.md` prevalece)**:
   - Las compuertas de validación humana (`decision_gates`), pautas de formulación de código y criterios de revisión definidos en el `.md` rigen el proceso reflexivo del agente durante la sesión.

3. **Registro Central**:
   - Todo perfil operativo debe estar declarado formalmente en [`agent-registry.yaml`](../config/agent-registry.yaml).
