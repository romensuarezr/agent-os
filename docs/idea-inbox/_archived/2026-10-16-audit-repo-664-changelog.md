# Idea: literal engañoso en audit-repo.sh:664 (sugerencia con CHANGELOG.md) — 2026-10-16

**Prioridad:** Baja (engañosa pero inocua) — deuda registrada, no entra a sprint

**Problema:**
`audit-repo.sh:664` genera la propuesta `- [ ] Actualizar CHANGELOG.md con los hitos históricos…`,
apuntando a un fichero que no existe en el core (la convención es `changelog.md` en minúsculas,
que el propio `audit-repo.sh` impone migrando en sus líneas 195-198).

**Decisión (2026-10-16, T-109):**
NO se toca: el contrato de T-109 excluye el fichero y una "excepción de una línea" es scope
creep con otro nombre. Además las líneas 195-198 deben quedar byte-idénticas (la 195 hace
`grep -q` de una cadena exacta), así que cualquier edición en ese fichero exige revisar la
migración entera, no una línea.

**Propuesta (cuando se retome):**
Corregir la 664 junto con una revisión completa del bloque de migración, con caso de regresión
que verifique que `audit-repo.sh --apply` sigue renombrando `CHANGELOG.md` → `changelog.md`.
