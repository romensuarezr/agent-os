# Task-103: Sanear la exposición de infraestructura y hacer cumplir la frontera portable

## Objetivo
Dejar el árbol del core sin literales de infraestructura ni rutas personales, y añadir el control
automático que impida que vuelvan a colarse.

La frontera portable ya está decidida (2026-09-28): **cero `***REMOVED-PATH***`, cero IPs Tailscale,
cero hostnames en el core**; lo personal vive en un overlay local ignorado por git. Esta tarea no
re-debate la frontera: la aplica y la verifica.

## Contexto técnico

### Qué se expone y por qué importa

| Hallazgo | Dónde | Volumen |
|---|---|---|
| Hostname del nodo de inferencia | árbol actual | 138 (`<nodo-inferencia>`, incluidos `<nodo>-qdrant-1`, `<nodo>_default`) |
| Rutas personales | árbol actual | 64 (`***REMOVED-PATH***/...`) |
| IP Tailscale del nodo principal, con puertos | árbol actual | 26 (`<ip-nodo-principal>:3001`, `:3002`, `:11434`, `:61208`, `:8080`) |
| Hostname del host local | árbol actual | 12 (`<host-local>`) |
| Nodos de datos y web | árbol actual | 16 (`<nodo-datos>`, `<nodo-web>`) |
| Otras IPs Tailscale y de gateway | árbol actual | 8 |

### Por qué esto no es cosmético
Un orquestador multi-agente necesita leer y escribir en repos de campo. Si el core público
arrastra la topología de la flota, **los agentes de campo heredan la superficie**: nombres de
nodos, IPs privadas y puertos de servicio. El mapa de la flota es exactamente el asset que
permite saber qué está expuesto y por dónde entrar.

### Por qué el policy no funcionó
`docs/critical-flows.md` abre con un `[!IMPORTANT]` que prohíbe literales de infraestructura, y
el core tiene `secret-locate.sh` y `generate-secrets-catalog.sh`. Lo que nunca tuvo fue
**aplicación**: la política está escrita, las herramientas existen, y la historia del repo la
incumple 451 veces. El patrón es el mismo que cerraron T-100/T-101/T-102: la regla existe pero
nadie la ejecuta.

### Decisiones tomadas por el usuario
- **El repo sigue público.** 4 meses de historia pública no se deshacen con un clic (caché de
  GitHub ~90 días) y el core está diseñado para compartirse.
- **La flota se queda fuera del core.** Ya no es una decisión nueva: es la frontera del 2026-09-28.
  `fleet.yaml` (real) no existe en el repo; `fleet.example.yaml` sí, y contiene un hostname real,
  lo que lo hace peor que no tenerlo: quien lo lee cree que esa es la convención a seguir.
- **Fase 2 (reescritura de historia) bloqueada** hasta que el usuario confirme la rotación.

## Caja de archivos
- `.agents/config/infra-literals.exceptions` (nuevo — lista de excepciones del check)
- `scripts/agent/lib/locator-hygiene.sh` (nuevo — el escáner, reutilizable por el check y el hook)
- `tests/validate-control-plane.sh` (check N+1, calculado sobre el conteo real)
- `scripts/agent/lib/hook-pre-commit` (nuevo — hook opcional, solo sobre staged)
- `.gitignore` (salida del catálogo de secretos)
- `changelog.md`
- `roadmap.md`
- `.agents/tasks/task-103.md` (este contrato)
- `docs/sprints/sprint-16-core.md`
- **~63 ficheros de contenido con literales**, saneados por sustitución mecánica:
  `docs/sprints/_archived/*`, `docs/adrs/*`, `docs/idea-inbox/_archived/*`,
  `docs/architecture/*`, `docs/runbooks/*`, `docs/external-inbox/_archived/*`,
  `.agents/tasks/_archived/*`, `.agents/profiles/*`, `.agents/config/*`,
  `.agents/skills/remote-admin/*`, `tests/`, `scripts/agent/*`, `changelog.md`, `roadmap.md`

## Criterios de done
- [ ] Cero `***REMOVED-PATH***` en ficheros trackeados
- [ ] Cero IPs Tailscale/públicas de infraestructura en ficheros trackeados
- [ ] Cero hostnames de la flota en ficheros trackeados
- [ ] `fleet.example.yaml` genérico de verdad: nodo de ejemplo, cero datos reales
- [ ] `routing-policy.yaml` neutralizado sin perder la regla de enrutado
- [ ] `routing-policy.yaml` conserva la regla de enrutado (no se pierde en el saneado)
- [ ] Check N+1 (calculado sobre el conteo real) que falla ante literales prohibidos
- [ ] El check respeta un fichero de excepciones, con motivo por entrada
- [ ] `.gitignore` cubre la salida del catálogo de secretos
- [ ] Hook pre-commit opcional: solo inspecciona staged, no el repo entero
- [ ] Suite completa sin regresiones
- [ ] `git diff --name-only` ⊆ Caja
- [ ] Fase 2 (reescritura de historia) NO ejecutada — bloqueada por el usuario
- [ ] Plan presentado al usuario (Fase 3.5)
- [ ] APROBADO recibido — fecha/hora: ___
- [ ] Rama creada: ___
- [ ] Lock activo: ___
- [ ] Sesión cerrada correctamente