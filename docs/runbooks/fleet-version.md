# Runbook — Desfase de versión de la flota

> Herramienta: `scripts/agent/fleet-version.sh` (T-115)  
> Alcance: lectura local. No escribe, no toca git y no usa la red.

---

## Qué resuelve

Cada satélite guarda en `.agents/context/last-sync.md` la versión del core con la que se sincronizó.
`install.sh` y `sync.sh` escriben ese ledger:

```
2026-10-27
version: 1.14.0
tag: v1.14.0
commit: 17f4474...
```

`audit-child.sh` compara ese dato **dentro de cada hijo**. `fleet-version.sh` da la vista agregada:
una tabla con el estado de toda la flota comparado contra el `VERSION` del core.

---

## Uso

```bash
# Descubrimiento automático (fleet.yaml si declara 'satellites:'; si no, satellites.yaml)
bash scripts/agent/fleet-version.sh

# Declaración explícita
bash scripts/agent/fleet-version.sh --satellites .agents/config/satellites.yaml

# Rutas sueltas (el alias es el nombre del directorio)
bash scripts/agent/fleet-version.sh ~/Proyectos/ops-hub ~/Proyectos/kanarii

# Digest para scripts
bash scripts/agent/fleet-version.sh --satellites .agents/config/satellites.yaml --json
```

Sin configuración ni rutas, imprime `ℹ️ No hay satélites configurados` y sale 0: no inventa flota.

---

## Estados

| Estado | Significado | Acción |
|---|---|---|
| `ALINEADO` | La versión registrada coincide con el core | Nada |
| `DESFASE` | Versión distinta; se indica `atrás`/`adelante` y en qué nivel (major/minor/patch) | `sync.sh <ruta>` en el satélite |
| `LEGACY` | El ledger existe pero `version:` falta o no es semver (`legacy`, `unknown`) | Re-sincronizar con `install.sh`/`sync.sh` |
| `AUSENTE` | No hay `.agents/context/last-sync.md` | Instalar o sincronizar el satélite |
| `SELF` | La ruta es el propio core; su `last-sync.md` es documentación, no un ledger | Nada |

El campo `delta` del JSON indica la magnitud en el **nivel más alto donde difieren** (major, minor o
patch); no es un vector acumulado de distancias.

---

## Declarar la flota

`satellites.yaml` se distribuye como esquema, pero el parser acepta cualquier fichero con el mismo
bloque. Formato mínimo:

```yaml
satellites:
  ops-hub:
    path: ~/Proyectos/ops-hub
  kanarii:
    path: ~/Proyectos/kanarii
```

Reglas del parser:

- Bloque `satellites:` en la raíz; alias en indentación de 2 espacios y `path:` en 4.
- Rutas `~/...` se expanden contra `$HOME`; también se aceptan rutas absolutas y relativas.
- Líneas comentadas (`#`) se ignoran. Comentarios al final de `path:` se recortan.
- Un `path:` sin alias se descarta.

Precedencia de descubrimiento (sin `--satellites` ni rutas): `fleet.yaml` si contiene el bloque
`satellites:` → `satellites.yaml`. Las rutas pasadas por argumento siempre se añaden.

---

## Salida

```
📦 Versión del core: 1.14.0 (/ruta/al/core)

ALIAS                ESTADO     SATÉLITE      DETALLE
-------------------- ---------- -------------- -------
ops-hub              DESFASE    1.13.1         atrás (core 1.14.0)
kanarii              ALINEADO   1.14.0         core 1.14.0

📊 Total: 2 · alineados: 1 · desfase: 1 · legacy: 0 · ausentes: 0 · self: 0
```

JSON estable (`--json`): `core.version`, `configured`, `satellites[]` (`alias`, `path`, `status`,
`version`, `date`, `tag`, `direction`, `delta`) y `summary` (`total`, `aligned`, `drift`, `legacy`,
`absent`, `self`).

---

## Códigos de salida

| Código | Cuándo |
|---|---|
| `0` | Lectura completada (también con `DESFASE` o sin satélites: es información, no fallo) |
| `1` | El core no tiene `VERSION` legible o no es semver |
| `2` | Error de uso: opción desconocida, `--satellites` sin valor o fichero inexistente |

---

## Límites conocidos

- El ledger no tiene versión de esquema: el parser es tolerante (`^version:`) y clasifica como
  `LEGACY` en vez de fallar.
- La herramienta no verifica el `commit:` registrado ni el contenido sincronizado; eso es
  `audit-child.sh`.
- Rutas duplicadas se colapsan por ruta real (se conserva el primer alias).
