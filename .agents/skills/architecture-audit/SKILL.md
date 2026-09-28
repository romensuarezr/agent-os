---
name: architecture-audit
description: Realiza auditorías técnicas del código del proyecto para detectar violaciones de arquitectura, dependencias incorrectas, duplicidades y componentes fuera de su capa. Actívala antes de un refactor o cuando un archivo supere las 300 líneas.
---

# Skill: Architecture Audit (Auditoría Técnica y Limpieza)

Realiza auditorías técnicas profundas y deterministas para asegurar que la base de código respeta la separación de capas, el principio de responsabilidad única (SRP), los límites de dependencias y las reglas DRY del proyecto.

---

## 1. Cuándo Activar este Skill
- **Previo a un refactor**: Para establecer la línea base de acoplamiento y dependencias antes de tocar código.
- **Detección de monolitos**: Cuando un archivo o componente supera las 300 líneas de código útil.
- **Control de fronteras arquitectónicas**: Para validar que la capa de presentación no importe directamente acceso a datos, o que el dominio no dependa de frameworks de infraestructura.
- **Invocación explícita**: Mediante `/audit` o peticiones como *"haz una auditoría de arquitectura de [directorio/módulo]"*.

---

## 2. Comandos Deterministas de Inspección (CLI / Shell)

Antes de quemar tokens de contexto con lecturas masivas, ejecuta comandos deterministas locales para filtrar y cuantificar los puntos críticos:

### A. Detección de Archivos Monolíticos (> 300 líneas)
```bash
# Identifica los 20 archivos más extensos excluyendo vendor, dist y git
find . -type f \( -name "*.ts" -o -name "*.tsx" -o -name "*.py" -o -name "*.go" -o -name "*.rs" -o -name "*.js" \) \
  ! -path "*/node_modules/*" ! -path "*/.git/*" ! -path "*/dist/*" ! -path "*/build/*" ! -path "*/.venv/*" \
  -exec wc -l {} + | sort -rn | head -n 20
```

### B. Mapeo de Violaciones de Capas (Imports Cruzados)
```bash
# Ejemplo: Detectar acceso directo a base de datos (knex, prisma, orm, pg, sql) en componentes UI o rutas
grep -rnE "(from ['\"].*(prisma|typeorm|pg|mysql|database|db)['\"]|import .*db)" src/components/ src/views/ src/pages/ 2>/dev/null

# Ejemplo: En Python, detectar imports de infraestructura en modelos de dominio puro
grep -rnE "^from .*(infra|database|http_client|repository) import" domain/ core/ 2>/dev/null
```

### C. Detección de Acoplamiento y Dependencias Circulares
```bash
# En proyectos Node.js/TypeScript (usando npx madge si está disponible):
npx --yes madge --circular --extensions ts,tsx,js src/ 2>/dev/null || true

# En proyectos Python (usando grep determinista sobre imports relativos profundos):
find . -name "*.py" -exec grep -Hn "from \.\.\." {} +
```

### D. Búsqueda de Lógica Duplicada o Boilerplate Repetido
```bash
# Localizar bloques repetitivos de catch o manejo genérico de error no centralizado
grep -rnE "(catch \([a-zA-Z0-9_]+\) \{|except Exception as [a-zA-Z0-9_]+:)" src/ | wc -l
```

---

## 3. Protocolo de Auditoría Paso a Paso

1. **Lectura de Topología**: Lee `.agents/AGENT_ONBOARDING.md` para entender el stack activo y las fronteras de carpetas declaradas.
2. **Filtrado Determinista**: Corre los comandos CLI anteriores para recopilar métricas objetivas (líneas de código, imports prohibidos, acoplamientos circulares).
3. **Inspección Focalizada**: Inspecciona únicamente los archivos que han superado los umbrales de alerta (`> 300` líneas o con imports anómalos).
4. **Evaluación de Principios**:
   - **SRP (Single Responsibility)**: ¿El archivo mezcla presentación, estado, validación y persistencia?
   - **DRY (Don't Repeat Yourself)**: ¿Hay duplicación de esquemas, transformadores de datos o llamadas HTTP idénticas?
   - **Límites de Capa**: ¿La capa superior accede a detalles internos de la capa inferior sin mediación de interfaz o contrato?

---

## 4. Plantilla de Reporte de Auditoría

Toda ejecución de este skill debe generar un informe estructurado siguiendo este formato:

```markdown
### Resumen Ejecutivo de Auditoría
- **Módulos auditados**: `src/features/billing/`
- **Archivos fuera de norma (>300 líneas)**: 2 archivos
- **Violaciones de límites de capa**: 3 incidencias detectadas

### Tabla de Incidencias

| Archivo | Líneas | Severidad | Violación Detectada | Recomendación / Remediación |
|---|---|---|---|---|
| `src/views/Checkout.tsx` | 420 | 🔴 ALTA | Lógica de cálculo fiscal y llamada directa a stripe SDK dentro del componente UI | Extraer cálculo a `useCheckoutTax` y llamada SDK a `billingService.ts` |
| `src/services/api.ts` | 510 | 🟡 MEDIA | Monolito de endpoints con duplicación de headers y auth | Dividir por dominios (`usersApi.ts`, `ordersApi.ts`) |
| `src/domain/user.py` | 180 | 🔴 ALTA | Importa `psycopg2` directamente dentro de entidad de dominio | Invertir dependencia: definir interfaz de repositorio |

### Plan de Refactor Sugerido (Atómico y Priorizado)
1. **Paso 1 (Seguridad / Capas)**: Aislar llamadas SDK externas en servicios dedicados.
2. **Paso 2 (Monolitos)**: Modularizar archivos de más de 300 líneas extrayendo hooks / helpers.
3. **Paso 3 (DRY)**: Centralizar middleware de manejo de errores y clientes HTTP.
```

