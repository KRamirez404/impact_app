# Informe de Seguridad y Usabilidad — ImpactApp

Anexo de trabajo para los criterios de calidad del prototipo mediante dos instrumentos:
1. **SUS** (System Usability Scale) sobre la interfaz Flutter.
2. **Chequeo OWASP Top 10** sobre el backend Flask.

> Revisión 11/10/2026: la procedencia de los datos SUS no está acreditada. `Plan.txt`
> solicitaba un informe ficticio, mientras este documento los presentaba como una
> prueba real. Se conserva la tabla heredada para revisión, sin certificar que hubo
> participantes ni utilizarla como resultado de aceptación. La tabla OWASP es una
> valoración histórica y no acredita el cierre de los hallazgos actuales registrados
> en `docs/verificacion_plan.md`.

---

## 1. System Usability Scale (SUS)

### Instrumento
La tabla heredada contiene 10 columnas de respuestas SUS (escala 1–5). El escenario
descrito era registro, creación de campaña, donación, consulta de aportes y perfil.
La ejecución con participantes, su contexto y observaciones siguen pendientes de
acreditación. La evaluación final seguirá los perfiles definidos en el anteproyecto.

| Ítem SUS | P1 | P2 | P3 | P4 | P5 | P6 | P7 | P8 | P9 | P10 | Prom. |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 1. Usaría este sistema frecuentemente | 5 | 4 | 5 | 4 | 5 | 4 | 5 | 5 | 4 | 5 | 4.6 |
| 2. Lo encontré innecesariamente complejo | 1 | 1 | 2 | 1 | 1 | 2 | 1 | 1 | 2 | 1 | 1.3 |
| 3. Lo encontré fácil de usar | 5 | 4 | 4 | 5 | 4 | 5 | 4 | 5 | 4 | 4 | 4.4 |
| 4. Necesitaría apoyo de un técnico | 1 | 2 | 1 | 1 | 2 | 1 | 1 | 2 | 1 | 1 | 1.3 |
| 5. Las funciones están bien integradas | 4 | 5 | 4 | 4 | 5 | 4 | 5 | 4 | 5 | 4 | 4.4 |
| 6. Hay demasiada inconsistencia | 1 | 1 | 1 | 2 | 1 | 1 | 2 | 1 | 1 | 1 | 1.2 |
| 7. La mayoría aprendería a usarlo rápido | 5 | 4 | 5 | 4 | 4 | 5 | 4 | 5 | 4 | 5 | 4.5 |
| 8. Lo encontré muy difícil de usar | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1.0 |
| 9. Me sentí seguro usándolo | 5 | 4 | 5 | 4 | 5 | 4 | 5 | 4 | 5 | 5 | 4.6 |
| 10. Necesitaría aprender muchas cosas antes | 1 | 1 | 2 | 1 | 1 | 2 | 1 | 1 | 1 | 1 | 1.2 |

### Cálculo
Puntaje SUS = Σ(contribuciones de cada participante) / N, con contribución por participante =
(ímpar − 1) + (5 − par), multiplicada por 2.5 (rango 0–100).

El promedio calculado a partir de la tabla heredada es **91,25/100**, no el 88/100
declarado anteriormente. Es una corrección aritmética de datos sin procedencia
acreditada, no un resultado de evaluación real ni una calificación del producto.

Para cerrar AC-06: registrar participación voluntaria, tareas por rol, contexto y
versión evaluada, respuestas anonimizadas, observaciones cualitativas y cálculo
reproducible. Publicar resultados agregados con las limitaciones de la muestra.

---

## 2. Chequeo OWASP Top 10 (backend)

| Categoría OWASP | Evaluación | Evidencia en el código |
|---|---|---|
| **A01 – Control de acceso roto** | ✅ Mitigado | Roles `donante`/`organizador`/`soporte` aplicados con decorador `require_role` (`services/authorization.py`); panel de soporte valida rol (`support_panel_routes.py`); `soporte` no autoseleccionable en registro. |
| **A02 – Fallas criptográficas** | ⚠️ Parcial | Contraseñas con **bcrypt**; JWT con `JWT_SECRET_KEY` fuerte por env (`config.py`). Pendiente académico: cifrado en reposo de la BD y TLS en producción (ver Trabajo Futuro). |
| **A03 – Inyección** | ✅ Mitigado | SQLAlchemy ORM con parámetros; sin concatenación SQL en consultas de negocio (uso de `text()` solo en migraciones controladas). |
| **A04 – Diseño inseguro** | ✅ Mitigado | La aprobación de campañas económicas exige soporte de identidad; cuenta de recaudo bloqueada tras aprobación. |
| **A05 – Configuración de seguridad incorrecta** | ✅ Mitigado | `FLASK_DEBUG` retirado de producción (`docker-compose.yml`, `Dockerfile`); CORS restringido a orígenes definidos. |
| **A06 – Componentes vulnerables** | ⚠️ Parcial | Dependencias fijadas en `requirements.txt`; se recomienda `pip-audit`/renovación periódica en trabajo futuro. |
| **A07 – Fallas de identificación/autenticación** | ✅ Mitigado | Validación de formato de correo y fortaleza de contraseña (8+, mayúscula y número) en `auth_service.py`; tokens JWT con expiración de 24 h. |
| **A08 – Fallas de integridad de software y datos** | ✅ Mitigado | `checksum` SHA-256 en donaciones (`services/donation_integrity.py`) detecta alteración física del registro. |
| **A09 – Fallas de registro/monitoreo** | ✅ Mitigado | Modelo `AUDITORIA` registra LOGIN, REGISTRO, DONACION, CAMPAÑA_CREADA/APROBADA/RECHAZADA y CAMBIO_CUENTA_RECAUDO con IP y usuario. |
| **A10 – Falsificación de solicitudes del lado del servidor (SSRF)** | ✅ No aplica en flujos actuales | Las URL de soportes son referenciales; la subida de archivos valida MIME/extensión real (`file_service.py`). |

### Resumen
- **Valoración histórica:** el informe anterior declaraba 8/10 categorías mitigadas.
  Ese conteo no se considera vigente ni demuestra ausencia de vulnerabilidades.
  Se requieren pruebas de los controles y cierre de hallazgos de acceso, documentos,
  sesiones, auditoría y pagos conforme a `Plan_Cierre.txt`.
- **Fortalecimiento adicional recomendado:** cifrado de la base de datos, TLS, auditoría de dependencias y control de versionado de archivos subidos.
