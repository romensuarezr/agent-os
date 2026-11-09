# Idea: DeepWiki como complemento de scout.sh (comprensión profunda de repos)

- **Fecha:** 2026-11-09
- **Origen:** Análisis externo traído por el usuario (2026-11-09),
  depurado y verificado por el relé (búsqueda web + repo, 2026-11-09).
- **Estado:** 💡 REGISTRADA, NO APROBADA
- **Tipo:** Tooling / Investigación (complemento del motor de búsqueda).

## QUÉ (tareas para el planning, no el cómo)

1. **Añadir DeepWiki como fuente de comprensión profunda:** tras el
   descubrimiento a $0 de scout.sh, usar DeepWiki MCP para entender
   cómo implementa un repo concreto una funcionalidad, sin clonarlo.
2. **Decidir el registro:** dónde vive un servidor MCP remoto
   (¿`.agents/config/fleet.yaml` con formato nuevo `url`, o config
   propia de cada CLI?) — hoy el bloque `mcpServers` solo tiene
   entradas stdio (`command`/`args`/`env`).
3. **Regla de uso:** DeepWiki es fuente secundaria: sus respuestas
   vienen de una wiki generada en el momento de indexar, no del HEAD
   del repo; todo lo que diga se contrasta contra el repo real antes
   de entrar en un plan (lección Bane).

## Hechos de entrada (verificados)

- DeepWiki existe (Cognition, autores de Devin): MCP gratuito sin
  autenticación para repos públicos en https://mcp.deepwiki.com/mcp
  (streamable HTTP; /sse legacy). Tres herramientas:
  `read_wiki_structure`, `read_wiki_contents` y la de preguntas, que
  en la documentación se llama `ask_question` y en el servidor vivo
  `ask_wiki_question` (el nombre cambió; descubrir en vivo, no
  fijarlo desde la documentación).
- Las respuestas vienen de una wiki generada al indexar, no del HEAD:
  la deriva de versión es el modo de fallo.
- No sustituye a scout.sh: scout descubre y filtra a $0 (GitHub/NPM);
  DeepWiki explica implementación (consume tokens de prompt).
- Solo repos públicos en el tier gratuito; repos privados exigen
  cuenta Devin con GitHub conectado.
- El repo de Orca es `stablyai/orca` (`onorca.dev` es la web, no el
  repo) — el análisis traído citaba `onorca/orca`, erróneo.
- En agent-os no hay ninguna mención a DeepWiki; el bloque
  `mcpServers` existe en `.agents/config/fleet.example.yaml` con
  formato stdio; la ruta `config/fleet.yaml` del análisis está
  deprecada (la canónica es `.agents/config/fleet.yaml`).

## Preguntas abiertas (las decide el planning)

- ¿Entra como fuente del skill tooling-advisor (T-174) o como pieza
  aparte?
- ¿Registro en fleet.yaml (ampliando el esquema a remoto) o en la
  config propia de cada CLI (opencode.json, etc.)?
- ¿Límites de uso (solo en planning/scout, nunca en implementación)
  para no quemar tokens?

## Fuera de alcance

- Sustituir scout.sh ni el workflow deep-research (SearXNG).
- Indexar repos privados con DeepWiki (fuera del tier gratuito).
- Enmendar el Sprint 31 para meterlo: idea para que el planning la
  moldee (siguiente sprint o T-174 si el planning lo decide).
