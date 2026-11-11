# Idea: Integración de Bane (Self-Hosted Deep Research) en el Flujo de Sprint Planning

- **Fecha:** 2026-10-27
- **Origen:** Análisis de alternativas open-source a suscripciones comerciales (Alejavi Rivera: *"Cancelarás Suscripciones! Estas IAs te Regalan TODO GRATIS"*).
- **Estado:** 💡 Capturada para evaluación de roadmap / Sprint futuro.
- **Tipo:** Infraestructura de Flota / Workflow Enhancement (Capa 4 / Tooling Hub).

---

## 1. Referencias y Enlaces Clave
- **Vídeo de referencia:** [Cancelarás Suscripciones! Estas IAs te Regalan TODO GRATIS (YouTube)](https://www.youtube.com/watch?v=Q_QMdobAWWw)
- **Herramienta analizada:** **Bane** (Motor de búsqueda con razonamiento profundo, interfaz clon de Perplexity Pro, de código abierto).
- **Servicios relacionados en nuestra flota:**
  - FreeLLMAPI (`<nodo-inferencia>` sobre Tailscale) como proveedor de inferencia $0.
  - Coolify / Traefik (`<nodo-orquestacion>`) como plataforma de despliegue.
  - `.agents/workflows/sprint-planning.md` como consumidor del servicio en Fase 1.

---

## 2. Separación Arquitectónica (Core vs. Infraestructura)

Para cumplir con el desacoplamiento del Tooling Hub (tool-inventory.md):

1. **Dónde vive el servicio (Infraestructura / Stack VPS):**
   - Bane se despliega como contenedor Docker en el VPS `<nodo-orquestacion>` gestionado vía Coolify (o en `<nodo-inferencia>`), protegido tras reverse proxy Traefik o restringido a la malla privada Tailscale.
   - Consume los modelos de inferencia gratuita de FreeLLMAPI (endpoint OpenAI-compatible; ver fleet.yaml local, no versionado) evitando cualquier coste de API comercial.

2. **Qué vive en el repositorio `agent-os` (Core agnóstico):**
   - **Plantilla Docker:** `templates/bane/docker-compose.yml` para despliegues reproducibles de la comunidad.
   - **Declaración de Flota:** Especificación en `config/fleet.example.yaml` bajo `services.bane` (endpoint y API key opcional).
   - **Mejora del Workflow (`sprint-planning.md`):**
     - En el paso donde el workflow actualmente emite un bloque de texto: `(prompt para Perplexity)`, actualizarlo para permitir dos modos:
       1. *Modo API/CLI determinista:* Si `fleet.yaml` define un endpoint de Bane activo, un script (`scripts/agent/research-query.sh`) puede despachar la búsqueda técnica en background y depositar el resultado en Markdown en `docs/idea-inbox/` o en el sprint draft.
       2. *Modo Prompt Manual:* Generar el prompt con las banderas de razonamiento adecuadas para pegarlo en Bane o en Perplexity Pro indistintamente.

---

## 3. Beneficios y Métricas de Impacto
- **Coste Cero ($0):** Elimina la dependencia de la suscripción de Perplexity Pro ($20/mes) para tareas de prospección y contraste de librerías.
- **Privacidad Total:** Las investigaciones sobre arquitectura propietaria o clientes no se filtran a motores de búsqueda indexados por terceros.
- **Automatización Desatendida:** Permite que un agente en modo headless consulte información de la web en tiempo real sin requerir que un humano abra una pestaña del navegador y copie/pegue el prompt.

---

## 4. Próximos Pasos de Evaluación
- [ ] Validar consumo de memoria y CPU de Bane en Docker (definir el límite en la evaluación; sin cifra de referencia verificada en el core).
- [ ] Probar conexión entre Bane y FreeLLMAPI en un entorno de pruebas.
- [ ] Diseñar el subcomando CLI o la actualización del workflow en `sprint-planning.md`.
