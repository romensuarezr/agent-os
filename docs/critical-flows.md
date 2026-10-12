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

## Registro de flujos

| # | Flujo | Riesgo principal | Cobertura | Última tarea |
| :-- | :--- | :--- | :--: | :--- |
| 1 | **Bind vs. destino de proxy inverso** | El servicio escucha en una dirección y el proxy inverso apunta a otra: el proxy responde error de gateway aunque el backend esté sano y el healthcheck en verde. | 🟡 | T-098 |

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