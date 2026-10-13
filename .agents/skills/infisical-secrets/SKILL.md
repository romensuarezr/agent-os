---
name: infisical-secrets
description: Inyección efímera de secretos en memoria y gestión centralizada con Infisical Community Edition y Universal Auth en la flota de Agent OS.
---

# 🔐 Infisical Secrets Management (Inyección Efímera de Secretos)

Esta habilidad proporciona el protocolo operativo, runbooks y comandos necesarios para inyectar variables de entorno y secretos confidenciales directamente en la memoria de los procesos (`infisical run`), eliminando por completo la necesidad de almacenar archivos `.env` en disco o exponer tokens en repositorios.

Infisical opera como el gestor centralizado de secretos de la flota de **Agent OS**, alojado en el nodo de infraestructura PaaS (Coolify/Docker).

## Cuándo usar
- Inyectar secretos o variables de entorno efímeramente en subprocesos (`infisical run`) sin persistir archivos `.env` en disco.
- Configurar autenticación Universal Auth (Machine Identity: Client ID + Secret) para agentes o servicios de la flota.
- Importar, exportar o rotar credenciales y variables de entorno de producción y staging de forma centralizada.

---

## 🌐 Topología del Servicio y Conectividad Dinámica

La configuración del servicio se resuelve de forma dinámica y desacoplada mediante `.agents/config/fleet.yaml` o variables de entorno del host, garantizando portabilidad absoluta en proyectos hijos:

- **Variables de Entorno Estándar**:
  - `INFISICAL_API_URL`: Endpoint de la API REST (ej. `http://<host>:<puerto>/api` o `https://infisical.tu-dominio.com/api`).
  - `INFISICAL_CLIENT_ID`: Identificador público de la Machine Identity.
  - `INFISICAL_CLIENT_SECRET`: Clave secreta confidencial de la Machine Identity.
  - `INFISICAL_PROJECT_ID`: Identificador único (UUID) del proyecto o workspace en Infisical.
- **Configuración en Flota (`.agents/config/fleet.yaml`)**:
  - Consulta la sección `nodes.<nodo>.services.infisical` para resolver el endpoint y consola sin exponer datos en git.
- **Modo Recomendado**: `infisical` standalone lite (<500MB RAM) con PostgreSQL y Redis local.

---

## 🔑 Autenticación: Machine Identity (Universal Auth)

Para la interacción automatizada de agentes de IA, CLI local y scripts desatendidos (CI/CD o cron jobs), Infisical emplea **Universal Auth** (Machine Identities), evitando el login interactivo de usuario humano.

### 1. Creación de la Identidad en la Consola Web

1. Acceder a la consola administrativa de tu instancia (`/admin`).
2. Crear o seleccionar la Organización y el Proyecto (ej. `Agent OS` o el nombre del proyecto actual).
3. Navegar a **Access Control** → **Machine Identities** → **Add Machine Identity**.
4. Nombre de la identidad: `agent-os-flota` (o `runner-local`).
5. Configurar el método de autenticación: **Universal Auth**.
6. En la pestaña del Proyecto, asociar la Machine Identity con el rol adecuado (`Developer` para lectura de secretos de desarrollo/staging o `Admin` para gestión integral).
7. Generar las credenciales:
   - **Client ID**: Identificador público de la máquina.
   - **Client Secret**: Secreto de un solo visionado.
8. Obtener el **Project ID** desde la URL o la pestaña de configuración del proyecto (`Project Settings` → `General`).

### 2. Autenticación Universal Auth con el CLI (Machine Identity)

Para ejecuciones desatendidas de agentes o runners, **NUNCA** se usa login interactivo de navegador. El flujo es estrictamente en 2 pasos: primero se canjea el token con `infisical login` y luego se consume con `infisical run` o `infisical export`:

> ⚠️ **TRAMPA COMÚN**: `infisical run` **NO** tiene el flag `--method=universal-auth` (ese flag es de `infisical login`). Si ejecutas `infisical run` sin definir `INFISICAL_TOKEN` o `--token`, la CLI intentará abrir un navegador solicitando login de usuario.

```bash
# PASO 1: Canjear el token Universal Auth en memoria (sin interacción humana)
export INFISICAL_TOKEN=$(infisical login \
  --domain="${INFISICAL_API_URL}" \
  --method=universal-auth \
  --client-id="${INFISICAL_CLIENT_ID}" \
  --client-secret="${INFISICAL_CLIENT_SECRET}" \
  --plain 2>/dev/null | tail -n 1)

# PASO 2: Ejecutar subproceso con los secretos inyectados en memoria
infisical run \
  --token="$INFISICAL_TOKEN" \
  --domain="${INFISICAL_API_URL}" \
  --projectId="${INFISICAL_PROJECT_ID}" \
  --env=dev \
  --path="/<nombre-del-proyecto>" \
  -- <comando_a_ejecutar>
```

---

## 📁 Organización por Carpetas de Proyectos (`--path`)

En la flota de **Agent OS**, todos los proyectos comparten un workspace central en Infisical (`Agent OS`), organizados en carpetas jerárquicas:
- `/romensuarez-web`
- `/kanarii`
- `/polymarket`
- etc.

> ⚠️ **TRAMPA COMÚN**: Por defecto, la CLI consulta la raíz (`/`), donde hay **0 secretos**. Si estás trabajando en un proyecto específico, **SIEMPRE debes incluir `--path="/<nombre-del-proyecto>"`** al consultar, exportar o inyectar secretos.

Para descubrir qué carpetas existen en el proyecto:
```bash
curl -s -X GET "$INFISICAL_API_URL/v1/folders?workspaceId=$INFISICAL_PROJECT_ID&environment=dev" \
  -H "Authorization: Bearer $INFISICAL_TOKEN" | jq -r '.folders[].name'
```

---

## ⚡ Comandos de Operación y Runbooks

El CLI de Infisical está disponible en el entorno local (bien como binario nativo, npm global o vía `npx -y @infisical/cli`).

### 1. Inyección de Secretos en Memoria (`infisical run`)

Ejecuta el subproceso inyectando las variables descifradas directamente en `process.env` sin tocar disco:

```bash
# Ejemplo en romensuarez-web:
infisical run \
  --token="$INFISICAL_TOKEN" \
  --domain="${INFISICAL_API_URL}" \
  --projectId="${INFISICAL_PROJECT_ID}" \
  --env=dev \
  --path="/romensuarez-web" \
  -- npm run dev
```

### 2. Exportación Directa a la Sesión Shell (`infisical export`)

Si necesitas tener las variables disponibles en el entorno bash actual (por ejemplo para scripts de despliegue):

```bash
eval $(infisical export \
  --token="$INFISICAL_TOKEN" \
  --domain="${INFISICAL_API_URL}" \
  --projectId="${INFISICAL_PROJECT_ID}" \
  --env=dev \
  --path="/romensuarez-web" \
  --format=dotenv-export)
```

### 3. Autenticación Alternativa vía API REST Directa (curl / Python)

Si por alguna razón la CLI no estuviera instalada, la API REST oficial de Universal Auth se consume exactamente así:

- **Endpoint**: `POST ${INFISICAL_API_URL}/v1/auth/universal-auth/login`
- **Body JSON**: `{"clientId": "$INFISICAL_CLIENT_ID", "clientSecret": "$INFISICAL_CLIENT_SECRET"}` (*en camelCase*)

```bash
# Obtención del access token vía curl
RESP=$(curl -s -X POST "$INFISICAL_API_URL/v1/auth/universal-auth/login" \
  -H "Content-Type: application/json" \
  -d "{\"clientId\":\"$INFISICAL_CLIENT_ID\",\"clientSecret\":\"$INFISICAL_CLIENT_SECRET\"}")

export INFISICAL_TOKEN=$(echo "$RESP" | jq -r '.accessToken')
```

> ⚠️ **NO ALUCINAR CON LA RED**:
> - `INFISICAL_API_URL` ya termina en `/api` (ej. `http://<host>/api`).
> - La ruta exacta es `/v1/auth/universal-auth/login`. No inventes `/v3/...` ni omitas `/login`.
> - Las claves del JSON son `clientId` y `clientSecret` (camelCase), no `client_id` (snake_case).
> - La instancia corre detrás del proxy inverso de Coolify. **NUNCA** intentes conectar a puertos internos como `:8080`.

### 2. Inicialización en un Proyecto Hijo (`infisical init`)

En un proyecto hijo gestionado por Agent OS:

```bash
# Conectar el directorio local con el proyecto en Infisical
infisical init --domain="${INFISICAL_API_URL}"
```
Esto genera un archivo `.infisical.json` que contiene únicamente el `projectId` y la configuración de workspace (sin ningún secreto ni token sensible).

### 3. Consulta, Creación y Borrado de Secretos

```bash
# Listar claves de secretos disponibles (sin mostrar valores)
# ⚠️ NO uses `infisical secrets` para inventariar: imprime los VALORES en claro y los
#    vierte en tu contexto y en el log de la sesión. Usa el localizador del core.
bash scripts/agent/secret-locate.sh --list
bash scripts/agent/secret-locate.sh --name NOMBRE_DE_LA_CLAVE

# Auditar la bóveda: revocados, duplicados y conflictos de shadowing
bash scripts/agent/secret-locate.sh --audit
python3 scripts/agent/lib/verify-secrets.py --source=infisical

# Crear o actualizar un secreto
infisical secrets set CLAVE="valor" \
  --domain="${INFISICAL_API_URL}" \
  --projectId="${INFISICAL_PROJECT_ID}" \
  --env=dev

# Eliminar un secreto (IMPORTANTE: requiere --type=shared al usar Machine Identity)
infisical secrets delete CLAVE \
  --type=shared \
  --domain="${INFISICAL_API_URL}" \
  --projectId="${INFISICAL_PROJECT_ID}" \
  --env=dev
```

### 4. Volcado Efímero por Pipe (Nunca a archivo rastreado)

Si un script legacy o docker-compose requiere variables en formato dotenv, se realiza por pipe o proceso temporal, **NUNCA** redireccionando a un archivo `.env` persistido en git:

```bash
# Lectura en memoria para un subshell
eval $(infisical export --env=prod --format=dotenv-export --domain="${INFISICAL_API_URL}" --projectId="${INFISICAL_PROJECT_ID}")
```

### 5. Auditoría y Migración Masiva de Secretos (`import-secrets.sh`)

Para migrar repositorios existentes o escanear una máquina con múltiples proyectos:

```bash
# Diagnóstico y validación de vigencia de APIs sin modificar Infisical (0 tokens)
bash scripts/agent/import-secrets.sh /ruta/a/proyectos --dry-run

# Aplicar migración jerárquica a Infisical en entorno dev (crea carpetas por proyecto)
bash scripts/agent/import-secrets.sh /ruta/a/proyectos --apply --env=dev

# Aplicar y proteger los archivos originales (.env -> .env.backup)
bash scripts/agent/import-secrets.sh /ruta/a/proyectos --apply --env=dev --clean-env
```

---

## 🛡️ Reglas de Seguridad y Buenas Prácticas

1. **Principio de Secreto Cero en Git**:
   - Queda terminantemente prohibido generar archivos `.env`, `.env.production` o similares dentro del árbol de trabajo que puedan ser accidentalmente añadidos a git.
   - La suite `tests/validate-control-plane.sh` audita activamente que ningún archivo `.env` esté rastreado.
2. **Aislamiento por Entornos**:
   - `dev`: Claves para tests y desarrollo local.
   - `staging`: Claves para tests de integración en entornos de staging.
   - `prod`: Claves de producción de servicios desplegados en hosting/Coolify.
3. **Rotación Rápida**:
   - En caso de sospecha de compromiso de un token (ej. GitHub PAT o API key de LLM), la rotación se ejecuta en la consola de Infisical; todos los agentes y servicios consumen el nuevo valor en la siguiente ejecución sin necesidad de re-desplegar ni tocar código fuente.

---

## 📐 Taxonomía y alcance de los secretos

### Protocolo cuando un secreto no está en la carpeta del proyecto

**No adivines, no iteres carpeta por carpeta y no preguntes al usuario.** Es la causa más
frecuente de turnos quemados:

```bash
bash scripts/agent/secret-locate.sh --name NOMBRE_DE_LA_CLAVE
```

El script responde en una sola llamada dónde vive la clave. Si aparece en varias carpetas,
avisa del conflicto: puede ser una clave transversal o una copia obsoleta.

### Metadatos obligatorios

Usa la **descripción** del secreto en Infisical para declarar el alcance. Convención:

```
scope=project|shared   shared solo si la consumen 2 o más proyectos
env=dev|staging|prod
owner=<equipo>
consumers=<proyectos que la leen>
rot=<periodicidad de rotación>
```

### Reglas de ubicación (no son opiniones: están medidas)

1. **Transversal → carpeta compartida.** Una clave consumida por **≥2 proyectos** va en la
   carpeta compartida, con `scope=shared` y `consumers=` listados. El umbral sale de la
   auditoría de la bóveda, no de criterio subjetivo.
2. **Específica → carpeta del proyecto.** Claves atadas a un entorno concreto
   (`DATABASE_URL`, `TELEGRAM_CHAT_ID`, `PORT`) **no** se comparten ni se replican, aunque
   dos proyectos usen el mismo nombre de variable.
3. **No se replica un secreto "porque ya se usó aquí".** Duplicar credenciales multiplica la
   superficie de revocación: si copias una clave a dos carpetas, rotarla exige recordar ambas.
   Solo se replica cuando el aislamiento lo exige (producción vs desarrollo), y siempre
   declarando `consumers`.
4. **Nada de carpetas `_backup` dentro de la bóveda.** Un respaldo vive fuera del gestor de
   secretos. Dentro de la bóveda se convierte en una copia obsoleta que nadie rota.
5. **Nunca borres una clave revocada.** Márcala y repórtala: borrarla destruye el rastro del
   incidente y deja al servicio sin credencial sin explicación.

### Shadowing: el fallo más peligroso y silencioso

Si el **mismo nombre** existe en varias carpetas con **valores distintos**, revocar una copia
deja vivas las demás, y un agente que elija la carpeta equivocada usa otra credencial sin
enterarse. Ninguna herramienta lo detecta por defecto:

```bash
python3 scripts/agent/lib/verify-secrets.py --source=infisical
```

Salida relevante: `CONFLICTO (mismo nombre, valores distintos)`. Cada conflicto debe
resolverse eligiendo **una** carpeta canónica y borrando el resto.

### Auditoría periódica

```bash
bash scripts/agent/secret-locate.sh --audit          # duplicados y carpetas clonadas
python3 scripts/agent/lib/verify-secrets.py --source=infisical   # revocados y shadowing
```

Ambas son de **solo lectura** y comparten motor de vigencia, así que no pueden divergir.

---

## 🏷️ Descripciones y etiquetas: cómo leerlas y cómo proponerlas

### Qué estado tiene la bóveda (medido, no supuesto)

La auditoría de higiene revela el dato duro:

```bash
bash scripts/agent/secret-locate.sh --hygiene
```

En la última auditoría, **283 de 283 entradas** estaban sin descripción y sin etiquetas. El
modelo de datos de Infisical soporta ambos campos (`comment` y `tags`), y la CLI permite
escribir las etiquetas; simplemente nadie los ha usado.

### Qué aporta cada metadato

| Campo | Para qué sirve | Cómo se lee |
| :--- | :--- | :--- |
| `lastSecretModified` de la carpeta | **Ordena por antigüedad real.** La carpeta tocada más recientemente es la canónica probable ante un conflicto de shadowing | `secret-locate.sh --list` ya viene ordenado |
| `description` de la carpeta | Qué guarda esa carpeta y quién la consume | `secret-locate.sh --list` la muestra |
| `tags` del secreto | Etiquetado rápido: `scope`, `env`, `owner` | `secret-locate.sh --hygiene` |
| `comment` del secreto | Descripción larga del propósito de la clave | ídem |

### Etiquetado (la CLI lo soporta de forma nativa)

```bash
infisical secrets set NOMBRE_DE_LA_CLAVE="<valor>" \
  --path=/<carpeta> \
  --tag scope-project --tag env-prod --tag owner-plataforma
```

> ⚠️ **`--tag` REEMPLAZA** las etiquetas existentes, no las añade. Lee antes de escribir.
> ⚠️ **Los slugs solo admiten minúsculas, números y guiones.** `scope=project` se rechaza
> con un 422; la forma válida es `scope-project`. El `=` no existe como separador: el
> prefijo hace de namespace.

### Etiquetas ya aplicadas en la flota

Tras la auditoría se etiquetaron con `scope-project` + `env-dev` las claves que comparten
nombre entre carpetas pero son **configuración por proyecto**, para que la auditoría deje de
reportarlas como shadowing:

`APP_URL`, `DATABASE_URL`, `GOOGLE_API_KEY`, `GROQ_API_KEY`, `HF_TOKEN`, `N8N_API_KEY`,
`N8N_API_URL`, `NEXT_PUBLIC_WHATSAPP_NUMBER`, `NOTION_API_KEY`, `PORT`,
`TELEGRAM_BOT_TOKEN`, `TELEGRAM_CHAT_ID`

La auditoría respeta esa etiqueta: una clave con `scope-project` se clasifica como
`INTENCIONAL_SCOPE_PROJECT` y nunca como conflicto.

### Descripciones: límite real

La CLI expone `--tag` pero **no** tiene flag de descripción. El campo `comment` existe en el
modelo y se exporta con `infisical export`, pero la vía de escritura no está expuesta por la
CLI documentada. Mientras tanto, la taxonomía **debe vivir en las etiquetas**, que sí son
escribibles:

```
scope-project|scope-shared    env-dev|env-staging|env-prod
owner-<equipo>                consumers-<proyectos>       rot-<periodicidad>
```

### El agente debe proponer, no mutar solo

Si `--hygiene` reporta claves sin metadatos, o si `--audit` revela shadowing o carpetas
clonadas, el agente debe **informar y proponer el cambio concreto** (qué clave, en qué
carpeta, con qué etiquetas), nunca reescribir la bóveda por su cuenta. Escribir secretos es
una acción con consecuencias que requiere aprobación humana.

### Respuesta a la pregunta de qué carpeta es la buena

- `shared` es la carpeta canónica de secretos transversales.
- `/configuraciones` es su predecesora: contiene exactamente las mismas 5 claves y **no tiene
  descripción**. Existe por costumbre, no por diseño.
- Conviven hasta que se migren los consumidores. Retirarla exige verificar quién la usa, así
  que es una pasada posterior, no una decisión automática.


---

## 📇 Catálogo de secretos por repositorio

### Qué es

`.agents/config/secrets-catalog.yaml` es el **contrato** de secretos de un repositorio: qué
claves declara, de qué carpeta de la bóveda viene cada una, qué etiquetas tiene y si su valor
sigue vivo. **No contiene valores.**

```yaml
generated_at: 2026-10-12T18:13:33Z
source: infisical+local      # o 'local-only' si no hay bóveda
complete: true
secrets_declared: 56
secrets:
  - key: HF_TOKEN
    scope: shared
    status: unknown
    locations: [kanairos, polymarket, shared]
    tags: [env-dev, scope-shared, uses-polymarket]
    required_by: [.env, packages/agents/agent-data-manager/.env]
```

### Por qué se versiona en git

Un `.env` es una foto ciega: no dice de dónde vino una clave, qué más la usa ni si sigue
viva. El catálogo sí. Versionarlo hace que un PR muestre los cambios de contexto:
"esta clave pasó a `scope-shared`", "esta carpeta ya no la consume", "esto está revocado".
Ese es el motivo de que sea un artefacto **generado y versionado**, y no un fichero de
memoria.

### Cómo se genera y quién lo escribe

**Lo escribe el script. El agente no lo edita a mano.**

```bash
bash scripts/agent/generate-secrets-catalog.sh --path .            # regenerar
bash scripts/agent/generate-secrets-catalog.sh --path . --check    # pre-flight: 1 si está desfasado
```

Degrada sin red: si la bóveda no responde, genera solo la parte derivable del repo y marca
`source: local-only` y `complete: false`. Un proyecto hijo que **no** use Infisical también
tiene catálogo: refleja sus referencias locales.

### El ciclo completo

```
bóveda (fuente de verdad)  ──generate──▶  catálogo (versionado)  ──materialize──▶  .env
  tags, descripciones                        contrato sin valores                  copia local
                                                                                   (gitignored)
```

``.env` es una **materialización** para trabajar sin conexión, nunca la fuente. Se genera con:

```bash
# Simulación (defecto): no escribe nada, solo informa
bash scripts/agent/materialize-secrets.sh --path .

# Escritura real: solo añade lo que falta, nunca pisa lo que ya está
bash scripts/agent/materialize-secrets.sh --path . --apply
# --force si de verdad quieres sobrescribir un valor local
```

**Garantías de la materialización**

| Garantía | Cómo |
| :--- | :--- |
| Nada se escribe sin `--apply` | Modo detección por defecto |
| Nunca imprime valores | Ni en texto ni en `--json` |
| Nunca pisa un valor local | `--force` explícito, y avisa del divergente |
| **Rechaza escribir en ficheros que git versionaría** | Frena con exit 1 y lista los ficheros |
| Nunca escribe en `.env.example` | Las plantillas son contrato, no credenciales |
| Permisos 600 | En cada fichero escrito |

Si el dry-run marca **(valor local distinto)**, hay shadowing entre el `.env` y la bóveda.
No lo resuelvas con `--force` sin entender cuál de los dos valores es el bueno: mira la
evidencia de uso que da `secret-locate.sh`.

### Cuándo falta una clave en un proyecto

1. `secret-locate.sh --name X` primero. Si ya existe en otra carpeta, **no la copies**: cámbiala.
2. Si no existe en absoluto, decide el alcance: credencial del proyecto → su carpeta;
   credencial de proveedor usada por varios → `shared` con `scope-shared`.
3. **Etiqueta en el momento de crearla.** Es la única vez que tienes el contexto fresco.
4. Regenera el catálogo.


---

## 📊 Marca de salud de los secretos

### Qué es y por qué NO se comprueba en cada sesión

`.agents/context/secrets-health.md` es una **marca generada** que `install.sh` escribe al
desplegar y que se regenera a demanda. **No se comprueba en el pre-flight de sesión, a
propósito**: un aviso que aparece cada vez y casi nunca exige acción es ruido que entrena a
ignorar los avisos. Solo se lee cuando un agente trabaja con secretos.

### Qué contiene

```
- **Auditado**: <fecha ISO>
- **Revocadas**: <n>
- **Conflictos de shadowing**: <n>
- **Cobertura de verificacion**: <verificadas>/<total> (<pct>%)
```

La cobertura es el dato que más duele: si es baja, **hay credenciales que nadie ha
verificado nunca**, y una revocada puede estar隐形 desde hace meses.

### Antigüedad: 3 meses

Estos datos son una foto. Si la marca tiene **más de 3 meses**, no te fíes: regenera.

```bash
python3 scripts/agent/lib/verify-secrets.py --source=infisical --mark
```

Tarda ~40s (llama a las APIs de cada proveedor). Para un inventario rápido sin red:

```bash
bash scripts/agent/secret-locate.sh --audit --json
```

### El ciclo de rotación

1. **Detectar**: la auditoría marca qué valores están revocados y en qué carpetas.
2. **Decidir**: para cada clave revocada, quién la consume y si es transversal o por
   proyecto. **No copies el token que funciona de otro repo**: los tokens de Cloudflare
   tienen permisos por zona y las claves de Gemini están atadas a un proyecto de Google.
   Copiar da acceso a dominios ajenos o viola los términos del proveedor.
3. **Rotar**: generar el token nuevo en la consola del proveedor, donde se controla el
   alcance, y guardarlo en su carpeta canónica.
4. **Propagar**: cuando el valor nuevo responde, `materialize-secrets.sh --force` refresca
   los `.env` locales, y se elimina la copia vieja de las carpetas que la tenían.
