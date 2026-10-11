# Decisiones y alcance del cierre

Fecha: 11/10/2026. Fuente principal: `requerimientos.pdf`; alcance complementario:
`anteproyecto.txt`. Este registro distingue decisiones adoptadas de propuestas.

## D-01 — Flujo económico (pendiente de decisión)

El PDF RF-09 exige transferencia externa, comprobante y validación. El código
implementa checkout Wompi. No se ha autorizado modificar el requisito ni retirar
Wompi. La etapa 9 queda condicionada a elegir:

1. Cumplir el flujo del PDF e implementar transferencias/comprobantes.
2. Mantener Wompi, actualizar la especificación académica y definir el destino
   del recaudo para cada organizador.

Hasta resolverlo se conserva el comportamiento actual. Perfil, validaciones y
documentación pueden avanzar porque no dependen de esa decisión.

## D-02 — Validación de comprobantes (propuesta, no aprobada)

Si se elige transferencia: el organizador confirma recepción en su cuenta;
soporte supervisa y resuelve inconsistencias. Deben definirse evidencia requerida,
duplicados, rechazo, anulación y permisos antes de implementar.

## D-03 — Donaciones procesadas (propuesta, no aprobada)

Para restringir eliminación se propone considerar procesados los pagos
confirmados y las donaciones en especie recibidas. Falta acordar tratamiento de
pendientes, anulaciones y campañas restauradas. No cambia el código actual.

## D-04 — Clasificación de archivos (diseño de cierre)

- Públicos: imágenes y documentos de avances destinados explícitamente a mostrar
  uso de recursos y resultados. Disponibles en campañas publicadas.
- Privados: identidad, información bancaria de verificación y comprobantes de
  transferencia. No se incluyen en listados/detalles públicos ni en URLs de
  descarga sin autorización.
- Identidad: acceso del titular y soporte; comprobantes: donante dueño, organizador
  de la campaña y soporte según finalidad.
- La decisión de publicación de un archivo no se infiere de su extensión ni del
  campo `validado`; deberá representarse expresamente.
- Pendientes: campaña y soportes consultables por creador y soporte; público y
  otros donantes no acceden hasta aprobación.
- La implementación de permisos se realizará en etapas 4/8/9. Este diseño no
  significa que el código actual ya proteja esos datos.

## D-05 — Evidencia y evaluación

Solo se registran resultados de ejecuciones reales. La tabla SUS heredada se
conserva con procedencia no acreditada, sin usarla como evaluación final.
La aceptación exige respuestas anonimizadas, tareas, contexto, observaciones y
cálculo reproducible. Las pruebas automatizadas no sustituyen la evaluación SUS.

## Trabajo habilitado y bloqueos

- Habilitado: documentación, registro/perfil, búsqueda y diseño de evidencias.
- Dependiente de D-01/D-02: desarrollo financiero y validación de aportes.
- Dependiente de D-03: regla definitiva de eliminación con aportes.
- La etapa 1 está EN PROGRESO mientras las decisiones financieras sigan pendientes.
