# Wompi Sandbox: configuración y operación

Implementación exclusiva de pruebas. Producción está bloqueada por defecto con
`WOMPI_ALLOW_PRODUCTION=0`. No se usan credenciales reales en pruebas
automatizadas.

## Variables de entorno

Nombres esperados en `.env` o en el entorno del contenedor:

```text
WOMPI_ENV=sandbox
WOMPI_ALLOW_PRODUCTION=0
WOMPI_PUBLIC_KEY=pub_test_...
WOMPI_PRIVATE_KEY=prv_test_...
WOMPI_INTEGRITY_SECRET=test_integrity_...
WOMPI_EVENTS_SECRET=test_events_...
WOMPI_CHECKOUT_URL=https://checkout.wompi.co/p/
WOMPI_API_URL=https://sandbox.wompi.co/v1
WOMPI_MIN_AMOUNT=1000
DONATION_REDIRECT_URL=https://transaction-redirect.wompi.co/check
```

No se deben imprimir valores. `.env` está ignorado por Git.

El backend valida:

- presencia de las cuatro credenciales;
- prefijos `pub_test_`, `prv_test_`, `test_integrity_` y `test_events_` en Sandbox;
- URL de API `https://sandbox.wompi.co/v1`;
- checkout oficial `https://checkout.wompi.co/p/`;
- moneda `COP`;
- ausencia de producción salvo autorización explícita.

Diagnóstico sin secretos:

```bash
make wompi-check
# alternativa local:
cd impactapp_backend && .venv/bin/python scripts/check_wompi_config.py
```

Si falta configuración, el checkout y el webhook responden 503 sin modificar
donaciones.

## Flujo implementado

1. Flutter valida el importe COP con precisión de centavos y envía
   `Idempotency-Key` estable por intento.
2. `POST /api/donations/checkout` crea una donación `pendiente` y devuelve una
   URL firmada de Checkout Web.
3. El usuario paga en Sandbox. La redirección no confirma el pago.
4. Wompi envía `POST /api/webhooks/wompi` con `X-Event-Checksum` y/o
   `signature.checksum`.
5. El backend valida la firma, el ambiente y consulta
   `GET /v1/transactions/{id}` con la llave privada.
6. Solo si coinciden id, referencia, monto y moneda se aplica el estado.
7. El evento válido se registra en `PAGO_EVENTO` con huella única y resultado.
8. La app consulta `GET /api/donations/:id/status`; el diálogo mantiene el
   estado `pendiente` hasta que el backend confirme.
9. Si el webhook no llega (por ejemplo, backend en LAN), esa consulta busca la
   transacción por referencia en Wompi y aplica el estado solo si coinciden
   referencia, monto y moneda.

`PAGO_EVENTO` no guarda payload completo, correos, secretos ni checksum
completo. La tabla se crea con `db.create_all()`; no se eliminan ni recrean
tablas existentes.

## Webhook HTTPS en desarrollo

Wompi requiere una URL pública para eventos. Opciones:

```bash
# cloudflared (instalar fuera del repositorio)
cloudflared tunnel --url http://localhost:5000
```

Configurar en el Dashboard de Wompi, ambiente Sandbox, la URL:

```text
https://<URL-DEL-TUNEL>/api/webhooks/wompi
```

Cerrar el túnel al terminar. No guardar tokens del túnel en el repositorio ni
exponer otros endpoints. Si no hay URL pública, el webhook real no llegará: en
ese caso la consulta de estado (`GET /api/donations/:id/status`) concilia por
referencia contra Wompi, de forma que la app refleja el pago al terminar el
checkout. Las pruebas automatizadas usan un proveedor simulado y no acreditan
una transacción Sandbox real.

## Datos de prueba oficiales

Fuente: https://docs.wompi.co/docs/colombia/datos-de-prueba-en-sandbox/

- Tarjeta `4242 4242 4242 4242`: aprobada. Fecha futura y CVC de 3 dígitos.
- Tarjeta `4111 1111 1111 1111`: declinada.
- Nequi `3991111111`: aprobada; `3992222222`: declinada.
- PSE: banco de prueba que aprueba o rechaza, según disponibilidad del comercio
  en Sandbox.

No se afirma que todos los métodos estén habilitados para el comercio. La
disponibilidad se comprueba en el checkout Sandbox.

## Pruebas

- Las pruebas backend usan SQLite temporal aislado y un proveedor Wompi
  simulado explícito.
- Las pruebas cubren firma inválida, ambiente, importes, referencias, estados,
  duplicados, concurrencia cuando PostgreSQL está disponible, atomicidad y
  ausencia de secretos en respuestas.
- Una transacción Sandbox real solo se considera probada después de completar
  checkout, webhook/consulta autoritativa y verificación de estado y recaudación.

## Limitaciones

- Sin túnel HTTPS no hay webhook real; la aprobación depende de la conciliación
  por referencia al consultar el estado de la donación.
- La dispersión a organizadores no está implementada.
- Transferencias bancarias directas no se validan con Wompi.
- Producción no está habilitada.
