---
name: security-audit
description: Escáner estático determinista para satélites — autorización de rutas, firma JWT e IDOR — con digest de severidad archivo:línea, sin red ni ejecución de exploits.
---

# Skill: Security Audit (Auditoría Defensiva Estática de Satélites)

Escanea código de aplicaciones satélite (web, APIs) con patrones estáticos deterministas para detectar fallos de autorización: rutas sin validación de propiedad, JWT sin verificación de firma e IDOR en parámetros de identidad. Coste $0, sin dependencias, sin red.

---

## 1. Cuándo Activar este Skill

- Auditoría defensiva de un satélite (web/app/API) antes de publicar o tras tocar autenticación/autorización.
- Revisión de seguridad solicitada explícitamente por el operador.
- NO para: escaneo de vulnerabilidades dinámico, pentesting activo o explotación (fuera de alcance).

## 2. Invocación y Método

No hay binario propio: la skill dirige un escaneo estático con las utilidades del sistema (grep/ripgrep), siempre desde la raíz del satélite:

```bash
# Familia A — rutas sin autorización (ver ejemplo de patrón en §3)
grep -rnE "<patrón>" <src/|routes/|api/> --include='*.{js,ts,py,go,rb,php}'

# Familia B — JWT débil
grep -rnE "alg[\"' :=]+none|verify\s*\(\s*None|jwt\.decode\([^)]*\)(,\s*['\"]{0}|,\s*algorithms\s*=\s*\[\s*\])" <src/>

# Familia C — IDOR: identidad en entrada sin comprobación de propiedad
grep -rnE "(req(uest)?\.(params|query|body)\.(user_?id|owner_?id|account_?id))" <src/>
# → exigir traza de comprobación ownership/authorize en la misma función o middleware
```

Salida obligatoria por hallazgo: `severidad | familia | archivo:línea | evidencia`.

## 3. Familias de Patrones y Severidades

| Familia | Patrón detectado | Severidad |
|---|---|---|
| A. Autorización de rutas | Endpoint que acepta identidad (path/body/query) sin pasar por middleware o función de autorización/propiedad | HIGH |
| B. Firma JWT | `alg: none`, verificación desactivada (`verify=False`), ausencia de lista blanca de algoritmos | HIGH |
| C. IDOR | Parámetro de identidad ajena sin comprobación de titular en la misma cadena de ejecución | HIGH (evidencia directa) / MED (traza incompleta) |

Reglas de evidencia: sin traza de código que muestre la comprobación, el hallazgo es `MED` (posible positivo); con traza ausente confirmada, `HIGH`. LOW reservado a higiene (headers de seguridad ausentes).

## 4. Salida (Digest)

```markdown
## Security Audit — <satélite> (<fecha>)
| Sev | Familia | Ubicación | Evidencia |
|---|---|---|---|
| HIGH | B | src/auth/jwt.ts:42 | decode sin verificación de firma |

Resumen: HIGH=n MED=n LOW=n | Método: estático grep/ripgrep | Red: no ejecutada
```

## 5. Límites (declarar siempre)

- Solo estático: no detecta flujos dinámicos, race conditions ni lógica de negocio fuera de patrones.
- No sustituye auditoría dinámica ni pentesting.
- Sin ejecución de exploits y sin llamadas de red durante el escaneo.
- Dependencias: `grep`/`rg` del sistema. Sin paquetes npm/pip nuevos.

## 6. Contrato de Dependencias (frontmatter `tools`)

```yaml
tools:
  - grep
  - rg
```
