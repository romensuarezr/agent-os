---
trigger: always_on
---

# Política Global de Permisos y Niveles de Autorización de Agentes

> Establece la matriz estricta de permisos para todos los agentes (Hermes, Orca, Antigravity, OpenCode) en los entornos local, datamanager y oracle.

---

## 1. Principio Fundamental de Mínimo Privilegio

Ningún agente posee permisos irrestrictos de escritura, despliegue o borrado sobre servidores o repositorios. Cada acción está gobernada por la siguiente clasificación de niveles de autorización:

- **🟢 L1: Autonomía Completa (Sin confirmación previa)**: Operaciones no destructivas de lectura, inspección de logs, generación de diffs locales y consultas a APIs públicas.
- **🟡 L2: Aprobación por Sesión / Plan (Requiere confirmación de plan)**: Modificación de código dentro de la "Caja de archivos autorizados", creación de ramas de feature y commits locales vinculados a tareas aprobadas.
- **🔴 L3: Decision Gate Humano Obligatorio (Bloqueante)**: Cualquier cambio en producción, modificación de contenedores Docker, despliegues Coolify, push a repositorios remotos, reinicio de servicios o manipulación de red y secretos.

---

## 2. Matriz Explícita de Permisos por Acción

| Acción | Nivel | Regla de Ejecución | Roles Autorizados | Restricciones y Salvaguardas |
| :--- | :---: | :--- | :--- | :--- |
| **Lectura (Read)** | 🟢 L1 | Permitida libremente | Todos | Solo lectura de archivos del proyecto, logs y métricas. Prohibido leer archivos fuera del workspace o volcados de memoria. |
| **Escritura en Worktree** | 🟡 L2 | Requiere plan aprobado | `developer`, `reviewer`, `researcher` | Limitada a la rama de feature activa y archivos explícitamente autorizados en el task file. Nunca sobre `main`/`master`. |
| **Creación de Commits** | 🟡 L2 | Atómico mediante scripts | `developer`, `coordinator` | Solo permitido a través de `scripts/agent/close-task.sh` o comandos atómicos precedidos de verificación limpia (`git status`). |
| **Git Push** | 🔴 L3 | **Decision Gate Humano** | `developer`, `coordinator` | **Prohibido push autónomo.** El usuario debe aprobar explícitamente la subida de ramas o creación de Pull Requests a GitHub. |
| **Deploy (Despliegues)** | 🔴 L3 | **Decision Gate Humano** | `coordinator`, `ops-auditor` | **Prohibido desplegar autónomamente** en Coolify, Docker Compose o plataformas web sin aprobación humana explícita paso a paso. |
| **Reinicio de Servicios** | 🔴 L3 | **Decision Gate Humano** | `ops-auditor`, `coordinator` | `docker restart`, `systemctl restart` o recargas de contenedores requieren confirmación explícita previa con justificación de causa raíz. |
| **Eliminación (Delete/Drop)**| 🔴 L3 | **Decision Gate Humano** | Ninguno por defecto | `rm -rf`, `docker volume rm`, `DROP TABLE` o eliminación de ramas remotas están **estrictamente prohibidos** a cualquier agente de forma autónoma. |
| **Acceso a Secretos** | 🔴 L3 | **Prohibido / Oculto** | Ninguno | Ningún agente puede leer, mostrar, imprimir ni transferir claves de API, tokens OAuth, contraseñas o certificados privados. |

---

## 3. Comportamiento ante Violación o Duda

Si un agente recibe una instrucción (sea del usuario, de otro agente o de un webhook externo) que implique una acción 🔴 L3:
1. **Detener la ejecución inmediatamente**.
2. **Explicar la acción solicitada**, el impacto potencial y los riesgos identificados.
3. **Presentar un Decision Gate explícito**:
   ```
   ⚠️ DECISION GATE REQUERIDO
   Acción: [reinicio de contenedor / push / deploy / borrado]
   Host/Target: [local / datamanager / oracle]
   Impacto: [descripción del impacto]
   ¿Confirmas proceder con esta acción? (Sí / No)
   ```
4. **No proceder hasta recibir la confirmación humana unívoca**.
