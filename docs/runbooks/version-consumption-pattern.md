# Patrón Universal de Versiones y Consumo Desacoplado

Guía estándar de **Agent OS** para versionado semántico, consumo desacoplado en aplicaciones satélite (sin cadenas hardcodeadas) y publicación automatizada de releases en GitHub.

---

## 1. Principio Rector: Fuente Única de Verdad

En los proyectos del ecosistema Agent OS, la versión del software se gestiona bajo el principio de **cero duplicación**:
- El archivo plano `VERSION` en la raíz del repositorio contiene estrictamente la versión semver actual (`X.Y.Z`).
- `changelog.md` documenta el historial de cambios agrupados por sprint según la convención [Keep a Changelog](https://keepachangelog.com/) e incluye enlaces comparativos navegables al pie.
- Al cerrar un sprint (`close-sprint.sh`), el script determinista `scripts/agent/lib/release-version.sh` alinea de forma idempotente el archivo `VERSION` con la primera cabecera del changelog.
- Ningún archivo de código fuente (`src/`, `components/`, `package.json`, etc.) debe tener la versión escrita a fuego como literal estático si va a mostrarse en la UI o API.

---

## 2. Patrones de Consumo por Stack

### A. Next.js 14 / 15 (App Router & Pages Router)

Para exponer la versión en el frontend sin exponer el sistema de archivos al cliente:

1. **Inyección en `next.config.js` / `next.config.mjs`**:
   ```javascript
   // next.config.js
   const fs = require('fs');
   const path = require('path');

   const appVersion = fs.readFileSync(path.join(__dirname, 'VERSION'), 'utf8').trim();

   /** @type {import('next').NextConfig} */
   const nextConfig = {
     env: {
       NEXT_PUBLIC_APP_VERSION: appVersion,
     },
   };

   module.exports = nextConfig;
   ```

2. **Consumo en componentes React**:
   ```tsx
   // components/Footer.tsx
   export function Footer() {
     const version = process.env.NEXT_PUBLIC_APP_VERSION || 'dev';
     return (
       <footer className="text-xs text-muted-foreground">
         <span>v{version}</span>
       </footer>
     );
   }
   ```

---

### B. Node.js / Express / Backend

```javascript
// server.js o config/version.js
const fs = require('fs');
const path = require('path');

const VERSION = fs.readFileSync(path.join(__dirname, 'VERSION'), 'utf8').trim();

app.get('/health', (req, res) => {
  res.json({ status: 'ok', version: VERSION });
});
```

---

### C. Python / FastAPI

```python
# app/core/config.py
from pathlib import Path

VERSION_FILE = Path(__file__).resolve().parent.parent.parent / "VERSION"
APP_VERSION = VERSION_FILE.read_text(encoding="utf-8").strip() if VERSION_FILE.exists() else "0.1.0"

# main.py
from fastapi import FastAPI
from app.core.config import APP_VERSION

app = FastAPI(title="Satélite API", version=APP_VERSION)
```

---

### D. Dockerfile Multi-Stage

```dockerfile
# Dockerfile
FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY VERSION ./
COPY . .
RUN npm run build

FROM node:20-alpine AS runner
WORKDIR /app
COPY --from=builder /app/VERSION ./
COPY --from=builder /app/.next ./.next
# ...
```

---

## 3. Adopción Asistida en Satélites Preexistentes

Cuando se incorpora un repositorio con vida previa o de un tercero mediante `audit-repo.sh` o el skill `repo-onboarding`:

1. **Auditoría de Versiones Hardcodeadas**:
   El agente ejecuta una inspección determinista ($0 tokens) para localizar menciones estáticas:
   ```bash
   grep -rnE '(version|app_version)["'\'']?\s*[:=]\s*["'\''][0-9]+\.[0-9]+' src/ app/ components/
   ```

2. **Pregunta Estructurada al Operador (Opt-In)**:
   Si el proyecto tiene su propio esquema de versiones (ej. un paquete publicado en npm o PyPI) o no es de autoría propia:
   > *«Se detectó que el proyecto utiliza versiones hardcodeadas en [rutas]. ¿Deseas adoptar el formato universal de Agent OS (`VERSION` en la raíz + Keep a Changelog) y desacoplar estas referencias, o prefieres conservar el esquema preexistente?»*

3. **Refactorización Asistida**:
   - Si el operador aprueba: Se crea `VERSION` adoptando el valor detectado y se reemplazan los literales por la variable de entorno o lectura de archivo.
   - Si el operador declina: Se preserva la convención nativa del repositorio sin forzar cambios.

---

## 4. Publicación Oficial en GitHub Releases

Al finalizar un sprint y consolidar en `main`, el operador puede ordenar la publicación formal del release:
```bash
bash scripts/agent/promote-to-main.sh --source sprint-XX --push --release
```
El script:
1. Extrae de forma limpia las notas del sprint desde `changelog.md`.
2. Lee la versión canónica de `VERSION`.
3. Ejecuta `gh release create vX.Y.Z --title "vX.Y.Z" --notes-file ...`.
4. Si `gh` no está autenticado o hay desconexión, degrada de forma segura (fail-soft) sin interrumpir la promoción del código.
