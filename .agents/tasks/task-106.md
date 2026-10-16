# Task-106: Saneado de exposición de infraestructura en romensuarez-web

## Objetivo
Sanear las 21 violaciones de frontera portable en el repo real `~/orca/workspaces/romensuarez-web/limpet`
(`romensuarezr/romensuarez-web`, HEAD `c20e9b2`): 11 rutas personales (`file:///home/romen/Proyectos/…`)
y 10 IPs públicas (`158.179.213.240`) en ADRs y docs vigentes. Excluir `.agents/tasks/_archived/`
con motivo escrito en el fichero de excepciones del satélite.

## Contexto técnico
El escáner del core ya soporta repo externo (`locator-hygiene.sh --path`, puro lector, sin escrituras).
El satélite tiene `.agents/` instalado, así que la exclusión vive en
`<satélite>/.agents/config/infra-literals.exceptions` (formato del core como referencia).
Decisiones fijadas: `_archived/` se excluye (no se reescribe historia); los ADR duplicados
(`docs/adr/` vs `docs/adrs/`) SOLO se sanean, su consolidación es otra tarea.

## Caja de archivos
Archivos autorizados para modificación (todos en el satélite `romensuarez-web/limpet`):
- `docs/adr/0001-estrategia-despliegue-hibrido-cloudflare-coolify.md`
- `docs/adr/0002-segmentacion-subdominios-cloudflare-access.md`
- `docs/adrs/ADR-001-estrategia-despliegue-hibrida-cloudflare-coolify.md`
- `docs/adrs/ADR-002-segmentacion-subdominios-cloudflare-access.md`
- `docs/adrs/README.md`
- `docs/architecture-evaluation-cloudflare-coolify.md`
- `.agents/config/infra-literals.exceptions` (crear si no existe, formato del core)
- Cualquier otro `.md` vigente que el escáner marque (solo literales, nunca código ni historia)

## Criterios de done
- [ ] `locator-hygiene.sh --path <satélite>` devuelve 0 violaciones fuera de `_archived/`
- [ ] `.agents/tasks/_archived/task-005/006/007.md` excluidos con motivo escrito (no reescritos)
- [ ] Suite del core 25/25 intacta (el core no se toca; solo se usa su escáner)
- [ ] Trabajo commiteado en el satélite (rama `feat/T-106-…`, NO en el core)

## Estado de aprobación
> Este bloque lo rellena el agente durante /session-start.
> No modificar manualmente.

- [ ] Plan presentado al usuario (Fase 3.5)
- [ ] APROBADO recibido — fecha/hora: ___
- [ ] Rama creada: ___
- [ ] Lock activo: ___
- [ ] Sesión cerrada correctamente
