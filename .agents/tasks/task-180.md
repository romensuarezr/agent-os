# Task-180: DeepWiki MCP como fuente secundaria de comprensión estructural profunda post-scout en tooling-advisor

## Objetivo
Formalizar la integración de DeepWiki MCP como fuente secundaria y desacoplada de comprensión estructural profunda de repositorios públicos en la skill canónica `.agents/skills/tooling-advisor/SKILL.md`, estableciendo guardarraíles estrictos de seguridad y contraste obligatorio contra el árbol real (HEAD).

## Contexto técnico
La propuesta `docs/idea-inbox/2026-11-09-deepwiki-complemento-scout.md` identificó a DeepWiki MCP (`https://mcp.deepwiki.com/mcp`) como herramienta para analizar cómo un proyecto de código abierto resuelve un patrón sin necesidad de clonarlo localmente. A diferencia de `scout.sh` (que opera a coste $0 de inferencia consultando APIs oficiales de GitHub/NPM/PyPI), DeepWiki consume tokens de contexto y consulta una wiki generada en el momento de indexación, por lo que su modo de fallo es la deriva temporal frente al código vivo.

## Diseño macro aprobado en planning
> Registro vinculante del diseño acordado entre el humano y el agente durante el sprint planning.
> El Revisor Ejecutor audita el plan técnico contra esta sección: cualquier desviación gatilla ESCALADO_A_HUMANO.

- **Sprint / Fecha**: Sprint 32 / 2026-11-10
- **Diseño y arquitectura aprobados por**: Humano (Operador)
- **Decisiones e interfaces selladas**:
  - Incorporar DeepWiki MCP en la skill `.agents/skills/tooling-advisor/SKILL.md` como herramienta complementaria de segunda fase tras el cribado determinista inicial con `scout.sh`.
  - Guardarraíl de seguridad: Exclusivo para repositorios públicos; terminantemente prohibido indexar o consultar repositorios con credenciales privadas.
  - Guardarraíl de verdad arquitectónica: DeepWiki es **fuente secundaria**. Sus conclusiones deben contrastarse siempre contra el árbol real (HEAD o archivos descargados puntuales) antes de considerarlas válidas para planes de sprint o código de producción.
  - Guardarraíl operativo: Se ratifica el principio estricto de **CERO auto-ejecución** de la skill `tooling-advisor`: toda recomendación derivada se formula en propuestas estructuradas para `docs/idea-inbox/`.
  - Registrar la entrada canónica del endpoint de DeepWiki en `.agents/config/fleet.example.yaml`.
- **Veredicto de diseño macro**: `[APROBADO_EN_PLANNING]`

## Caja de archivos
Archivos autorizados para modificación:
- `.agents/skills/tooling-advisor/SKILL.md`
- `.agents/config/fleet.example.yaml`
- `.agents/tasks/task-180.md`

## Criterios de done
- [ ] `.agents/skills/tooling-advisor/SKILL.md` formaliza el protocolo de uso de DeepWiki MCP como complemento post-scout.
- [ ] Guardarraíles de contraste obligatorio contra HEAD, restricción a repos públicos y cero auto-ejecución explícitamente sellados en la skill.
- [ ] Configuración del servidor DeepWiki MCP registrada en `.agents/config/fleet.example.yaml`.
- [ ] Suite de pruebas `tests/validate-control-plane.sh` 38/38 en verde.
- [ ] `locator-hygiene.sh` 100% limpio.

## Estado de aprobación y deliberación
> Este bloque lo rellena el agente durante /session-start y cierre de tarea.
> No modificar manualmente.

- [ ] Deliberación técnica completada (`deliberate-plan.sh`)
  - **Veredicto del revisor**: `[CONSENSO | REVISADO_CON_CAMBIOS | ESCALADO_A_HUMANO | SIN_REVISOR]`
  - **Rol del revisor**: Compuerta técnica determinista (caja de archivos, tests, realidad repo, fidelidad a diseño macro).
- [ ] Plan presentado al usuario (Fase 3.5)
- [ ] APROBADO recibido — fecha/hora: ___
- [ ] Rama creada: ___
- [ ] Lock activo: ___
- [ ] Sesión cerrada correctamente
