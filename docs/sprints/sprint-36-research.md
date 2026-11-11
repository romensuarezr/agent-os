# Research Sprint 36
> Fuente: Scout determinista (`scout.sh`, $0 tokens) + SearXNG — 2026-11-11
> Tareas: T-196 … T-200 (paquete de gobernanza de contexto, seguridad defensiva e inferencia)

## Descubrimientos Scout (por tarea)

### T-196
- **Consulta scout**: `knowledge hierarchy rules human operator directives vs synthetic AI generated context governance`
- **Alternativas detectadas**: sin repos ni paquetes OSS maduros relevantes en el registro consultado.
- **Recomendación**: `Desarrollo a medida justificado` — reglas agnósticas propias del core en `.agents/rules/global/`, sin dependencias externas, cumpliendo portabilidad y coste $0.

### T-197
- **Consulta scout**: `token context weight audit orphan skills manifest lines tokens`
- **Alternativas detectadas**: paquetes npm ajenos al problema (`js-tokens`, `parse-statements`, `@sanity-labs/design-tokens`) — sin aplicabilidad.
- **Recomendación**: `Desarrollo a medida justificado` — extensión determinista de `scripts/agent/inspect-skills.sh` (script existente del core, señal⚠️ leído, no recreado). Se reutiliza la base de inspección estática existente.

### T-198
- **Consulta scout**: `openai compatible gateway provider catalog deepseek nvidia nim freellmapi`
- **Alternativas detectadas**: sin repos ni paquetes relevantes en NPM/GitHub para un catálogo de conectores.
- **Recomendación**: `Desarrollo a medida justificado` — declaración de proveedores en `templates/freellmapi/config/freellmapi.config.json` (existente, se enriquece) y del rol `advisor` en `.agents/config/routing-policy.yaml` (existente, 118 líneas, sin rol advisor hoy).

### T-199
- **Consulta scout**: `static security audit scanner JWT authorization IDOR OWASP`
- **Alternativas detectadas**: `saas-security-audit` (npm v0.11.0, scanner SaaS/tenant-isolation — alcance distinto), `oauth4webapi`/`oidc-provider` (librerías de flujo OAuth, no escáneres estáticos). Ninguna alcanza el umbral de madurez ≥500⭐ con licencia permisiva verificable en la prospección.
- **Recomendación**: `Desarrollo a medida justificado` — skill de escaneo estático agnóstica basada en patrones deterministas, apoyada en reglas existentes (`agent-permissions.md`) sin dependencias de pago.

### T-200
- **Consulta scout**: `idea validation viability scoring bias detection skill`
- **Alternativas detectadas**: sin repos relevantes; único matiz `@skill-harness/core` (LLM-judge grading, dependencia interna de terceros con API — no adoptable bajo soberanía $0).
- **Recomendación**: `Desarrollo a medida justificado` — veredicto numérico calculado con prospección determinista propia (`searxng-search.py` + `scout.sh`), cero APIs comerciales.

## Consultas SearXNG (Paso 5 — autónomo)
<!-- Secciones de resultados por tarea insertadas por searxng-client.sh -->

### T-196 / T-197 — Bypass interno declarado

> Investigación web externa no requerida: tareas de alcance puramente interno/core (redacción de reglas globales y extensión determinista de un script local sin incertidumbre externa).

### T-198 — Consulta SearXNG

## Resultados de Búsqueda Soberana: OpenAI compatible API gateway provider configuration DeepSeek MoE Nvidia NIM endpoint base_url models catalog

1. **[Get Started with DeepSeek-V4-Pro-0813 - NVIDIA Documentation Hub](https://docs.nvidia.com/nim/large-language-models/2.0.13/get-started/advanced/get-started-deepseek-v4-pro-0813.html)** `[google cse]`
   19 oct 2026 ... When creating the Personal API key, select at least NGC Catalog from the Services Included list. ... The NIM exposes OpenAI-compatible inference ...

2. **[NVIDIA NIM | AI SDK](https://ai-sdk.dev/providers/openai-compatible-providers/nim)** `[brave]`
   import { createOpenAICompatible } from '@ai-sdk/openai-compatible'; import { streamText } from 'ai'; const nim = createOpenAICompatible({ name: 'nim', baseURL: 'https://integrate.api.nvidia.com/v1', headers: { Authorization: `Bearer ${process.env.NIM_API_KEY}`, }, }); const result = streamText({ model: nim.chatModel('deepseek-ai/deepseek-r1'), prompt: 'Tell me the history of the Northern White Rhino.', }); for await (const textPart of result.textStream) { process.stdout.write(textPart); } console.log(); console.log('Token usage:', await result.usage); console.log('Finish reason:', await result.finishReason);

3. **[Stop Paying $20/month. Use NVIDIA Build: 80+ Free AI Models](https://dev.to/lorenzojkrl/stop-paying-20month-use-nvidia-build-80-free-ai-models-17ih)** `[google cse]`
   17 jun 2026 ... Install Cline from the VS Code or Cursor Marketplace; Open Cline settings and select OpenAI Compatible as the provider; Set the base URL to ...

4. **[NVIDIA Build Free API: 100+ AI Models on DGX Cloud (2026 Guide)](https://pasqualepillitteri.it/en/news/1621/nvidia-build-free-api-100-ai-models-2026)** `[brave]`
   NVIDIA Build offers a catalog of more than 100 AI models accessible for free through an OpenAI-compatible API · NVIDIA Build is the operational portal for the NVIDIA NIM project (NIM stands for NVIDIA Inference Microservices, prepackaged microservices that run LLM models, that is Large Language Models, on NVIDIA GPUs with optimized TensorRT-LLM).

5. **[deepseek-v4-pro-0813 Model by Deepseek-ai | NVIDIA NIM](https://build.nvidia.com/deepseek-ai/deepseek-v4-pro-0813)** `[google cse]`
   26 ago 2026 ... DeepSeek V4 scales to 262K-token context windows with efficient MoE architecture for coding tasks.

6. **[NVIDIA NIM Free Developer Tier: OpenAI-Compatible API Setup](https://news.creeta.com/en/nvidia-nim-openai-compatible-free-tier/)** `[brave]`
   Model families include Meta Llama, Mistral, NVIDIA Nemotron, DeepSeek, Qwen, Moonshot AI's Kimi K2, Google Gemma, Microsoft Phi, and IBM Granite, with concrete IDs such as meta/llama-3.3-70b-instruct and moonshotai/kimi-k2-instruct documented ...

7. **[DeepSeek V4 Flash Free Access: July Findings and Current Ofox ...](https://ofox.ai/blog/deepseek-v4-flash-free-zero-cost-paths-2026/)** `[google cse]`
   14 jul 2026 ... A free API for an agent loop, NVIDIA NIM developer tier, OpenAI-compatible, tool calling, Escape the ~40 req/min rate cap. Try the model in a ...

8. **[DeepSeek V4: Specs, Pricing, Benchmarks, and How to Run It (2026)](https://www.morphllm.com/deepseek-v4)** `[google cse]`
   DeepSeek V4 is an open-weight MoE family under MIT. Since September 10, 2026 the API serves V4.1-Flash (552B, 8B input / 16B output active, $0.15/$0.

9. **[NVIDIA NIM | Promptfoo](https://www.promptfoo.dev/docs/providers/nvidia/)** `[brave]`
   The NVIDIA provider connects promptfoo to NVIDIA's hosted inference API at https://integrate.api.nvidia.com/v1. The endpoint is OpenAI-compatible, so any model NVIDIA exposes through it can be used the same way you'd use OpenAI Chat Completions.

10. **[LLM APIs](https://docs.api.nvidia.com/nim/reference/llm-apis)** `[brave]`
   NOTE: Select models are available as downloadable container images and supported with an NVIDIA AI Enterprise entitlement. These select models have additional OpenAI API spec details for running self-hosted localized NIMs.

### T-199 — Consulta SearXNG

## Resultados de Búsqueda Soberana: deterministic static analysis pattern JWT signature verification authorization route checks IDOR detection source code scanner

1. **[GitHub - momenbasel/vulnhawk](https://github.com/momenbasel/vulnhawk)** `[google cse]`
   AI-powered SAST scanner that finds auth bypass, IDOR, and logic bugs Semgrep/CodeQL miss. Free GitHub Action. Supports Python, JS/TS, Go, PHP, Ruby.

2. **[Why half your AI SAST findings are wrong (and how to fix them)](https://derivai.substack.com/p/ai-can-find-vulnerabilities-but-it)** `[brave]`
   Endpoints accepting identity parameters that don’t route through your ownership validation function. That’s a potential IDOR. You confirm it by searching the codebase for everywhere that the identity parameter flows and checking which middleware chains include the authorization check. Webhook handlers that might not validate signatures.

3. **[Lonkero - Wraps around your attack surface. Professional-grade ...](https://github.com/bountyyfi/lonkero)** `[google cse]`
   Lonkero - Wraps around your attack surface. Professional-grade scanner for real penetration testing. Fast. Modular. Rust. - bountyyfi/lonkero.

4. **[Static Code Analysis for Security: How SAST Addresses the OWASP ...](https://www.in-com.com/blog/preventing-security-breaches-the-role-of-static-code-analysis-in-owasp-top-10-vulnerabilities/)** `[brave]`
   Static analysis finds the code-level ... hardcoded passwords, weak password validation, session tokens generated with non-cryptographic randomness, missing session invalidation on logout, and JWT implementations that accept the none algorithm...

5. **[(PDF) Using Static Analysis to Detect Vulnerabilities in OpenID ...](https://www.researchgate.net/publication/354376744_Using_Static_Analysis_to_Detect_Vulnerabilities_in_OpenID_Connect_Clients)** `[brave]`
   together with the access token. ID tokens come in the JSON Web Token (JWT) format,

6. **[Web Application Security Vulnerabilities | Top Risks](https://www.aikido.dev/blog/top-web-application-security-vulnerabilities)** `[google cse]`
   20 oct 2025 ... Aikido's AI-powered SAST (static code analysis) can help catch dangerous injection patterns in your code before deployment. For instance, ...

7. **[What is code security review? A guide to secure code review in ...](https://www.endorlabs.com/learn/what-is-code-security-review)** `[brave]`
   AI security review uses specialized agents to detect, triage, and fix vulnerabilities on every pull request, combining deterministic program analysis with LLM reasoning. Endor Labs' AI Security Review runs the company's AI SAST engine on each PR. The engine combines rule-based pattern matching, dataflow tracing, and multi-pass LLM reasoning across several specialized agents. Detection agents read a change the way a security engineer would. They trace how data moves across files and functions to catch flaws a pattern can't describe: broken access control, IDOR, injection, and insecure design.

8. **[Vector Documentation | AI Penetration Testing Scanner - zauth](https://zauth.inc/docs/vector)** `[google cse]`
   Blackbox points a real attacker agent at your live app with no code access. It discovers the attack surface, tests across categories, and proves each exploit on ...

9. **[Catching IDORs, Broken Authorization, and Other Logic Issues with ...](https://semgrep.dev/blog/2025/ai-powered-detection-with-semgrep/)** `[brave]`
   This gives our AI-powered detection a precise, code-level understanding of unsafe data paths, helping them detect real IDORs instead of just guessing from patterns. We have illustrated this process in the diagram below: While LLMs have shown the ability to detect vulnerabilities, the data has shown the most optimal code security solution for AppSec teams blends deterministic, rules based scanning with AI-powered detection.

10. **[Your JWT Validation Is Probably Broken | ScanMyCode.dev | ...](https://www.scanmycode.dev/blog/authentication-authorization-jwt-validation-bypass)** `[brave]`
   ScanMyCode.dev runs automated security audits that flag authentication and authorization issues with exact file and line references. Token handling, missing authorization checks on endpoints, IDOR patterns.

### T-200 — Consulta SearXNG

## Resultados de Búsqueda Soberana: product idea viability validation framework objective scoring demand competition alternatives research methodology

1. **[Business Idea Validation Guide (2026): The Full Method - IdeaProof](https://ideaproof.io/guides/business-idea-validation-guide)** `[google cse]`
   It's the difference between building ... nobody needs. The goal is to gather evidence—not opinions—about your idea's viability through market research, customer interviews, and small-scale experiments....

2. **[Product Research & Market Validation: A Practical Framework to ...](https://gembah.com/blog/product-research-market-validation/)** `[brave]`
   This framework provides objective criteria for prioritizing concepts during product opportunity assessment. Score multiple product ideas to identify which opportunities deserve deeper validation investment before any single concept consumes ...

3. **[How to validate your startup idea - 7 methods explained - OpenVC](https://www.openvc.app/blog/how-to-validate-your-startup-idea-6-methods-explained)** `[google cse]`
   For instance, you could take the problem statement and competitive analysis from 3: The Startup Grind and pair that with 2: Lean Market Validation to craft actionable assumptions. This combo can give you a much clearer view of your idea’s viability.

4. **[5 Steps to Validate Your Business Idea | HBS Online](https://online.hbs.edu/blog/post/market-validation)** `[google cse]`
   18 ago 2020 ... ... points of the total mattress market share. Do this exercise for your target market. For products similar to yours, research sales data, the ...

5. **[Startup Idea Validation Framework](https://blog.proofengine.studio/startup-idea-validation-framework/)** `[brave]`
   With Proof Engine: Our team applies the framework with AI-powered experiments in a 2-week sprint for $4,500. You get all 5 pillars scored with professional-grade evidence. Proof Engine Studio is an AI-native product validation studio. The 5-Pillar Framework is the methodology behind every sprint we run. 2 weeks, $4,500, real demand signals.

6. **[Desirability, Feasibility, and Viability: A Simplified Guide - Ramotion](https://www.ramotion.com/blog/desirability-feasibility-viability/)** `[brave]`
   That makes validation methods like user interviews, field research, prototype testing, search analysis, and competitive analysis especially useful. Interviews uncover language and motivation, observation exposes workarounds, and prototypes show ...

7. **[A framework for evaluating the viability of business ideas - Theseus](https://www.theseus.fi/bitstreams/09f6b8e6-b24f-4613-a489-ea8839e4893e/download)** `[google cse]`
   16 mar 2016 ... The earliest research on entrepreneurship can be traced back to Joseph Schumpeter. According to Schumpeter (1934), the entrepreneur who spreads ...

8. **[Product Idea Research Guide for Founders | IdeaCrystal](https://ideacrystal.com/en/blog/product-idea-research-guide)** `[brave]`
   Score each area based on data quality and commercial significance, not optimism. ... Demand: Are there clear signs of active, recurring, high-intent interest and an urgent customer problem?

9. **[7 Stages of New Product Development: A Guide for Leaders](https://www.planview.com/resources/articles/7-stages-of-new-product-development-a-guide-for-product-commercialization-leaders/)** `[google cse]`
   Utilize a structured/systematic approach: This method should be used when selecting product ideas and should also rely on scoring models, decision matrices, ...

10. **[The Ultimate Guide to Idea Validation in Idea Management - Qmarkets](https://qmarkets.net/resources/article/idea-validation/)** `[google cse]`
   Scorecards: Customizable scorecards allow organizations to evaluate ideas based on defined criteria like feasibility, viability, and strategic alignment. Scores are aggregated, providing a clear ranking of the most promising ideas.
