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
infisical secrets \
  --domain="${INFISICAL_API_URL}" \
  --projectId="${INFISICAL_PROJECT_ID}" \
  --env=prod

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
