---
trigger: destructive-action
---

# Rule: No Destructive Without Audit

> El agente NUNCA ejecuta operaciones destructivas o irreversibles sin previa auditoría de impacto y confirmación explícita.

---

## 1. Protocolo Obligatorio de Tres Pasos

Antes de ejecutar cualquier comando o mutación irreversible en el sistema de archivos, repositorios git o bases de datos:

1. **Auditoría de Impacto (Pre-Flight)**: Enumera con precisión matemática qué archivos, colecciones, registros o ramas serán afectados.
   - En filesystem: listar rutas exactas que se verán afectadas (e.g. `ls -la <paths>` o dry-run).
   - En base de datos: indicar el conteo de filas/documentos y el predicado exacto del filtro.
   - En Git: mostrar el commit hash de rescate antes de cualquier reseteo o cambio de historial.
2. **Confirmación Explícita o Modo No Destructivo**: No asumas aprobación tácita ni por silencio. Las operaciones irreversibles requieren confirmación explícita del usuario o flags de invocación seguros (e.g., `--dry-run`, backups temporales).
3. **Verificación Post-Acción**: Tras la operación, muestra el estado resultante (`git status`, recuento de registros, estado del directorio) para certificar la ausencia de daños colaterales.

---

## 2. Categorías y Ejemplos de Operaciones Destructivas

### Sistemas de Archivos (POSIX / OS)
- ❌ **Peligro**: `rm -rf <path>`, `find ... -delete`, sobreescritura sin backup de ficheros clave.
- ✅ **Auditoría previa**: Listar el contenido con `ls` o `find` para validar el target exacto antes de borrar.

### Bases de Datos Relacionales (SQL: PostgreSQL, SQLite, MySQL)
- ❌ **Peligro**: Sentencias `DROP TABLE`, `TRUNCATE`, o `DELETE FROM <table>` sin cláusula `WHERE` estricta.
- ✅ **Auditoría previa**: Ejecutar previamente `SELECT count(*) FROM <table> WHERE <condicion>` para cuantificar el impacto exacto y verificar transacciones reversibles (`BEGIN; ... ROLLBACK;`).

### Bases de Datos de Documentos / NoSQL (Ejemplo: Cloud Firestore, MongoDB)
- ❌ **Peligro**: `deleteDoc()`, `db.collection.deleteMany({})`, borrado masivo de colecciones o subcolecciones.
- ✅ **Auditoría previa**: Consultar previamente los IDs afectados mediante queries de solo lectura y respaldar snapshots si la mutación es crítica.

### Control de Versiones (Git)
- ❌ **Peligro**: `git reset --hard`, `git push --force`, `git clean -fdx`, `git branch -D`.
- ✅ **Auditoría previa**: Registrar el SHA del HEAD actual (`git rev-parse HEAD`) y verificar `git status` antes de descartar cambios locales.

