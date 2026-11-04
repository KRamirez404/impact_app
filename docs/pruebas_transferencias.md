# Etapa 2 — Estrategia de pruebas aisladas

Fecha: 16/10/2026. Estado: plan y verificación parcial de Fase B; resultados al final.
Este documento no prepara ni autoriza por sí mismo un entorno de base de datos.

## 1. Efectos secundarios comprobados

- `impactapp_backend/tests/conftest.py` lee `TEST_DATABASE_URL` antes de importar
  `app`. Si no existe, elimina `/tmp/impactapp_pytest.db` si está presente y utiliza
  ese nombre fijo. No es aislamiento suficiente para ejecuciones paralelas.
- Acepta SQLite en memoria o bajo el directorio temporal, y PostgreSQL cuyo nombre
  termine en `_test`. El sufijo no demuestra que servidor y credenciales sean seguros.
- Importar `impactapp_backend/app.py` ejecuta `create_app()`, creación de carpetas,
  `create_all()`, ajustes de esquema y seed, incluso antes de pedir un fixture.
- El fixture `client` ejecuta `drop_all()`, creación, ajustes y seed por prueba.
- Configurar `TESTING=True` dentro de ese fixture llega después de la importación.
- La creación de carpetas incluye uploads y `data` bajo la raíz de la aplicación;
  una BD temporal por sí sola no aísla esas escrituras.
- La recopilación de pytest tampoco es una operación de solo lectura segura.

## 2. Preparación exigida antes de ejecutar

1. Revisar de nuevo conftest, configuración de pytest, fixtures seleccionados y
   posibles plugins. Inventariar comandos del proyecto sin ejecutarlos automáticamente.
2. Elegir una copia o contenedor desechable del código, sin montaje de escritura
   del workspace del usuario y sin sus archivos privados o variables secretas.
3. Establecer `TEST_DATABASE_URL` antes de cualquier importación o recopilación.
   Para SQLite, ruta absoluta única por ejecución en directorio temporal exclusivo;
   no utilizar el fallback fijo. Usar ruta desechable de almacenamiento y raíz de
   aplicación desechable para absorber `uploads` y `data`.
4. Para PostgreSQL, servicio exclusivo de pruebas, base terminada en `_test` y rol
   sin acceso a bases reales. Confirmar host, nombre, propietario y ausencia de datos
   del usuario antes de permitir fixtures destructivos. No reutilizar el servicio
   de desarrollo porque el nombre de la base parezca de pruebas.
5. No ejecutar workers contra la misma base: los fixtures eliminan tablas. Asignar
   bases independientes o ejecutar secuencialmente; los tests de concurrencia usan
   sesiones independientes dentro de su propio escenario controlado.
6. Instalar dependencias solo en el entorno desechable autorizado. Revisar si el
   runner de contenedores requiere descargas; no iniciar infraestructura existente.
7. Usar JWT y credenciales ficticias. Simular Wompi, fuente bancaria y correo;
   bloquear tráfico externo a nivel del entorno además de mocks. Sin llaves reales.
8. Verificar que ninguna variable heredada apunta a almacenamiento o datos reales.
   No imprimir URLs con contraseñas ni secretos durante esa comprobación.
9. Ejecutar únicamente después de acreditar lo anterior. Registrar comando, motor,
   aislamiento, versión y resultados. La limpieza solo afecta recursos creados para
   esa ejecución, no directorios temporales compartidos ni volúmenes existentes.

La preparación y ejecución quedan pendientes; no se proporcionan comandos que
puedan confundirse con una autorización para reinicializar la base actual.

## 3. Matriz prevista

| Nivel | Escenarios y resultado esperado |
|---|---|
| Unitarias | COP y decimal exacto; importes inválidos; transiciones permitidas; identidad de actores; precisión temporal insuficiente; normalización bancaria solo cuando exista contrato real. |
| Permisos e integración | Anónimo, bloqueado con JWT previo, otro donante/organizador, soporte sin asignación, revocación y expiración; acceso denegado sin alterar negocio. |
| Asignaciones | Solo responsable designado concede/revoca; historial con actor/fecha/motivo; sin responsable configurado todas esas acciones restringidas. |
| Doble control | Confirmación no contabiliza; mismo usuario denegado incluso tras cambio de rol; persona distinta sin asignación denegada; revocación efectiva en cada petición. |
| Declaración | Donante desde JWT; campaña/destino consistentes; reintento equivalente reutiliza resultado; misma clave con otro payload devuelve conflicto. Sin donación aprobada ni cambio de avance. |
| Archivos | PDF/JPEG/PNG estructuralmente válidos; MIME/extension falsos, corrupción, contenido activo y recursos excesivos rechazados; límites aprobados, configurados y probados en sus fronteras. |
| Privacidad | Descarga propia y de revisores habilitados; ajenos y otras campañas no revelan existencia; rutas públicas y serializadores no exponen comprobantes ni datos bancarios nuevos. |
| Almacenamiento | Traversal, enlaces simbólicos, colisión de nombre, carga interrumpida, caída antes/después de mover o confirmar SQL; ningún archivo incompleto descargable; reconciliación idempotente. |
| Bloqueos funcionales | Fuente ausente, ID ausente/no fiable, discrepancia, cierre inexistente o fecha ambigua: ninguna contabilización. Un archivo nunca equivale a verificación bancaria. |
| Banco y duplicados, fase E | ID repetido entre fuentes/versiones, mismo movimiento para dos declaraciones/campañas, reimportación y liquidación Wompi no cuentan dos ingresos. Requiere fuente aprobada. |
| Cierre, fase E | Recepción acreditada anterior permite revisar, no aprueba automáticamente; posterior o indeterminable queda bloqueada. Probar zona y fronteras con política aprobada. |
| Atomicidad, fase E | Inyectar fallo en movimiento, donación, checksum, vínculo, evento, recálculo, auditoría y commit: rollback completo y reintento sin doble contabilización. |
| PostgreSQL concurrente, fase E | Dos autorizaciones, dos campañas/mismo movimiento, revocación y cierre concurrentes, Wompi y transferencia/misma campaña: exclusividad y avance correcto; reintentos acotados sin ciclos de bloqueo. |
| SQLite | FK habilitadas y verificadas, unicidad y rollback; no atribuir equivalencia de bloqueos de fila. Si no se acredita coordinación segura, contabilización deshabilitada. |
| Frontend y correo | Estados reales, descargas autenticadas y mensajes de indisponibilidad; nunca mostrar pagada por cargar documento. Correo simulado, si existe servicio. |

## 4. Regresión existente a conservar

- `test_wompi.py`, `test_wompi_extra.py` y `test_wompi_integrity.py`: firmas,
  ambiente, consulta autoritativa simulada, importes, estados terminales, idempotencia,
  índices, rollback y concurrencia PostgreSQL. Revisar mocks antes de ejecutar;
  bloqueo de red es obligatorio para evitar llamadas accidentales.
- `test_roles.py`: permisos y donaciones en especie; donación económica directa
  sigue sin eludir el checkout o la futura ruta bancaria controlada.
- `test_uploads.py`: las validaciones nuevas no alteran el contrato general de
  cargas; documentos financieros no utilizan ese almacenamiento público.
- `test_profile.py`, `test_auth.py` y `test_f2_f3.py`: revisar interacciones con
  bloqueo, anonimización, campañas y serialización cuando cambien esas superficies.

No modificar pruebas para aceptar una regresión de privacidad ni declarar que
pasaron pruebas PostgreSQL omitidas en SQLite.

## 5. Registro de esta fase

Fase A: lectura de configuración, fixtures y referencias de código; documentación.
No se importó la aplicación, no se prepararon bases/contenedores, no se ejecutó
pytest ni se contactaron pasarelas/bancos/correo. La revisión de diferencias y
formato documental no constituye prueba funcional ni de seguridad del módulo.

## 6. Verificación de Fase B

Las pruebas nuevas no importan `app.py` ni los fixtures heredados. Usan Flask
directamente, SQLite en memoria, FK activadas y red bloqueada. Cubren designación
inválida/ausente, roles, bloqueo con JWT anterior, revocación, expiración, alcance,
doble control, validaciones, idempotencia, reactivación conservando historia,
restricciones SQL, rollback y ausencia de efectos sobre donaciones/recaudo.

Desde `impactapp_backend/`, con dependencias existentes en `.venv`:

```bash
PYTEST_DISABLE_PLUGIN_AUTOLOAD=1 PYTHONPATH=. .venv/bin/python -B -m pytest --noconftest -p no:cacheprovider pruebas_aisladas/test_asignaciones_financieras.py -q
.venv/bin/python -B scripts/verificar_regresion_aislada.py
```

El segundo comando copia solo código y pruebas heredadas a un directorio temporal,
sin .env, uploads, instancia o base existentes. Reemplaza el entorno del subproceso,
usa SQLite exclusivo, flag financiero apagado y bloquea conexiones de red antes
de recopilar. La importación, `drop_all()` y seed ocurren solo dentro de esa copia.
La limpieza afecta exclusivamente el directorio creado por el runner. No instala
dependencias, no levanta contenedores y no usa servicios del proyecto.

Resultados de regresión con el runner versionado: 216 aprobadas, 3 omitidas por
requerir PostgreSQL, en 200,42 segundos. Una ejecución previa con runner temporal
agotó 120 segundos; la repetición con 300 segundos había completado en 178,63
segundos. Se observaron advertencias heredadas de `datetime.utcnow()` y `Query.get()`
en Python 3.14/SQLAlchemy; no se alteraron esos módulos.

La suite financiera incluye comprobación en proceso independiente de registro
condicional sin importar `app` ni inicializar BD, y cabeceras sin caché compartida.
Resultado final: 38 pruebas aprobadas en 4,31 segundos con SQLite en memoria;
219 advertencias de los defaults temporales heredados de modelos existentes.
PostgreSQL, carreras de asignación y cualquier contabilización bancaria siguen
pendientes. No confundir el helper de doble control con una integración o movimiento
financiero real.
