# Runbook: Normalización de Autenticación GitHub SSH en Servidores Remotos

> **Fecha**: 2026-09-24  
> **Hosts**: `datamanager` (`100.77.82.13`) y `oracle` (`100.96.20.7`)  
> **Objetivo**: Resolver de forma determinista el error `Host key verification failed` y establecer una arquitectura segura de autenticación Git SSH sin prompts interactivos ni exposición de credenciales.  
> **Herramienta de diagnóstico**: `.agents/skills/remote-admin/scripts/check-git-remote.sh`

---

## 1. Diagnóstico Actual (Estado Detectado)

| Parámetro | Host `datamanager` | Host `oracle` |
| :--- | :--- | :--- |
| **Rol en el Control Plane** | Hermes Agent 24/7 + FreeLLMAPI + Ollama | Docker Infra + Coolify + SSH target Orca |
| **Usuario / Home** | `ubuntu` (`/home/ubuntu`) | `ubuntu` (`/home/ubuntu`) |
| **`known_hosts` para GitHub** | ❌ No registrado (`Host key verification failed`) | ❌ No existe archivo `known_hosts` |
| **Clave SSH cliente existente** | ✅ `~/.ssh/id_ed25519` presente | ❌ Ninguna clave cliente en `~/.ssh/` |
| **Huella clave pública** | `256 SHA256:XIwNZsvrx...` (`ubuntu@vnic-susana`) | Ninguna |
| **Handshake `git@github.com`** | ❌ `Host key verification failed` | ❌ `Host key verification failed` |
| **Configuración Git Global** | `Romén Suárez` / `romen@hermes.local` | ❌ No configurado |

---

## 2. Causa Raíz

1. **Ausencia de huellas en `known_hosts`**:
   Cuando un script o agente desatendido (Hermes, Orca, git clone/pull) contacta con `github.com` por primera vez vía SSH, OpenSSH intenta abrir un prompt interactivo pidiendo confirmar la autenticidad del host. Al no haber TTY interactivo, la conexión aborta inmediatamente con:
   ```text
   Host key verification failed.
   fatal: Could not read from remote repository.
   ```
2. **Falta de autorización de la clave en GitHub**:
   Incluso al omitir la verificación de host, la clave existente en `datamanager` devuelve `Permission denied (publickey)`, indicando que no está vinculada a ninguna cuenta ni como Deploy Key en el repositorio.

---

## 3. Arquitectura y Estrategia de Autenticación

### Recomendación de Seguridad: Deploy Keys con Principio de Mínimo Privilegio

Para servidores remotos de ejecución de agentes, se desaconseja añadir las claves SSH a la cuenta de usuario principal de GitHub (lo que otorgaría acceso total a todos los repositorios personales y de organizaciones).

En su lugar, el estándar recomendado es:
1. **Deploy Keys de solo lectura (`read-only`)**:
   - Cada servidor dispone de su propio par de claves `Ed25519`.
   - La clave pública se añade en GitHub en:  
     `https://github.com/romensuarezr/agent-os/settings/keys`
   - Permite al servidor hacer `git pull`, `git fetch` y clonar repositorios para tareas de auditoría, sincronización o ejecución sin riesgo de escrituras no controladas.
2. **Deploy Keys con permiso de escritura (`read/write`)**:
   - Sólo si el agente en el servidor debe crear ramas o hacer push directamente al repositorio core (requiere supervisión estricta L3).
3. **Aprovisionamiento no interactivo de `known_hosts`**:
   - Inserción determinista de las claves públicas de GitHub (`ssh-keyscan`) antes de cualquier intento de conexión.

---

## 4. Procedimiento de Aprovisionamiento (Decision Gates)

> ⚠️ **IMPORTANTE**: Estos comandos requieren ejecución supervisada. Sigue los pasos en orden.

### Paso 1: Fijar `known_hosts` de GitHub en ambos servidores (L1 - Seguro)

Ejecutar en la consola local para provisionar `github.com` de forma no interactiva:

```bash
# En datamanager:
ssh datamanager "mkdir -p ~/.ssh && chmod 700 ~/.ssh && ssh-keyscan -t ed25519,ecdsa,rsa github.com >> ~/.ssh/known_hosts && chmod 600 ~/.ssh/known_hosts"

# En oracle:
ssh oracle "mkdir -p ~/.ssh && chmod 700 ~/.ssh && ssh-keyscan -t ed25519,ecdsa,rsa github.com >> ~/.ssh/known_hosts && chmod 600 ~/.ssh/known_hosts"
```

---

### Paso 2: Configurar Clave SSH en `datamanager`

`datamanager` ya cuenta con su clave `Ed25519` generada.

1. **Obtener la clave pública de `datamanager`**:
   ```bash
   ssh datamanager "cat ~/.ssh/id_ed25519.pub"
   ```
   *Valor detectado en auditoría:*
   ```text
   ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJ7c5FH6kWH2Tfm52TkueaQNtbhEb2SJBclKOvhr5L6E ubuntu@vnic-susana
   ```

2. **Acción humana en GitHub (L3 Gate)**:
   - Ir a [GitHub agent-os Deploy Keys](https://github.com/romensuarezr/agent-os/settings/keys).
   - Pulsar **Add deploy key**.
   - Título: `datamanager-hermes-vps`
   - Key: Pegar la clave pública anterior.
   - Dejar desmarcada la opción *Allow write access* (solo lectura) a menos que se requiera push explícito.
   - Pulsar **Add key**.

3. **Configurar `~/.ssh/config` en `datamanager`**:
   ```bash
   ssh datamanager 'cat << "EOF" >> ~/.ssh/config

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

### Paso 3: Configurar Clave SSH y Git en `oracle`

1. **Generar nuevo par de claves Ed25519 en `oracle` (L3 Gate)**:
   ```bash
   ssh oracle 'ssh-keygen -t ed25519 -C "oracle-vps@agent-os" -f ~/.ssh/id_ed25519 -N ""'
   ```

2. **Obtener la clave pública generada**:
   ```bash
   ssh oracle "cat ~/.ssh/id_ed25519.pub"
   ```

3. **Acción humana en GitHub (L3 Gate)**:
   - Ir a [GitHub agent-os Deploy Keys](https://github.com/romensuarezr/agent-os/settings/keys).
   - Pulsar **Add deploy key**.
   - Título: `oracle-infra-vps`
   - Key: Pegar la clave pública obtenida.
   - Pulsar **Add key**.

4. **Configurar `~/.ssh/config` y Git Global en `oracle`**:
   ```bash
   ssh oracle 'cat << "EOF" >> ~/.ssh/config

Host github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_ed25519
    IdentitiesOnly yes
    StrictHostKeyChecking accept-new
    ConnectTimeout 5
EOF
chmod 600 ~/.ssh/config'

   ssh oracle 'git config --global user.name "Oracle VPS Agent" && git config --global user.email "oracle-agent@agent-os.local"'
   ```

---

## 5. Verificación y Validación Automatizada

Para comprobar que la normalización ha tenido éxito sin requerir múltiples comandos manuales, ejecuta desde el entorno local:

```bash
# Verificar datamanager:
bash .agents/skills/remote-admin/scripts/check-git-remote.sh datamanager

# Verificar oracle:
bash .agents/skills/remote-admin/scripts/check-git-remote.sh oracle
```

**Resultado esperado en Sección 5 (Handshake)**:
```text
Hi romensuarezr/agent-os! You've successfully authenticated, but GitHub does not provide shell access.
```
O, si se usó una cuenta de usuario:
```text
Hi romensuarezr! You've successfully authenticated, but GitHub does not provide shell access.
```

El código de salida `1` en `ssh -T git@github.com` con el mensaje de bienvenida de GitHub confirma la autenticación completa y sin errores.
