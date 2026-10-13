# Agent Onboarding Template

> Guía rápida para que el agente entienda este repositorio.

## 🩺 Pre-flight de Inicio de Sesión (Salud del Repositorio)
Antes de iniciar cualquier tarea o planificar trabajo, ejecuta la auditoría de salud local de Agent OS:
```bash
bash scripts/agent/audit-child.sh
```
**Interpretación obligatoria del resultado:**
- `✅ CONFORME`: El entorno y configuración están sincronizados y estables. Operar normal.
- `⚠️ DRIFT DETECTADO`: Se detectaron advertencias o desactualización (>7 días, configs obsoletas). Informar al usuario y proponer sincronización (`bash scripts/agent/sync.sh`).
- `❌ NO CONFORME`: Fallos estructurales críticos, permisos corruptos o desactualización severa. No improvisar: acogerse estrictamente a `.agents/rules/global/deterministic-execution.md` para subsanar antes de intervenir el código.

## 🚀 Stack Tecnológico
- **Frontend**: [React / Next.js / etc.]
- **Backend**: [Node.js / Python / etc.]
- **Database**: [Firestore / PostgreSQL / etc.]
- **Infra**: [Docker / Vercel / etc.]

## 📂 Estructura de Carpetas Clave
- `src/components/`: Componentes UI.
- `src/hooks/`: Lógica de estado y side-effects.
- `lib/`: Servicios de datos y utilidades core.
- `docs/`: Documentación del proyecto y sprints.

## 🔐 Gestión de Secretos
Los secretos **nunca** viven en el repositorio. Se resuelven en tiempo de ejecución desde el gestor de secretos.

> [!CAUTION]
> No ejecutes `infisical secrets` para inventariar: imprime los **valores** en claro y los
> vuelca en el contexto de la sesión y en el log. Para listar o buscar, usa el localizador.

```bash
# ¿Dónde vive esta clave? (solo nombres, nunca valores)
bash scripts/agent/secret-locate.sh --name NOMBRE_DE_LA_CLAVE

# Inventario de carpetas y su número de claves
bash scripts/agent/secret-locate.sh --list
```

**Protocolo si el secreto no está en la carpeta de este proyecto**:
1. Usa `secret-locate.sh --name`. **No** adivines carpeta por carpeta ni lo pidas al usuario.
2. Si la clave aparece en varias carpetas, es una clave compartida o duplicada: revisa
   `--audit` antes de usarla.
3. Consume siempre de forma efímera, sin escribir a disco:
   ```bash
   infisical run --path=/<carpeta> -- bash -c 'miapp'
   ```

- **Carpeta compartida**: un secreto consumido por **2 o más** proyectos vive en la carpeta
  compartida con `scope=shared`. Uno específico de este proyecto, en su propia carpeta.
- **Nunca repliques** un secreto a otra carpeta "porque ya se usó aquí": multiplica la
  superficie de revocación.
- **Detalle completo**: `.agents/skills/infisical-secrets/SKILL.md` (taxonomía, shadowing y rotación).

## 🛠️ Comandos Frecuentes
- `npm run dev`: Arrancar entorno de desarrollo.
- `npm run build`: Validar compilación.
- `npm test`: Ejecutar suite de pruebas.

## ⚖️ Convenciones Específicas
- [Ej: Todos los hooks deben exportar `isLoading`].
- [Ej: Los estilos se gestionan con Vanilla CSS].

---
*Copia este archivo en `.agents/AGENT_ONBOARDING.md` de tu nuevo proyecto y rellena los datos.*
