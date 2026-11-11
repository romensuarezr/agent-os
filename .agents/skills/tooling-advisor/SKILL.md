---
name: tooling-advisor
description: Prospección pasiva y periódica de herramientas y CLIs de la flota (OpenCode, Hermes, Orca, Infisical, Glances) mediante check-tooling-updates.sh ($0 tokens) y comprensión estructural complementaria de repositorios públicos vía DeepWiki MCP post-scout para formular propuestas técnicas estructuradas en docs/idea-inbox/ bajo el principio estricto de cero auto-ejecución.
---

# 🔭 Tooling Advisor (Prospección Pasiva de Flota y Propuestas)

Esta habilidad proporciona a los agentes de **Agent OS** un procedimiento estandarizado para auditar de forma determinista la obsolescencia o evolución de los CLIs y componentes de la flota, formulando propuestas estructuradas y redactadas en `docs/idea-inbox/`.

---

## ⛔ Principio Rector Inviolable: CERO AUTO-EJECUCIÓN

> [!CAUTION]
> **La habilidad `tooling-advisor` es estrictamente consultiva y propositiva.**  
> - **TERMINANTEMENTE PROHIBIDO** ejecutar actualizaciones desatendidas, instalaciones de binarios o modificaciones de paquetes en el sistema (`npm update`, `npm install -g`, `pip install --upgrade`, `git pull` en dependencias, `curl ... | bash`, etc.).  
> - **Única salida autorizada**: redacción de documentos de propuesta en `docs/idea-inbox/YYYY-MM-DD-<slug>.md` en estado `💡 REGISTRADA, NO APROBADA`.  
> - La decisión final de actualizar, descartar o postergar cualquier herramienta pertenece de forma soberana al operador humano o al consenso sellado en sprint planning.

---

## 🎯 Cuándo Usar Esta Habilidad

- **Rituales de Sprint Planning**: Durante la prospección scout de tooling para evaluar qué versiones de CLIs o motores están disponibles upstream.
- **Consultas del operador**: Cuando el usuario pregunte "¿qué herramientas tienen actualizaciones pendientes?" o "¿qué novedades hay en OpenCode / Hermes / Orca?".
- **Revisiones periódicas de gobernanza**: Para auditar la obsolescencia técnica de la flota sin consumir tokens de inferencia en la fase de descubrimiento.

---

## ⚙️ Protocolo Operativo Paso a Paso

```
┌─────────────────────────────────┐
│ check-tooling-updates.sh --json │  ──▶ Descubrimiento determinista ($0 tokens)
└────────────────┬────────────────┘
                 │
                 ▼
     ¿Hay versiones nuevas?
        ├── NO  ──▶ Informar "Flota al día" y finalizar
        │
        └── SÍ  ──▶ Prospección de changelog redactado (filtro anti-volcados)
                         │
                         ▼
             Generar propuesta formal en:
             docs/idea-inbox/YYYY-MM-DD-<slug>.md
             (💡 REGISTRADA, NO APROBADA)
```

### Paso 1: Ejecución Determinista de la Sonda ($0 Tokens)
Ejecuta la sonda local oficial para consultar los registros upstream con timeout breve (≤5s) y captura fail-soft:

```bash
# Diagnóstico de toda la flota en formato estructurado
bash scripts/agent/check-tooling-updates.sh --json

# O filtrando por una herramienta específica
bash scripts/agent/check-tooling-updates.sh --tool opencode --json
```

Si la sonda reporta `updates_available_count: 0`, informa al operador que todas las herramientas monitoreadas se encuentran en su última versión estable y detén el flujo.

### Paso 2: Análisis Cualitativo y Filtro Anti-Volcados
Si una o más herramientas presentan `update_available: true`:
1. Identifica la herramienta, la versión instalada/declarada y la versión upstream.
2. Consulta el changelog o notas de la versión en el repositorio oficial o registro.
3. **Filtro Estricto de Contexto**:
   - ❌ **PROHIBIDO** volcar el markdown completo de releases o changelogs crudos extensos en la propuesta.
   - ✅ **OBLIGATORIO** sintetizar en 3-5 puntos clave:
     - Nuevas capacidades o comandos relevantes para Agent OS.
     - Correcciones de seguridad o bugs críticos.
     - Breaking changes o cambios en flags CLI.
     - Impacto operativo estimado (alto, medio, bajo).

### Paso 2.5: Comprensión Estructural Profunda con DeepWiki MCP (Fuente Secundaria Post-Scout)
Cuando se requiera comprender cómo una herramienta de código abierto implementa un patrón técnico o subsistema complejo sin clonar su repositorio completo en disco local, el agente puede apoyarse de forma complementaria en **DeepWiki MCP** (`https://mcp.deepwiki.com/mcp`, declarado en `.agents/config/fleet.example.yaml`):

1. **Gate Previo Scout-First**:
   - DeepWiki consume tokens de contexto y opera sobre una wiki generada en el momento de indexación.
   - Es estrictamente **posterior** al cribado determinista inicial con `scout.sh` o `check-tooling-updates.sh` ($0 tokens).
2. **Tres Guardarraíles Vinculantes**:
   - 🛡️ **Seguridad fail-closed (Repositorios Públicos Exclusivamente)**:
     - Queda **TERMINANTEMENTE PROHIBIDO** indexar o consultar repositorios que contengan credenciales privadas, secretos o código propietario interno. Su uso está acotado con exclusividad a repositorios públicos de código abierto.
   - 🔍 **Verdad Arquitectónica (HEAD First / Contraste Obligatorio)**:
     - DeepWiki es una **fuente secundaria**. Como la wiki puede sufrir deriva temporal frente al código fuente vivo, **toda conclusión, interfaz o patrón inferido debe contrastarse obligatoriamente contra el árbol real (HEAD de Git o descarga de archivos fuente específicos)** antes de ser aceptado en una propuesta técnica o diseño de sprint.
   - ⛔ **Cero Auto-Ejecución**:
     - Las conclusiones derivadas de DeepWiki sirven exclusivamente como insumo de comprensión para enriquecer la propuesta en `docs/idea-inbox/`. Nunca habilitan cambios de configuración ni despliegues desatendidos.

### Paso 3: Redacción de la Propuesta en `docs/idea-inbox/`
Crea un archivo nuevo siguiendo la convención de nomenclatura:
`docs/idea-inbox/YYYY-MM-DD-<herramienta>-v<version>.md`

La propuesta debe utilizar obligatoriamente la plantilla canónica a continuación.

---

## 📄 Plantilla Canónica de Propuesta (`docs/idea-inbox/`)

```markdown
# Idea: Actualización de [Nombre Herramienta] a v[X.Y.Z]

- **Fecha:** YYYY-MM-DD
- **Origen:** Sonda determinista check-tooling-updates.sh (T-174 / tooling-advisor).
- **Estado:** 💡 REGISTRADA, NO APROBADA
- **Tipo:** Tooling / Evolución de Flota.

## QUÉ (tareas para el planning, no el cómo)

1. **Evaluar compatibilidad:** Validar si la nueva versión introduce cambios en flags o configuración que afecten a la flota.
2. **Actualizar inventario:** Actualizar `.agents/config/fleet.yaml` y `.agents/config/fleet.example.yaml` con la nueva versión una vez aprobada.
3. **Verificar control plane:** Comprobar que la suite `tests/validate-control-plane.sh` permanece en 38/38 tras la actualización.

## Por qué (Justificación y Novedades Relevantes)

- **Versión actual**: [vX.Y.A]
- **Nueva versión upstream**: [vX.Y.Z] (vía [npm | GitHub | PyPI])
- **Síntesis de cambios clave** (extracto redactado, sin volcados crudos):
  - [Novedad 1 relevante para el sistema]
  - [Fix de estabilidad o seguridad]
  - [Compatibilidad o breaking change identificado]

## Impacto Estimado

- **Riesgo**: [Bajo | Medio | Alto]
- **Ámbito**: [Host local | Nodo de inferencia | Nodo de orquestación]
- **Coste de tokens**: $0 (inspección previa determinista).

## Hechos de entrada (verificados)

- Registro verídico upstream verificado con éxito vía `check-tooling-updates.sh`.
- Binario actual funcional en la flota.
- No existen dependencias rotas detectadas en el pre-flight.

## Descartado con motivo / Fuera de alcance

- Aplicar la actualización de forma desatendida o automática (violación de gobernanza).
- Modificar configuraciones en caliente sin validación previa del operador.
```

---

## 🛡️ Guardarraíles y Frontera Portable

1. **Higiene de localizadores (Check 22)**:
   - Prohibido incluir rutas absolutas personales (`/home/<usuario>/...`) o direcciones IP privadas en las propuestas o reportes.
   - Utilizar siempre placeholders canónicos (`<nodo-inferencia>`, `<nodo-orquestacion>`, etc.).
2. **Compatibilidad Multiplataforma**:
   - La sonda y la skill operan de forma agnóstica entre Linux y macOS.
3. **Sin Regresiones en Control Plane**:
   - Todo cambio o propuesta debe preservar el denominador inmutable de **38/38** en `tests/validate-control-plane.sh`.
