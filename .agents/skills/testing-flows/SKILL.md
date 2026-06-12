---
name: testing-flows
description: Guía de arquitectura de pruebas y testing para flujos de trabajo en tres niveles. Instruye sobre la detección de frameworks y diseño de tests unitarios, de integración y E2E.
---

# Skill: Testing Flows (Arquitectura de Pruebas)

Esta habilidad guía al agente en el diseño y la implementación de pruebas automatizadas cubriendo los flujos críticos de la aplicación en tres niveles (unitario, integración, E2E), adaptándose dinámicamente al stack tecnológico del proyecto.

## 1. Detección del Framework de Testing (Guardia Obligatoria)

Antes de proponer o escribir cualquier prueba, el agente **debe** identificar las herramientas y frameworks que ya están configurados en el proyecto. 
Para ello, el agente seguirá este flujo:

1. **Ecosistema Node.js / Web**:
   - Inspeccionar el archivo `package.json`.
   - Buscar dependencias de testing:
     - **Vitest**: busca `"vitest"` en dependencias o scripts.
     - **Jest**: busca `"jest"`.
     - **Playwright**: busca `"@playwright/test"`.
     - **Cypress**: busca `"cypress"`.
     - **React Testing Library**: busca `"@testing-library/react"`.
2. **Ecosistema Python**:
   - Inspeccionar `pyproject.toml` o `requirements.txt`.
   - Buscar dependencias:
     - **pytest**: busca `pytest`.
     - **unittest**: librería estándar.
3. **Otros Ecosistemas**:
   - Inspeccionar archivos de configuración en la raíz (ej: `jest.config.js`, `vitest.config.ts`, `playwright.config.ts`, `pytest.ini`).

*Si no existe ningún framework configurado, el agente debe reportarlo y proponer al usuario la instalación de la opción más adecuada según el stack del proyecto (utilizando `tech-scout` si es necesario).*

---

## 2. Los Tres Niveles de Testing

### Nivel 1 — Tests Unitarios (Unit Testing)
- **Propósito**: Probar funciones puras, utilidades, helpers y componentes visuales de forma aislada.
- **Enfoque**:
  - Evitar llamadas a bases de datos o red.
  - Usar mocks rápidos de dependencias externas.
  - Ejemplo en JavaScript/TypeScript (Vitest/Jest):
    ```typescript
    import { formatCurrency } from './utils';

    describe('formatCurrency', () => {
      it('debería formatear correctamente un valor decimal', () => {
        expect(formatCurrency(1234.56)).toBe('$1,234.56');
      });
    });
    ```

### Nivel 2 — Tests de Integración (Integration Testing)
- **Propósito**: Probar la interacción entre componentes, la lógica de controladores, hooks de estado y servicios que interactúan con APIs o bases de datos (usando emuladores o bases de datos de prueba).
- **Enfoque**:
  - Utilizar emuladores locales si están configurados (ej: Firebase Emulator, contenedores de testcontainers).
  - Simular el ciclo de vida completo de un controlador o un flujo de almacenamiento.
  - Ejemplo en Python (pytest con base de datos en memoria):
    ```python
    def test_create_user_saves_to_database(db_session):
        user_service = UserService(db_session)
        user = user_service.create_user(email="test@example.com")
        assert user.id is not None
        assert db_session.query(User).filter_by(email="test@example.com").first() is not None
    ```

### Nivel 3 — Tests End-to-End (E2E)
- **Propósito**: Validar que el flujo completo del usuario funcione en el navegador o entorno real, desde el inicio del proceso hasta el resultado final.
- **Enfoque**:
  - Utilizar herramientas de automatización de navegador (ej: Playwright, Cypress).
  - Interactuar con los elementos del DOM simulando clicks, tipeos y esperas de red.
  - Ejemplo con Playwright:
    ```typescript
    import { test, expect } from '@playwright/test';

    test('flujo de login correcto', async ({ page }) => {
      await page.goto('/login');
      await page.fill('input[type="email"]', 'user@example.com');
      await page.fill('input[type="password"]', 'secure-password');
      await page.click('button[type="submit"]');
      await expect(page).toHaveURL('/dashboard');
    });
    ```

---

## 3. Convenciones y Buenas Prácticas
- **Nombres descriptivos**: Los bloques `describe` e `it` / `test` deben explicar con claridad el comportamiento esperado.
- **Mocking**: Mantener los mocks lo más sencillos posible para evitar tests frágiles que se rompan ante refactors de implementación interna.
- **Independencia**: Cada test debe ser capaz de ejecutarse de forma aislada y no debe depender del resultado o estado de los tests anteriores (limpiar bases de datos o estados en `afterEach` o `beforeEach`).
