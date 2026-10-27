# Runbook — Operaciones con secretos

> Herramienta: `scripts/agent/secrets.sh` (T-117)  
> Complementa: `secret-locate.sh` (dónde vive), `import-secrets.sh` / `materialize-secrets.sh` (bóveda ⇄ `.env`).

---

## Contrato de no-valor

`secrets.sh` es el **único** script del core que escribe valores en la bóveda, y lo hace bajo estas
reglas:

1. El valor entra por **stdin** (`--stdin`, sin eco en TTY) o se **genera** (`--generate[=N]`).
2. Un valor por argumentos se rechaza con **exit 2**: no aparece en `ps`, ni en el historial, ni en
   los logs del shell.
3. Al CLI viaja por `infisical secrets set --file /dev/stdin`: **sin fichero temporal**.
4. La confirmación imprime clave, carpeta, entorno y `sha256` truncado a 12 hex. Nunca el valor,
   ni un fragmento, ni su longitud.
5. Sin `set -x` y sin `eval`.

---

## Uso

```bash
# Valor por tubería (scripts, agentes)
printf 'valor' | bash scripts/agent/secrets.sh set MI_CLAVE --stdin --path /proyectos-x

# Valor por teclado (no se muestra)
bash scripts/agent/secrets.sh set MI_CLAVE --stdin --path /proyectos-x

# Valor generado (32 caracteres por defecto; rango 16-128)
bash scripts/agent/secrets.sh set MI_CLAVE --generate --path /proyectos-x
bash scripts/agent/secrets.sh set MI_CLAVE --generate=48 --path /proyectos-x --tags scope-shared,env-dev

# Rotación: genera, escribe y verifica que updatedAt cambió
bash scripts/agent/secrets.sh rotate MI_CLAVE --path /proyectos-x

# Confirmación en JSON (mismas claves, sin valor)
bash scripts/agent/secrets.sh set MI_CLAVE --stdin --path /proyectos-x --json
```

### Resolución de carpeta

- `--path /<carpeta>` es **obligatorio para crear** una clave que no existe: sin carpeta no hay
  destino y se sale con **6**.
- Si se omite, se resuelve con `secret-locate.sh --name <CLAVE>`: debe existir en **una** carpeta.
  Con 0 → exit 6; con 2 o más → exit 2 pidiendo `--path`.

---

## Códigos de salida

| Código | Significado |
|---|---|
| `0` | Escritura (y verificación, en `rotate`) correcta |
| `1` | Entorno (credenciales, `VERSION`, CLI) o verificación fallida |
| `2` | Uso incorrecto, incluido cualquier intento de valor por `argv` |
| `6` | La clave no existe y no se indicó `--path` |

---

## Buscar sin listar todo: `--search`

`secret-locate.sh --search <texto>` recorre **metadatos** (nombre de clave, descripción, etiquetas y
nombre de carpeta) y devuelve carpeta + clave. Case-insensitive.

```bash
bash scripts/agent/secret-locate.sh --search cloudflare
bash scripts/agent/secret-locate.sh --search supabase --json
```

- Exit `0` con coincidencias, `6` sin ninguna, `64` uso incorrecto (texto vacío).
- **No busca en valores**: hacerlo exigiría materializarlos. El export que ya usa el script los
  descarta sin imprimirlos.

---

## Consumir un secreto sin imprimirlo

```bash
infisical run --path=/<carpeta> -- <comando>          # el valor llega al proceso, no a la salida
infisical run --path=/<carpeta> -- <comando> 2>&1 | redact.sh   # diagnósticos (redact.sh llega con T-118)
```

Evita `echo $CLAVE`, `env | grep` y `infisical export` a pelo: cualquiera de los tres deja el valor
en la salida o en el historial.

---

## Higiene de metadatos

`secret-locate.sh --hygiene` lista claves sin descripción ni etiquetas con **un solo barrido** de la
bóveda (un `infisical export` por carpeta). Para completar metadatos sin exponer el valor:

```bash
printf 'CLAVE=valor\n' | infisical secrets set --file /dev/stdin --path=/<carpeta> --tag scope-shared --tag env-dev
```

---

## Límites conocidos

- Duplica ~15 líneas de autenticación (mint de token) de `secret-locate.sh`; candidato a lib común.
- `rotate` verifica por `updatedAt`: si la bóveda no lo actualiza (p. ej. mismo valor en el mismo
  milisegundo), la rotación se reporta como no verificada y sale 1.
- Los valores nunca se escriben en disco **por estos scripts**; si un consumidor los materializa
  (`.env`), eso es `materialize-secrets.sh` con permisos 600 y ficheros no versionados.
