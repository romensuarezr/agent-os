# Research Sprint 14 — Automejora y Confianza

> **Fuente**: Perplexity / Investigación técnica validada — 2026-09-30  
> **Tareas impactadas**: T-091 (Destilación de automejora), T-093 (Port estático de SkillSpector) y T-097 (Inferencia resiliente $0 para Hermes)

---

## 1. Patrones de Detección Estática de SkillSpector (NVIDIA)

### Pipeline en dos etapas:

1. **Stage 1 (Estático, siempre activo — objetivo de nuestro port determinista)**:
   - **Analizadores**: 11 analizadores con matching regex, análisis de comportamiento por AST de Python (detecta `exec`, `eval`, `subprocess` y llamadas peligrosas), firmas YARA, y lookups de CVEs vía OSV.dev (con fallback offline si no hay red).
   - **Cobertura**: 71 patrones en 17 categorías:
     - Prompt injection
     - Data exfiltration
     - Privilege escalation
     - Supply chain
     - Excessive agency
     - Output handling
     - System prompt leakage
     - Memory poisoning
     - Tool misuse
     - Rogue agent
     - Anti-refusal
     - Trigger abuse
     - Dangerous code (AST)
     - Taint tracking
     - YARA signatures
     - MCP least privilege
     - MCP tool poisoning
   - **Higiene de ingesta**: Rechaza symlinks, apertura de ficheros sin seguir enlaces, límites en archivos anidados (miembros/bytes/profundidad), tope de 100 MiB por ingesta y 1 MB por fichero analizado; si se supera un límite, falla cerrado.

2. **Stage 2 (LLM, opcional — OMITIDO en Agent OS Core)**:
   - Evalúa contexto e intención, filtra falsos positivos y eleva la precisión al ~87% (el estático solo tiene alto recall pero precisión moderada).
   - **Restricción Agent OS**: Prohibido el uso de LLM en el core para mantener cero consumo de tokens y determinismo offline.

### Evidencia Empírica Clave (Liu et al., 2026):
- Las skills con scripts ejecutables tienen **2.12x más probabilidad de ser vulnerables**.
- El 26.1% de 31.132 skills analizadas contenían vulnerabilidades y el 5.2% intención probablemente maliciosa.
- Las skills de Agent OS contienen scripts bash y markdown estructurado, por lo que disponer de un escáner estático propio aporta un valor crítico de seguridad y confianza a la flota.

---

## 2. Scoring 0–100 y Criterios de Discriminación

- **Escala**: 0–100 con etiquetas de severidad (`CRITICAL`, `HIGH`, `MED`, `LOW`) y recomendación accionable por skill.
- **Modelo de referencia en CI**: Modo blocker que falla el check ante cualquier hallazgo `HIGH` o `CRITICAL` no suprimido. En entornos de producción se utiliza un umbral ≤25/100 como gate de release.
- **Baseline de supresión**:
  - Los hallazgos aceptados o justificados se excluyen del score mediante un archivo de baseline.
  - Los re-escaneos solo penalizan hallazgos nuevos, garantizando que el score refleje riesgo no triado y evitando fatiga por ruido histórico.
- **Señal para Skills Markdown+Bash**: Las categorías con mayor ratio señal/ruido para nuestro ecosistema son:
  1. *Prompt injection*
  2. *Data exfiltration*
  3. *Dangerous code / Subprocess abuse*
  4. *MCP tool poisoning*

---

## 3. Destilación de Procedimientos en Frameworks Modernos (Mapeo a T-091)

| Framework | Patrón Implementado | Equivalencia en Agent OS (T-091) |
| :--- | :--- | :--- |
| **Reflexion** (Shinn et al.) | Convierte trayectorias de fallo en feedback verbal en memoria episódica para el siguiente intento. | **Draft → Humano**: El feedback y las propuestas generadas requieren confirmación explícita para consolidarse en el árbol principal. |
| **Voyager** (MineDojo) | Destila la experiencia de exploración en una librería de skills invocables que se acumula con el tiempo. | **Live-Capture**: El procedimiento multi-paso exitoso se destila a skill/regla/runbook versionado, no a una nota informal. |
| **MemGPT / Letta** | Memoria jerárquica con *sleeptime curation*: agente que edita bloques de memoria tras turnos con directiva *"be selective in memory editing, but aim for high recall"* y *access reinforcement*. | **Paso de Reflexión en `session-close` + Umbral 3x**: Evaluación al cierre y consolidación de patrones que ocurren 3+ veces para evitar proliferación de ruido. |
| **Agent Foundry** | *Retrospective*: edición sobre documentos vivos existentes (`core_memory_replace`). | **Retrospective sin silos**: Modificar reglas, runbooks y contratos existentes en caliente, **prohibiendo crear silos muertos** de "lecciones aprendidas". |

### Hueco en el Ecosistema y Ventaja de Agent OS:
La literatura destaca que la principal carencia de los frameworks multi-agente actuales es la falta de **aprendizaje organizacional** (*"agents don't learn from each other"*). En Agent OS, este problema se resuelve arquitectónicamente:
- La regla se versiona en el **core** (`.agents/rules/`).
- Se distribuye deterministamente a toda la flota satélite vía `install.sh` y `sync.sh`.

---

## 4. Arquitectura de Inferencia Resiliente: Free-Tier LLM Gateway (T-097)

### Topología en 3 Niveles:
1. **Nivel 1: Cloud Free Proxies**: FreeLLMAPI (`<TAILSCALE_IP>:3001/v1`) y OmniRoute (`<TAILSCALE_IP>:20128/v1`). Retorno inmediato bajo 200 OK; ante 429/403/timeout, apertura de circuito con cooldown de 5 min.
2. **Nivel 2: OpenRouter Free strictly isolated**: Model whitelisting con regex estricto `^.*:free$`. Ante 429/402/403, trip circuit hasta reseteo de cuota a las 00:00 UTC.
3. **Nivel 3: Ollama Local GGUF (`127.0.0.1:11434`)**: Garantía determinista in-host (`qwen2.5:7b` / `llama3.1:8b`).

### Checklist Técnico para Agentes Headless:
- **Bind de red**: Servicios que escuchan en el VPS deben enlazar la IP de Tailscale (`<TAILSCALE_IP>`, definida en el overlay gitignored `.agents/config/fleet.yaml`) o `0.0.0.0`, nunca exclusivamente `127.0.0.1`.
- **Eliminación de endpoints temporales**: Sustituir túneles efímeros `*.trycloudflare.com` por rutas canónicas en la malla privada de Tailscale (`http://<TAILSCALE_IP>:<puerto>`).
- **Inyección segura en memoria vía Infisical**: Cero almacenamiento de claves en archivos `.env` o comandos en claro.


