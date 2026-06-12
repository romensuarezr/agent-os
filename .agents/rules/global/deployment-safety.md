# Rule: Deployment Safety & Stability

> Reglas para evitar regresiones y crashes en entornos de ejecución.

## 1. Lazy Initialization (Zero-Conn Policy)
NUNCA inicialices conexiones a DBs o APIs externas en el nivel superior del módulo.
- **Mal**: `const db = connectDB();` (Crashea si la DB no está lista al arrancar el proceso).
- **Bien**: Inicializa en un evento de `startup` o mediante un getter que conecte bajo demanda.

## 2. Robust Configuration
Valida siempre la existencia de archivos de configuración antes de intentar abrirlos. Maneja errores de lectura de forma elegante.

## 3. Environment Isolation
Asegúrate de que las credenciales y URLs de desarrollo/staging nunca se filtren a producción. Usa archivos `.env` específicos y validados por la CLI.

## 4. Local-First Validation
Antes de hacer un push:
1. **Compilación/Lint**: Verifica que el código compila y pasa el linter.
2. **Instanciación**: Verifica que las clases/servicios modificados pueden instanciarse sin errores.
3. **Smoke Test**: Ejecuta el motor o servidor localmente y verifica que los logs estén limpios de errores críticos.
