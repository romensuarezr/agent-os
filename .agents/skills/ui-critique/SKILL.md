---
name: ui-critique
description: Auditoría heurística y revisión estética, técnica y de accesibilidad de interfaces frontend (React / Tailwind / Next.js) en proyectos satélite.
---

# Skill: UI Critique (Auditoría Heurística y Calidad de Interfaces)

Guía metodológica y operativa de inspección determinista para evaluar la calidad estética, solidez estructural, ergonomía de interacción y accesibilidad (WCAG AA) de interfaces frontend en proyectos satélite del ecosistema Agent OS (React, Next.js, Tailwind CSS).

---

## 1. Cuándo Activar esta Skill

- **Revisión previa a Pull Request**: Antes de dar por concluida cualquier tarea que altere vistas, layouts o componentes de usuario.
- **Auditoría visual periódica**: Para evaluar la consistencia del sistema de diseño (design system drift) en repositorios satélite.
- **Refactorización de UI**: Antes de migrar estilos inline o clases utilitarias ad-hoc hacia componentes de diseño reutilizables.
- **Petición explícita**: Cuando el usuario solicite *"haz una crítica de diseño"*, *"audita la interfaz"* o *"revisa la UI de esta pantalla"*.

---

## 2. Las 5 Dimensiones Heurísticas de Evaluación

Toda interfaz debe auditarse a través de 5 dimensiones fundamentales:

### Dimensión 1: Jerarquía Tipográfica y Escala Modular
- **Escala armónica**: Uso estricto de la escala tipográfica estándar (`text-xs`, `text-sm`, `text-base`, `text-lg`, `text-xl`, `text-2xl`, etc.). Prohibido el uso de tamaños arbitrarios no documentados (ej: `text-[13px]`) salvo justificación extrema.
- **Contraste de pesos**: Diferenciación clara entre encabezados (`font-semibold`/`font-bold`) y cuerpo de texto (`font-normal`).
- **Medida y ritmo vertical (Leading/Tracking)**: Interlineado proporcional al tamaño (`leading-relaxed` en párrafos densos, `leading-tight` en títulos grandes). Ancho máximo de línea óptimo para lectura (`max-w-prose` / 60–75 caracteres).

### Dimensión 2: Consistencia Espacial y Sistema de Espaciado (Spacing Tokens)
- **Regla del múltiplo de 4px / 8px**: Todos los márgenes, paddings y gaps deben corresponder a la escala base de Tailwind (`p-2` = 8px, `p-4` = 16px, `p-6` = 24px, `p-8` = 32px).
- **Densidad y aire visual**: Proporción equilibrada entre espacio blanco (negative space) y densidad de información. Los elementos relacionados deben estar más próximos entre sí que los independientes (Ley de Proximidad de Gestalt).
- **Alineación de rejilla (Grid/Flex Layout)**: Sin desajustes de 1px o bordes flotantes no alineados.

### Dimensión 3: Contraste de Color y Accesibilidad (WCAG AA)
- **Ratio de contraste mínimo**:
  - Texto estándar: Contraste mínimo de **4.5:1** contra el fondo.
  - Texto grande (≥18pt o ≥14pt bold): Contraste mínimo de **3:1**.
  - Componentes gráficos e iconos interactivos: Mínimo **3:1**.
- **Estados interactivos visibles**: Todo elemento interactivo (`<button>`, `<a>`, `<input>`) debe exponer estados perceptibles para `hover`, `active`, y fundamentalmente `focus-visible` (anillo de foco accesible sin romper estética).
- **Semántica HTML y ARIA**: Uso de etiquetas semánticas (`<header>`, `<nav>`, `<main>`, `<article>`, `<button>`) en lugar de `<div>` con manejadores onClick. Atributos `aria-label` o `aria-expanded` en controles sin texto visual.

### Dimensión 4: Enfoque DRY en Componentes UI y Variantes Reutilizables
- **Cero duplicación de clases complejas**: Listas de clases Tailwind idénticas repetidas en más de 2 ubicaciones deben encapsularse en componentes reutilizables (ej: `Button`, `Badge`, `Card`, `Input`).
- **Composición declarativa**: Uso de bibliotecas de variantes limpias (como `cva` - *class-variance-authority* o utilidades `cn() / clsx + tailwind-merge`).
- **Separación de responsabilidades**: Componentes puramente presentacionales desacoplados de llamadas directas a APIs o lógica de negocio pesada.

### Dimensión 5: Adaptabilidad Responsive y Ergonomía Móvil
- **Filosofía Mobile-First**: Los estilos base deben apuntar a pantallas reducidas, agregando breakpoints ascendentes (`sm:`, `md:`, `lg:`, `xl:`).
- **Zero Scroll Horizontal**: Ningún viewport móvil (320px–390px) debe generar desbordamiento horizontal involuntario (`overflow-x: hidden` defensivo no sustituye la corrección del layout).
- **Zonas táctiles (Touch Targets)**: Elementos interactivos en pantallas táctiles deben disponer de un área interactiva mínima de **44x44 px** (o espaciado circundante suficiente para prevenir pulsaciones erróneas).

---

## 3. Comandos Deterministas de Detección ($0 Tokens)

Antes de realizar análisis manuales, ejecuta estas comprobaciones deterministas rápidas en el proyecto satélite:

### A. Detección de Valores Arbitrarios en Tailwind CSS
```bash
# Busca valores arbitrarios entre corchetes (ej: w-[231px], text-[#123456], p-[13px])
grep -rnE '(p|m|px|py|pt|pb|pl|pr|w|h|text|bg|border)-\[[^]]+\]' src/ app/ components/ 2>/dev/null | head -n 30
```

### B. Detección de Estilos Inline en JSX/TSX
```bash
# Localiza uso de style={{ ... }} que evade el sistema de diseño
grep -rnE 'style=\{\{' src/ app/ components/ 2>/dev/null | head -n 20
```

### C. Detección de Botones no Semánticos (Divs clickables sin accesibilidad)
```bash
# Busca divs o spans con onClick que deberían ser <button> nativos
grep -rnE '<(div|span)[^>]*onClick' src/ app/ components/ 2>/dev/null
```

### D. Verificación de Focus States en Controles Interactivos
```bash
# Detecta botones o enlaces sin clase focus o focus-visible
grep -rnE '<(button|a)[^>]*className=' src/ app/ components/ 2>/dev/null | grep -v 'focus' | head -n 25
```

---

## 4. Estructura del Informe de Crítica UI

Al presentar una auditoría o propuesta de mejora de interfaz, estructura la respuesta bajo este esquema claro:

```markdown
### 🎨 Auditoría de Calidad UI: [Nombre de la Vista / Componente]

#### 1. Diagnóstico por Dimensión
- **Jerarquía Tipográfica**: [OK | Hallazgos de inconsistencia]
- **Consistencia Espacial**: [OK | Desvíos de escala o padding]
- **Accesibilidad y Contraste**: [Ratios medidos, focus states y tags semánticos]
- **Arquitectura de Componentes (DRY)**: [Oportunidades de extracción o limpieza]
- **Comportamiento Responsive**: [Rendimiento en 360px, 768px y 1280px]

#### 2. Puntos Críticos y Hallazgos Específicos
- `[Archivo:Línea]` — Descripción del defecto visual o de accesibilidad.

#### 3. Propuesta de Corrección (Antes vs Después)
```tsx
// ❌ Antes: Clases ad-hoc duplicadas y sin accesibilidad
<div onClick={handleClick} className="bg-[#0070f3] text-white p-[11px] rounded-[5px]">
  Continuar
</div>

// ✅ Después: Componente semántico, tipado, accesible y en sistema
<Button variant="primary" size="md" onClick={handleClick}>
  Continuar
</Button>
```
```

---

## 5. Reglas Invariantes

1. **Nunca degradar accesibilidad**: Ningún rediseño cosmético puede eliminar estados de foco visibles ni reducir ratios de contraste por debajo de WCAG AA.
2. **Priorizar el Design System existente**: Respeta siempre `tailwind.config.*` o el token catalog del satélite antes de sugerir nuevos tokens.
3. **Refactorización no destructiva**: Todo cambio estético debe conservar el comportamiento funcional y los contratos de eventos originales.
