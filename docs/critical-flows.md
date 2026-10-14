# Critical Flows — Agent OS Core

> Registro de flujos que, si fallan, **rompen el trabajo de todos los agentes sin señal clara**.
> Es la exigencia de `flow-bug-traceability` definida en `.agents/workflows/session-start.md`: cualquier
> tarea que cierre un bug en producción o que toque permisos, listeners o modelos de datos
> debe consultar este archivo, añadir su caso de borde al flujo correspondiente y actualizar
> el estado de cobertura antes del commit de cierre.

> [!IMPORTANT]
> Cero literales de infraestructura en este archivo (IPs, dominios, rutas personales, puertos
> absolutos de terceros). Se documentan como relaciones ("el proxy apunta a un bind que el
> servicio no escucha"), no como valores. La resolución concreta ocurre en la flota del
> operador, nunca en el repositorio.

## Criterio de inclusión

Un flujo entra aquí si su fallo produce al menos una de estas señales:

| Señal | Ejemplo |
|---|---|
| Falla **sin error visible** | healthcheck verde pero el servicio devuelve 502 |
| Falla **tardíamente**, en un paso posterior | el cliente valida y revienta en producción |
| Falla **de forma distinta según el actor** | funciona por SSH, falla desde el cliente |
| Requiere **credenciales cruzadas** entre componentes | la clave de A contra la API de B |

## Niveles C4 adaptados

C4 describe aplicaciones con servicios y dependencias. Este core es bash: scripts, worktrees y
assets. **Se conservan los nombres C4 y se define qué representa cada nivel aquí**, para que la
columna no sea decorativa.

| Nivel | Nombre | Qué representa en Agent OS |
| :--- | :--- | :--- |
| L1 | Sistema | La relación entre el core y cada proyecto hijo. Lo que cruza la frontera del repositorio. |
| L2 | Contenedor / subsistemas | Un conjunto de procesos que se despliegan y fallan juntos (servicio + proxy inverso, nodo de la flota). |
| L3 | Componente / scripts | Un script del core y los que invoca, con su contrato de entrada/salida. |
| L4 | Código | Funciones internas de un script. **Opcional**: un flujo que solo se rompe dentro de una función no suele dar señal clara, así que este nivel se reserva y hoy está vacío a propósito. |

## Registro de flujos

| # | Flujo | Nivel | Riesgo principal | Cobertura | Última tarea |
| :-- | :--- | :--- | :--- | :--: | :--- |
| 1 | **Bind vs. destino de proxy inverso** | L2 | El servicio escucha en una dirección y el proxy inverso apunta a otra: el proxy responde error de gateway aunque el backend esté sano y el healthcheck en verde. | 🟡 | T-098 |
| 2 | **Propagación de assets core → hijo** | L1 | El hijo recibe los scripts pero no las librerías nuevas: sus scripts de cierre mueren al hacer `source` de un fichero inexistente, y el fallo aparece como error de shell, no como "no estás al día". | ⬜ | T-101 |
| 3 | **Cierre de tarea honesto** | L3 | El script anunciaba "✅ cerrada" sin comprobar que el enlace del sprint apuntara al task file archivado, y el commit de sprint salía con `0 insertions` dejando cambios sin commitear. | 🟡 | T-100 |
| 4 | **Promoción de rama a destino** | L3 | Con `--ff-only` cableado, promover una rama con commits propios fallaba por un motivo que no explicaba la causa real; y `--push --pr` abría un PR vacío porque el destino ya contenía la rama. | 🟡 | T-101 |

## Relaciones entre flujos

| Desde | Hacia | Mecanismo |
| :-- | :-- | :--- |
| 3 | 4 | El commit que produce el cierre de tarea es exactamente el que `promote-to-main.sh` promueve después. Un cierre que miente deja además la promoción sin nada que integrar. |
| 2 | 3 | Un hijo que no recibió las librerías nuevas no puede ejecutar el cierre que el core acaba de endurecer. |

---

## Flujo 1 — Bind del servicio vs. destino del proxy inverso

**Síntoma**: el backend es accesible directamente y responde correctamente; el endpoint
publicado devuelve error de gateway de forma permanente. El healthcheck que consulta el
backend directamente sigue en verde, lo que induce a concluir que "todo funciona".

**Causa raíz**: el servicio publica su puerto en una sola dirección (normalmente la IP de la
malla privada) y el proxy inverso está configurado para reenviar a la dirección de loopback
del propio host. La conexión nunca se establece, pero el frontend del proxy responde igual.

**Por qué cuesta tiempo**: no es un fallo de aplicación, es una discrepancia entre dos
configuraciones que por separado son válidas. El `bind` correcto del servicio y el destino
correcto del proxy son la **misma decisión**, no dos decisiones independientes.

**Regla verificable**:

> El destino del proxy inverso debe apuntar a la dirección donde el servicio **demuestra**
> escuchar, nunca a una dirección por convención. Antes de declarar sano un endpoint
> publicado, comprobar la ruta completa (proxy incluido), no solo el backend.

**Detección determinista**: el pre-flight de pasarelas de inferencia
(`scripts/agent/check-inference-gateway.sh`) distingue `UNREACHABLE` (no hay socket) de
`UPSTREAM_DOWN` (hay socket pero el proxy no alcanza al backend). Ese matiz es exactamente
el que separa este fallo de una caída real del servicio.

**Comprobación de regresión**: si el servicio vuelve a publicarse en loopback, la misma
comprobación distingue ambos casos sin ambigüedad.

**Origen**: detectado y verificado en T-098 durante la remediación de inferencia de los
agentes locales.

---

## Flujo 2 — Propagación de assets core → hijo

**Síntoma**: un script del proyecto hijo falla con un error de shell aparentemente trivial
(`no such file or directory`, `command not found`) en vez de con un mensaje que diga "tu core está
desactualizado". El agente que lo ejecuta pierde tiempo diagnosticando el síntoma equivocado.

**Causa raíz**: la instalación copia el directorio `lib/` entero pero el manifiesto enumera los
ficheros uno a uno. Un fichero de librería nuevo que no se registre en
`scripts/agent/assets-manifest.txt` se instala en los hijos creados después, y falta en los
existentes: el core queda funcionando y un hijo se queda roto, sin ninguna señal de desalineación.

**Por qué cuesta tiempo**: el fallo aparece en el hijo, no en el core, y no encaja con ninguna de
las hipótesis que el agente suele probar primero.

**Regla verificable**:

> Toda librería nueva en `scripts/agent/lib/` se registra en
> `scripts/agent/assets-manifest.txt` en el mismo commit que la crea. Sin esa línea, la
> distribución a proyectos hijos es inconsistente y silenciosa.

**Detección determinista**: hoy **no la hay** (cobertura ⬜). El candidato es un check que compare
los ficheros de `lib/` contra las entradas del manifiesto y falle si hay diferencia.

**Origen**: riesgo identificado al extraer `lib/verify-commit.sh` en T-101.

---

## Flujo 3 — Cierre de tarea honesto

**Síntoma**: `close-task.sh` imprimía "✅ T-100 cerrada correctamente" mientras el enlace de la
fila del sprint seguía apuntando a `.agents/tasks/task-100.md`, un path que ya no existía. El
cierre se anunciaba completo y el repo quedaba con un enlace roto.

**Causa raíz**: el script ejecutaba la acción y reportaba éxito sin verificar el efecto. El mismo
patrón hacía que `close-sprint.sh` commiteara `0 insertions / 0 deletions` y dejara las
modificaciones sin stagear colgando en el working tree.

**Por qué cuesta tiempo**: el síntoma (enlace roto) aparece días después, cuando alguien navega al
sprint file, y no señala al script como causa.

**Regla verificable**:

> Un script que afirma haber hecho algo verifica el efecto **antes** de mover el ref. Se construye
> el commit en un índice temporal, se inspecciona con `git diff-tree`, y solo entonces se mueve la
> referencia. Si no se puede verificar, se avisa explícitamente; nunca se reporta éxito en silencio.

**Detección determinista**: `scripts/agent/lib/verify-commit.sh` centraliza la verificación, y los
checks 18 y 19 de la suite reproducen los dos fallos originales y comprueban que ya no se dan.

**Origen**: T-100, tras cuatro parches manuales previos (T-094, T-095, T-096, T-098).

---

## Flujo 4 — Promoción de rama a destino

**Síntoma**: promover una rama con commits propios fallaba con "requiere rebase", un mensaje que
describía la síntoma del fast-forward y no la causa. En sentido contrario, `--push --pr` terminaba
con código 1 pese a haber fusionado bien, porque el PR se abría contra un destino que ya contenía
la rama origen.

**Causa raíz**: `--ff-only` estaba cableado en tres sitios sin flag que lo relajara, y la
documentación no distinguía `--push` (publica el destino) de `--push-source` (publica el origen),
que no existía: la rama de tarea nunca llegaba a origin, así que el diff a revisar no estaba
disponible.

**Por qué cuesta tiempo**: el fallo se manifiesta en la revisión, cuando ya se ha invertido trabajo
en preparar la promoción.

**Regla verificable**:

> `--ff-only` es el valor por defecto y solo `--merge-commit` lo relaja. Cada push se verifica con
> `git ls-remote` contra la ref real del remoto, y cada merge se verifica comprobando que la rama
> origen queda como ancestro del destino, antes de reportar éxito.

**Detección determinista**: el check 20 cubre los tres modos (fast-forward por defecto,
`--merge-commit`, y fallo de publicación que no deja el destino movido).

**Origen**: T-101.
