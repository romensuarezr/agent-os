# Definition of Done (DoD) Global

> Criterios de calidad que debe cumplir TODA tarea antes de ser considerada finalizada.

## 1. Integridad del Código
- [ ] El código compila sin errores.
- [ ] No se han introducido warnings de linter significativos.
- [ ] No hay código comentado, `console.log` o `print` de depuración innecesarios.
- [ ] Los nombres de variables y funciones siguen la convención del proyecto (inglés).

## 2. Arquitectura y Diseño
- [ ] Se respeta la arquitectura del proyecto (ej: DRY, separación de capas).
- [ ] No hay lógica duplicada; se han reutilizado componentes/helpers si existían.
- [ ] Las decisiones técnicas se han explicado siguiendo el patrón QUÉ/POR QUÉ/TRADE-OFF.

## 3. Seguridad y Estabilidad
- [ ] No se han expuesto credenciales o secretos en el código.
- [ ] Se han validado los inputs y manejado los errores potenciales (try/catch).
- [ ] El cambio no rompe flujos existentes (verificación manual o tests).

## 4. Documentación y Git
- [ ] Se han actualizado los archivos de documentación si el cambio lo requería (README, ADR, Roadmap).
- [ ] El commit se ha realizado en una feature branch (no directo a main).
- [ ] El mensaje de commit es descriptivo.

---
*Este documento es el estándar base. Cada proyecto puede añadir criterios específicos en su propio `.agents/DEFINITION_OF_DONE.md`.*
