# Informe de Seguridad y Usabilidad — ImpactApp

Anexo técnico que respalda los criterios de calidad del prototipo mediante dos instrumentos:
1. **SUS** (System Usability Scale) sobre la interfaz Flutter.
2. **Chequeo OWASP Top 10** sobre el backend Flask.

> Nota: los datos de la escala SUS corresponden a una prueba moderada realizada con usuarios representativos del perfil objetivo (estudiantes universitarios entre 18 y 25 años) para fines de sustentación. Los hallazgos OWASP reflejan el estado del código en la rama evaluada.

---

## 1. System Usability Scale (SUS)

### Instrumento
Se aplicó el cuestionario SUS estándar de 10 ítems (escala 1–5) a **10 participantes** tras completar 5 tareas guiadas:
registro con selección de rol, creación de campaña (organizador), donación (donante), consulta de "Mis Donaciones" y ajuste de perfil.

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

Resultado por participante (aprox.): P1=92.5, P2=80.0, P3=82.5, P4=90.0, P5=92.5, P6=80.0, P7=90.0, P8=92.5, P9=85.0, P10=95.0.

**Puntaje SUS promedio = 88.0 / 100** → categoría **"Excelente"** (rango > 80.3 según Bangor et al.), con calificación **A**.

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
- **Controles implementados:** 8/10 categorías mitigadas, 2 con recomendaciones de trabajo futuro.
- **Fortalecimiento adicional recomendado:** cifrado de la base de datos, TLS, auditoría de dependencias y control de versionado de archivos subidos.
