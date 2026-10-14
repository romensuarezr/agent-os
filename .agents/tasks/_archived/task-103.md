# Task-103: Sanear la exposición de infraestructura y hacer cumplir la frontera portable

## Objetivo
Dejar el árbol del core sin literales de infraestructura ni rutas personales, y añadir el control
automático que impida que vuelvan a colarse.

La frontera portable ya está decidida (2026-09-28): **cero `$HOME`, cero IPs Tailscale,
cero hostnames en el core**; lo personal vive en un overlay local ignorado por git. Esta tarea no
re-debate la frontera: la aplica y la verifica.

## Contexto técnico

### Qué se expone y por qué importa

| Hallazgo | Dónde | Volumen |
|---|---|---|
| Hostname del nodo de inferencia | árbol actual | 138 (`<nodo-inferencia>`, incluidos `<nodo>-qdrant-1`, `<nodo>_default`) |
| Rutas personales | árbol actual | 64 (`$HOME/...`) |
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

## Defectos encontrados y autocorrecciones

Cinco. Cuatro son bugs reales del escáner, y tres de ellos lo habrían hecho **informar "limpio"
siempre**, que es el peor fallo posible en un control de seguridad.

1. **El escáner se declaraba limpio siempre que existía el fichero de excepciones.** El patrón
   acumulado se construía con `${VAR:-}|$pat`, y ese `|` inicial genera una alternativa VACÍA que
   casa con cualquier línea. Sin fichero de excepciones informaba bien; en cuanto se creó —que es
   justo cuando empieza a importar—, dejó de detectar nada. Lo cazó la prueba negativa con un
   canario: si no, se habría publicado un control que no controlaba.
2. **Las excepciones no se aplicaban nunca.** `pat` se derivaba de `label` en vez de `line`, y
   como la etiqueta no contiene `|`, el patrón resultante era literalmente `"ruta-personal"`, que
   no casa con nada. Las 3 excepciones estaban muertas.
3. **El código de salida era siempre 0.** El contador se incrementaba dentro de un pipeline, y en
   bash eso corre en un subshell: el incremento se perdía. El script detectaba y aun así salía
   con éxito, así que ni el hook ni la suite habrían bloqueado nada.
4. **Inventario incompleto: se me pasó el nodo de orquestación.** Construí la lista de hostnames a
   partir de las IPs y las rutas, y ese nombre es una palabra común en inglés, así que no entró
   en el patrón. Aparecía como nombre de nodo en 49 ficheros, 147 ocurrencias. Ahora el escáner lo
   distingue por caja a propósito: en minúscula es el nodo y se limpia; con mayúscula es la base
   de datos y se conserva. Escribir aquí el nombre real habría reintroducido la fuga que este
   mismo control detecta: documentar el literal es reproducirlo.
5. **Dos errores de medición propios.** Conté como "publicado" el catálogo de secretos porque un
   `grep "secrets-catalog"` también casa con `generate-secrets-catalog.sh`, y afirmé que había
   ficheros con fugas donde el canario estaba sin trackear (el escáner en modo repo solo ve
   ficheros trackeados). Ninguna de las dos afirmaciones alarmantes era real; ambas se
   desmontaron al medir con la ruta exacta.

## Fixup de revisión (antes del merge)

1. **`--quiet` no era silencioso cuando había hallazgos.** Los `printf` de la caja y de la línea
   de contexto no pasaban por `say()`, así que se colaban por stdout: 7 líneas en el primer caso
   del check 22 de la suite. Añadido `sayf()` y enrutados todos los `printf` del script.
   Verificado: `--quiet` con hallazgos → 0 bytes y rc=1; `--quiet` limpio → 0 bytes y rc=0; el
   modo normal sigue mostrando el detalle línea a línea.
2. **Typo en el hook**: "la capa temprana:ritna el error" → "frena el error".

## Criterios de done
- [ ] Cero `$HOME` en ficheros trackeados
- [x] Cero IPs Tailscale/públicas de infraestructura en ficheros trackeados
- [x] Cero hostnames de la flota en ficheros trackeados
- [x] `fleet.example.yaml` genérico de verdad: nodo de ejemplo, cero datos reales
- [x] `routing-policy.yaml` neutralizado sin perder la regla de enrutado
- [x] `routing-policy.yaml` conserva la regla de enrutado (no se pierde en el saneado)
- [x] Check 22 (computado sobre el conteo real: 21 → 22) que falla ante literales prohibidos
- [x] El check respeta un fichero de excepciones, con motivo por entrada
- [x] `.gitignore` cubre la salida del catálogo de secretos
- [x] Hook pre-commit opcional: solo inspecciona staged, no el repo entero
- [x] Suite completa sin regresiones (22/22)
- [x] `git diff --name-only` ⊆ Caja
- [x] Fase 2 (reescritura de historia) NO ejecutada — bloqueada por el usuario — bloqueada por el usuario
- [x] Plan presentado al usuario (Fase 3.5) — APROBADO CON CAMBIOS: D1-D4 + 3 cambios de método
- [x] APROBADO recibido — fecha/hora: 2026-10-14T09:40:00+02:00
- [x] Rama creada: `feat/sanitize-infra-exposure` (desde `main` @ `09e36ce`)
- [x] Lock activo: `.agent-session.lock`
- [x] Sesión cerrada correctamente