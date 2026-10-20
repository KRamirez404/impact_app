# Decisiones y alcance del cierre

Fecha: 11/10/2026. Fuente principal: `requerimientos.pdf`; alcance complementario:
`anteproyecto.txt`. Este registro distingue decisiones adoptadas de propuestas.

Actualización: 16/10/2026, por autorización del responsable del proyecto en la
solicitud de Build de la Etapa 2. Las decisiones siguientes no acreditan su
implementación ni resultados de pruebas.

## D-01 — Flujo económico (aprobado; implementación bancaria pendiente)

Se aprueba incorporar declaraciones de transferencias y comprobantes privados
como complemento de Wompi, preservando su funcionamiento y las donaciones
históricas. La primera versión bancaria utiliza COP exclusivamente.

Declarar o adjuntar un documento no incrementa el recaudo. Solo una transferencia
verificada y contabilizada mediante el procedimiento autorizado podrá hacerlo.
La contabilización real permanecerá deshabilitada mientras no exista una fuente
bancaria independiente aprobada e implementada. No se convertirán registros
históricos ni el texto `cuenta_recaudo` en verificaciones bancarias.

## D-02 — Doble control y evidencia bancaria (aprobado)

El organizador habilitado confirma recepción; otra persona con rol de soporte y
asignación financiera explícita vigente autoriza la contabilización. El mismo
usuario no puede realizar ambos pasos. Tener rol `soporte` o conservar un JWT no
sustituye la asignación ni la comprobación actual del estado del usuario.

Cada ingreso contabilizado requiere identidad bancaria verificable y única en el
ámbito real de la fuente. No se permite reutilizar un movimiento ni contabilizar
sin identificador mediante excepción manual. El comprobante del donante no es
prueba bancaria independiente.

Las discrepancias permanecen bloqueadas, sin modificar silenciosamente importes,
hasta aprobar una política de resolución. Una revisión posterior al cierre solo
es admisible si se acredita recepción bancaria anterior a un cierre verificable;
la fecha de declaración o carga no sirve para demostrarla. La precisión temporal
insuficiente también bloquea la contabilización.

Pendientes: fuente y contrato de identificadores, responsable administrativo
designado, política temporal, resolución de discrepancias y casos de revocación.
Detalle: [contrato y bloqueos de transferencias](transferencias_bancarias.md).

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
  de la campaña y soporte con asignación explícita vigente según finalidad.
- Comprobantes: exclusivamente PDF, JPEG y PNG, con validación real y descarga
  autenticada. Tamaños, páginas y dimensiones siguen pendientes de aprobación.
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

- Habilitado para el primer incremento de Etapa 2: documentación de decisiones,
  contrato, bloqueos y estrategia de pruebas aisladas. Este incremento no añade
  modelos, endpoints ni altera la inicialización.
- Las estructuras y controles posteriores podrán implementarse incrementalmente
  cuando estén definidos, manteniendo restringidas las acciones sin responsable
  designado y la contabilización sin fuente bancaria verificable.
- La activación financiera requiere resolver los bloqueos de D-02 y verificar
  permisos, evidencia, atomicidad, concurrencia y regresión de Wompi.
- Dependiente de D-03: regla definitiva de eliminación con aportes.
- El estado de Wompi debe acreditarse con sus verificaciones propias; este registro
  no declara terminada ni probada esa integración.
- Estado de Etapa 2: Fase A documental completada; Fase B incorpora asignaciones
  y autorización preparatoria desactivadas por defecto. Ver
  [esquema y API de Fase B](esquema_financiero_fase_b.md). Fuente bancaria,
  comprobantes, declaraciones y contabilización siguen pendientes.
