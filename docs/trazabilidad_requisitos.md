# Matriz de Trazabilidad de Requisitos — ImpactApp

Relaciona los requisitos funcionales (RF) y no funcionales (RNF) del proyecto con los casos de prueba automatizados (`impactapp_backend/tests/`) y el estado final del resultado.

## Códigos de caso de prueba (CP)

| CP | Archivo | Descripción |
|---|---|---|
| CP-01 | `tests/test_auth.py` | Registro, validación de formato, contraseña y roles |
| CP-02 | `tests/test_roles.py` | Control de acceso por rol (campañas/donaciones) |
| CP-03 | `tests/test_f2_f3.py` | Verificación de identidad, cuenta de recaudo, privacidad (Ley 1581) y auditoría |

## Matriz

| Req. | Descripción | Criterio de aceptación | CP | Resultado |
|---|---|---|---|---|
| RF-01 | Autenticación y registro de usuarios | Registro válido crea cuenta; login con credenciales incorrectas es rechazado | CP-01 | ✅ PASÓ |
| RF-02 | Distinción de roles Donante / Organizador / Soporte | Registro asigna solo `donante` u `organizador`; `soporte` no es autoseleccionable | CP-01 | ✅ PASÓ |
| RF-03 | Creación y verificación de campañas económicas | Campaña económica requiere soporte de identidad (documento oficial) para aprobarse | CP-03 | ✅ PASÓ |
| RF-04 | Registro y control de donaciones | Solo un usuario `donante` puede registrar donaciones; `organizador` no | CP-02 | ✅ PASÓ |
| RF-05 | Protección de la cuenta de recaudo | No se permite cambiar la cuenta de recaudo tras la aprobación (`estado=activa`) | CP-03 | ✅ PASÓ |
| RF-06 | Trazabilidad de aportes del donante | `/api/donations/mine` expone campaña y soportes asociados a cada donación | — | ✅ (manual + API) |
| RF-07 | Seguimiento y evidencias de campañas | `/api/tracking/campaign/:id` lista avances publicados por el creador | — | ✅ (manual + API) |
| RNF-01 | Plataforma Android | Generación de APK debug funcional | — | ✅ (ver Fase 6) |
| RNF-05 | Auditoría e integridad de registros | Eventos LOGIN, REGISTRO, DONACION, CAMPAÑA_CREADA/APROBADA se registran con IP | CP-03 | ✅ PASÓ |
| RNF-06 | Protección de datos personales (Ley 1581) | Registro exige aceptación; política disponible; `DELETE /api/auth/me` suprime datos | CP-01/03 | ✅ PASÓ |
| RNF-07 | Integridad de registros de donación | Checksum SHA-256 calculado y validado en consultas | CP-03 | ✅ PASÓ |
| RQ-01..05 | Métricas de calidad (pruebas) | Suite `pytest` ejecuta sin fallos | CP-01..03 | ✅ 20/20 PASÓ |

## Ejecución de la suite

```bash
make test        # o: docker compose exec backend python -m pytest tests -q
```

Resultado registrado: **21 passed** sobre la rama `master` (sept. 2026).
