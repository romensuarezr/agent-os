---
trigger: deployment-safety
---

# Rule: Deployment Safety & Stability

> Reglas agnósticas para evitar regresiones, bloqueos en importación y crashes en entornos de ejecución.

---

## 1. Zero-Conn at Module Evaluation (Lazy Initialization)

**Principio universal**: NUNCA abras sockets, pools de red o conexiones síncronas a bases de datos o servicios externos en el tiempo de evaluación/importación del módulo (`import`, `require`, `use`, `include`). La conexión debe residir en la fase explícita de arranque (`bootstrap`/`lifespan`) o instanciarse bajo demanda (lazy factory / dependency injection).

### Ejemplo (Node.js / TypeScript / Express)
- ❌ **Mal**: `const db = connectDB();` a nivel superior de archivo. Si la base de datos o el túnel no están listos al importar la ruta, crashea el proceso completo o rompe la suite de tests unitarios.
- ✅ **Bien**: Conectar dentro de la función de arranque (`async function bootstrap() { await db.connect(); app.listen(...); }`) o exportar un getter con lazy initialization.

### Ejemplo (Python / FastAPI)
- ❌ **Mal**: `engine = create_engine(DATABASE_URL); engine.connect()` en el cuerpo principal de `database.py`.
- ✅ **Bien**: Usar el gestor de ciclo de vida (`@asynccontextmanager async def lifespan(app)`) o inicializar el pool de conexiones en el evento startup.

### Ejemplo (Go / Rust)
- ❌ **Mal**: Funciones `init()` en Go que intentan autenticar contra servicios externos y ejecutan `panic()` si el servicio no responde inmediatamente.
- ✅ **Bien**: Inyección de dependencias explícita: inicializar clientes en `main()` y pasarlos como interfaces a los constructores del dominio.

---

## 2. Robust Configuration & Fail-Fast Pre-flights

- Valida la presencia y tipo de variables críticas **antes** de que la aplicación empiece a aceptar tráfico.
- Si falta una variable obligatoria, aborta con un mensaje de diagnóstico que indique exactamente qué clave falta (sin exponer su valor).
- Maneja errores de lectura de archivos de configuración (`.yaml`, `.json`, `.env`) de forma elegante y determinista.

---

## 3. Environment Isolation & Secret Safety

- Asegúrate de que las credenciales y URLs de desarrollo/staging nunca se filtren a producción ni queden hardcodeadas.
- Sigue la política L3 de manejo de secretos (ver `agent-permissions.md` y `deterministic-execution.md`): inyección vía variables de entorno o almacén centralizado (e.g., Infisical/Vault), nunca commits de valores sensibles.

---

## 4. Local-First Validation Pipeline

Antes de promover código o desplegar a cualquier entorno:
1. **Compilación / Linting / Tipos**: Verifica que el código compila y pasa el linter del stack correspondiente sin advertencias críticas.
2. **Instanciación y Tests de Unidad**: Comprueba que los servicios y módulos modificados se instancian en aislamiento.
3. **Smoke Test Local**: Ejecuta el servidor, contenedor o worker localmente y valida en los logs que no existan errores fatales ni advertencias de configuración.

