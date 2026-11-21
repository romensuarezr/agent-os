# Runbook: Despliegue y Gobernanza de Orca Bot Identities (v1.4.268)

Este runbook describe el protocolo operativo determinista ($0 tokens) para proyectar los perfiles declarativos de Agent OS hacia el subsistema nativo de bots de **Orca IDE** (v1.4.268).

---

## 1. Arquitectura de Identidad de Orca Bots

Orca v1.4.268 estructura a cada bot sobre tres artefactos clave:
- **`IDENTITY.md`**: Tarjeta de presentación (ID, rol, emoji, vibe técnico y protocolo).
- **`SOUL.md`**: Propósito en una frase, sección `## How I work` (contratos operativos) y `## Never` (restricciones duras).
- **`MEMORY.md`**: Contexto estático del stack de desarrollo, comandos frecuentes de testing/build y reglas activas.
- **`abilities`**: Habilidades disponibles ubicadas en `.agents/skills/`.
- **`tools`**: Servidores MCP asociados directamente al bot.

---

## 2. Generación Determinista de Artefactos

Para proyectar los perfiles del core (`coder`, `coordinator`, `qa-judge`, `docs-researcher`) a Orca:

```bash
# Simular proyección (dry-run)
bash scripts/agent/setup-profiles.sh --orca-bots --check

# Aplicar proyección en .agents/profiles/orca-bots/
bash scripts/agent/setup-profiles.sh --orca-bots --apply
```

Estructura generada:
```
.agents/profiles/orca-bots/
├── coder/
│   ├── IDENTITY.md
│   ├── SOUL.md
│   └── MEMORY.md
├── coordinator/
│   ├── IDENTITY.md
│   ├── SOUL.md
│   └── MEMORY.md
├── docs-researcher/
│   ├── IDENTITY.md
│   ├── SOUL.md
│   └── MEMORY.md
└── qa-judge/
    ├── IDENTITY.md
    ├── SOUL.md
    └── MEMORY.md
```

---

## 3. Integración en Orca IDE (ADE)

### 3.1 Listar bots registrados
```bash
orca bot list --json
```

### 3.2 Crear o importar un bot desde Agent OS
Dentro de Orca IDE, puedes crear el bot interactivamente o utilizar el plan de importación:

```bash
# Proponer la creación interactiva de un bot en el chat del operador
orca bot create --json

# Importar bot reconociendo la fuente existente sin filtrar secretos
orca bot import sources --json
```

### 3.3 Conectar Servidores MCP (Tools) al Bot
```bash
# Asociar un servidor MCP al bot (ej. SearXNG)
orca bot tools add --bot "docs-researcher" --name "searxng" --url "http://localhost:8080/mcp"

# Inspeccionar herramientas activas del bot
orca bot tools --bot "docs-researcher" --json
```

---

## 4. Inyección de Standing Instructions en OpenCode y Hermes

Cuando un worker o bot es instanciado en Orca con runtime OpenCode o Hermes:

1. **Soul como System Prompt Primario**: El contenido de `SOUL.md` rige el tono, el lenguaje (español en explicaciones, inglés en código) y las prohibiciones (cero push directo a main).
2. **Memory como Grounding de Stack**: El contenido de `MEMORY.md` informa de inmediato los comandos deterministas para ejecutar pruebas (`npm test`, `pytest`, `cargo test`, etc.) sin tener que explorar a ciegas.
3. **Abilities**: Las skills de `.agents/skills/` se montan como capacidades operativas nativas.

---

## 5. Higiene y Seguridad de Frontera

- **Cero Secretos**: Los archivos `IDENTITY.md`, `SOUL.md` y `MEMORY.md` **nunca** deben incluir contraseñas, tokens de API o rutas privadas de usuario.
- **Principio de Sala Limpia**: Todo artefacto generado es reproducible deterministamente mediante `setup-profiles.sh --orca-bots --apply`.
- **Prevención de Colisión**: Recordar siempre que en distribuciones Linux no debe ejecutarse `/usr/bin/orca` directamente para evitar invocar el lector de pantalla GNOME.
