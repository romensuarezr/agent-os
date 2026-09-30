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

## 🛠️ Comandos Frecuentes
- `npm run dev`: Arrancar entorno de desarrollo.
- `npm run build`: Validar compilación.
- `npm test`: Ejecutar suite de pruebas.

## ⚖️ Convenciones Específicas
- [Ej: Todos los hooks deben exportar `isLoading`].
- [Ej: Los estilos se gestionan con Vanilla CSS].

---
*Copia este archivo en `.agents/AGENT_ONBOARDING.md` de tu nuevo proyecto y rellena los datos.*
