# Runbook: Normalización de Autenticación GitHub SSH en Servidores Remotos

> **Fecha**: 2026-09-24  
> **Hosts**: Nodos configurados en `config/fleet.yaml` (ej: `<worker-node>` y `<infra-node>`, o alias SSH definidos en `~/.ssh/config`)  
> **Objetivo**: Resolver de forma determinista el error `Host key verification failed` y establecer una arquitectura segura de autenticación Git SSH sin prompts interactivos ni exposición de credenciales.  
> **Herramienta de diagnóstico**: `.agents/skills/remote-admin/scripts/check-git-remote.sh`

---

## 1. Diagnóstico Actual (Estado Detectado)

| Parámetro | Host Worker (`<worker-node>`) | Host Infra (`<infra-node>`) |
| :--- | :--- | :--- |
| **Rol en el Control Plane** | Agentes persistentes + Inferencia local | Docker Infra + PaaS / Coolify |
| **Usuario / Home** | `<usuario>` (`/home/<usuario>`) | `<usuario>` (`/home/<usuario>`) |
| **`known_hosts` para GitHub** | Verificar presencia de `github.com` | Verificar presencia de `github.com` |
| **Clave SSH cliente existente** | `~/.ssh/id_ed25519` | `~/.ssh/id_ed25519` |
| **Huella clave pública** | `ssh-ed25519 <CLAVE_PUBLICA> <usuario>@<host>` | `ssh-ed25519 <CLAVE_PUBLICA> <usuario>@<host>` |
| **Handshake `git@github.com`** | `Host key verification failed` si falta en `known_hosts` | `Host key verification failed` si falta en `known_hosts` |
| **Configuración Git Global** | `<Nombre de Agente> / <email@dominio.local>` | `<Nombre de Agente> / <email@dominio.local>` |

---

## 2. Causa Raíz

1. **Ausencia de huellas en `known_hosts`**:
   Cuando un script o agente desatendido (Hermes, Orca, git clone/pull) contacta con `github.com` por primera vez vía SSH, OpenSSH intenta abrir un prompt interactivo pidiendo confirmar la autenticidad del host. Al no haber TTY interactivo, la conexión aborta inmediatamente con:
   ```text
   Host key verification failed.
   fatal: Could not read from remote repository.
   ```
2. **Falta de autorización de la clave en GitHub**:
   Incluso al omitir la verificación de host, una clave no registrada devuelve `Permission denied (publickey)`, indicando que no está vinculada a ninguna cuenta ni como Deploy Key en el repositorio.

---

## 3. Arquitectura y Estrategia de Autenticación

### Recomendación de Seguridad: Deploy Keys con Principio de Mínimo Privilegio

Para servidores remotos de ejecución de agentes, se desaconseja añadir las claves SSH a la cuenta de usuario principal de GitHub (lo que otorgaría acceso total a todos los repositorios personales y de organizaciones).

En su lugar, el estándar recomendado es:
1. **Deploy Keys de solo lectura (`read-only`)**:
   - Cada servidor dispone de su propio par de claves `Ed25519`.
   - La clave pública se añade en GitHub en:  
     `https://github.com/<owner>/<repo>/settings/keys`
   - Permite al servidor hacer `git pull`, `git fetch` y clonar repositorios para tareas de auditoría, sincronización o ejecución sin riesgo de escrituras no controladas.
2. **Deploy Keys con permiso de escritura (`read/write`)**:
   - Sólo si el agente en el servidor debe crear ramas o hacer push directamente al repositorio core (requiere supervisión estricta).
3. **Aprovisionamiento no interactivo de `known_hosts`**:
   - Inserción determinista de las claves públicas de GitHub (`ssh-keyscan`) antes de cualquier intento de conexión.

---

## 4. Procedimiento de Aprovisionamiento (Decision Gates)

> ⚠️ **IMPORTANTE**: Estos comandos requieren ejecución supervisada. Sigue los pasos en orden parametrizando con los nombres de host de tu flota (`config/fleet.yaml`).

### Paso 1: Fijar `known_hosts` de GitHub en los servidores (L1 - Seguro)

Ejecutar en la consola local para provisionar `github.com` de forma no interactiva en cada nodo:

```bash
# En el nodo worker:
ssh <worker-node> "mkdir -p ~/.ssh && chmod 700 ~/.ssh && ssh-keyscan -t ed25519,ecdsa,rsa github.com >> ~/.ssh/known_hosts && chmod 600 ~/.ssh/known_hosts"

# En el nodo infra:
ssh <infra-node> "mkdir -p ~/.ssh && chmod 700 ~/.ssh && ssh-keyscan -t ed25519,ecdsa,rsa github.com >> ~/.ssh/known_hosts && chmod 600 ~/.ssh/known_hosts"
```

---

### Paso 2: Configurar Clave SSH en `<worker-node>`

1. **Obtener la clave pública de `<worker-node>`** (o generarla si no existe con `ssh-keygen -t ed25519`):
   ```bash
   ssh <worker-node> "cat ~/.ssh/id_ed25519.pub || ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -N '' && cat ~/.ssh/id_ed25519.pub"
   ```

2. **Acción humana en GitHub (L3 Gate)**:
   - Ir a `https://github.com/<owner>/<repo>/settings/keys`.
   - Pulsar **Add deploy key**.
   - Título: `<worker-node>-deploy-key`
   - Key: Pegar la clave pública obtenida.
   - Dejar desmarcada la opción *Allow write access* (solo lectura) a menos que se requiera push explícito.
   - Pulsar **Add key**.

3. **Configurar `~/.ssh/config` en `<worker-node>`**:
   ```bash
   ssh <worker-node> 'cat << "EOF" >> ~/.ssh/config

Host github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_ed25519
    IdentitiesOnly yes
    StrictHostKeyChecking accept-new
    ConnectTimeout 5
EOF
chmod 600 ~/.ssh/config'
   ```

---

### Paso 3: Configurar Clave SSH y Git en `<infra-node>`

1. **Generar o verificar par de claves Ed25519 en `<infra-node>`**:
   ```bash
   ssh <infra-node> 'ssh-keygen -t ed25519 -C "<infra-node>@agent-os" -f ~/.ssh/id_ed25519 -N ""'
   ```

2. **Obtener la clave pública generada**:
   ```bash
   ssh <infra-node> "cat ~/.ssh/id_ed25519.pub"
   ```

3. **Acción humana en GitHub (L3 Gate)**:
   - Ir a `https://github.com/<owner>/<repo>/settings/keys`.
   - Pulsar **Add deploy key**.
   - Título: `<infra-node>-deploy-key`
   - Key: Pegar la clave pública obtenida.
   - Pulsar **Add key**.

4. **Configurar `~/.ssh/config` y Git Global en `<infra-node>`**:
   ```bash
   ssh <infra-node> 'cat << "EOF" >> ~/.ssh/config

Host github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_ed25519
    IdentitiesOnly yes
    StrictHostKeyChecking accept-new
    ConnectTimeout 5
EOF
chmod 600 ~/.ssh/config'

   ssh <infra-node> 'git config --global user.name "Infra VPS Agent" && git config --global user.email "infra-agent@agent-os.local"'
   ```

---

## 5. Verificación y Validación Automatizada

Para comprobar que la normalización ha tenido éxito sin requerir múltiples comandos manuales, ejecuta desde el entorno local:

```bash
# Verificar nodo worker:
bash .agents/skills/remote-admin/scripts/check-git-remote.sh <worker-node>

# Verificar nodo infra:
bash .agents/skills/remote-admin/scripts/check-git-remote.sh <infra-node>
```

**Resultado esperado en Sección 5 (Handshake)**:
```text
Hi <owner>/<repo>! You've successfully authenticated, but GitHub does not provide shell access.
```
O, si se usó una cuenta de usuario:
```text
Hi <username>! You've successfully authenticated, but GitHub does not provide shell access.
```

El código de salida `1` en `ssh -T git@github.com` con el mensaje de bienvenida de GitHub confirma la autenticación completa y sin errores.
