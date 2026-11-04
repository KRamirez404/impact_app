# Incremento 2C: demostración Android

El cliente Android integra transferencias bancarias manuales y mejora el retorno
desde Wompi Checkout Web. Este incremento no activa pagos reales, transferencias
en el entorno habitual ni migraciones sobre bases existentes.

## Backend de demostración

El teléfono debe alcanzar el backend mediante una dirección de red real:

```text
http://<IP-LAN-DEL-EQUIPO>:5000/api
```

`localhost` en un teléfono físico apunta al teléfono, no al equipo que ejecuta
Flask. La URL se define con `--dart-define=API_BASE_URL=...` al compilar o desde
la opción **Configurar servidor** antes de iniciar sesión. El APK `debug` admite
HTTP en LAN; una distribución real debe utilizar HTTPS.

Para demostrar transferencias se necesita un backend de pruebas aislado con:

- las dos migraciones del Incremento 2B aplicadas únicamente a su base aislada;
- `TRANSFERENCIAS_ENABLED=1` y `FINANCIAL_ASSIGNMENTS_ENABLED=1`;
- claves de cifrado y hash de prueba externas al repositorio;
- `PRIVATE_STORAGE_ROOT` absoluto y privado;
- una cuenta de recaudo verificada asociada a una campaña activa.

El entorno habitual conserva `TRANSFERENCIAS_ENABLED=0`. Si el endpoint devuelve
404 o 503, la aplicación informa que no existe una cuenta verificada o que el
módulo está deshabilitado; no crea datos locales ficticios.

## Flujo de transferencia

1. El donante abre una campaña y elige **Transferencia**.
2. La aplicación consulta la cuenta verificada y muestra el número completo solo
   en esa respuesta privada.
3. El donante registra importe, referencia, fecha y un PDF, JPEG o PNG de hasta
   8 MiB.
4. La transferencia se crea con una clave idempotente y después se carga el
   comprobante. Si falla la carga, se reintenta sobre el mismo identificador.
5. **Mis transferencias bancarias** muestra historial y detalle.
6. Una transferencia rechazada permite cambiar únicamente el comprobante.

Los estados visibles son `registrada`, `en_revision`, `aprobada` y `rechazada`.
El cliente nunca envía el estado ni acredita una donación.

## Retorno de Wompi Sandbox

Checkout se abre en el navegador externo. Al regresar con Atrás o cambiar de
aplicación, el diálogo reanuda la consulta al backend. Mientras Android mantiene
la aplicación pausada, el sondeo queda detenido. Un cierre del navegador, una
cancelación o un error de conectividad conservan el pago como pendiente.

No se configuró un deep link porque el proyecto no dispone de un dominio HTTPS
autorizado para App Links. El retorno del navegador nunca aprueba el pago: solo
el webhook o la consulta autoritativa realizada por el backend pueden hacerlo.

## Compilación

Desde `impactapp_flutter/`:

```bash
flutter test
flutter analyze
flutter build apk --debug \
  --dart-define=API_BASE_URL=http://<IP-LAN-DEL-EQUIPO>:5000/api
```

La ruta esperada del artefacto es
`build/app/outputs/flutter-apk/app-debug.apk`. La firma release actual no es apta
para distribución y el estado de licencias del Android SDK debe validarse antes
de compilar.
