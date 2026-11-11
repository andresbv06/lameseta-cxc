# Diccionario de datos — Distribuidora La Meseta

Generado desde `tools/modelo.py`. Para obtenerlo directo de Oracle, ejecute `sql/10_diccionario_datos.sql`.

## ZONA

Zonas de reparto y cobro de la empresa.

| Columna | Tipo | Nulo | Defecto | Llave | Reglas | Descripción |
|---|---|---|---|---|---|---|
| id_zona | NUMBER(10) | No |  | PK |  | Identificador de la zona. |
| nombre_zona | VARCHAR2(60) | No |  | UQ |  | Nombre de la zona. |
| provincia | VARCHAR2(40) | No |  |  |  | Provincia a la que pertenece. |

## EMPLEADO

Vendedores, cobradores y administradores con su usuario del sistema.

| Columna | Tipo | Nulo | Defecto | Llave | Reglas | Descripción |
|---|---|---|---|---|---|---|
| id_empleado | NUMBER(10) | No |  | PK |  | Identificador del empleado. |
| id_zona | NUMBER(10) | Sí |  | FK -> ZONA.id_zona |  | Zona asignada (puede ser nula para administradores). |
| nombre | VARCHAR2(60) | No |  |  |  | Nombre. |
| apellido | VARCHAR2(60) | No |  |  |  | Apellidos. |
| correo | VARCHAR2(100) | No |  | UQ | correo IS NULL OR correo LIKE '%_@_%._%' | Correo electronico. |
| rol | VARCHAR2(10) | No |  |  | Valores: ADMIN, VENDEDOR, COBRADOR | Rol en el sistema. |
| usuario | VARCHAR2(30) | No |  | UQ |  | Nombre de usuario para iniciar sesion. |
| clave_hash | VARCHAR2(64) | No |  |  |  | Clave guardada como hash SHA-256 con sal. |
| activo | NUMBER(1) | No | 1 |  | Valores: 0, 1 | 1 = activo, 0 = inactivo. |

## CLIENTE

Negocios que compran a credito, con su limite y dias de credito.

| Columna | Tipo | Nulo | Defecto | Llave | Reglas | Descripción |
|---|---|---|---|---|---|---|
| id_cliente | NUMBER(10) | No |  | PK |  | Identificador del cliente. |
| id_zona | NUMBER(10) | No |  | FK -> ZONA.id_zona |  | Zona donde esta el cliente. |
| id_vendedor | NUMBER(10) | No |  | FK -> EMPLEADO.id_empleado |  | Vendedor que atiende al cliente. |
| cedula | VARCHAR2(20) | No |  | UQ |  | Cedula fisica o juridica. |
| nombre_comercial | VARCHAR2(100) | No |  |  |  | Nombre del negocio. |
| correo | VARCHAR2(100) | Sí |  |  | correo IS NULL OR correo LIKE '%_@_%._%' | Correo de contacto. |
| telefono | VARCHAR2(20) | Sí |  |  |  | Telefono de contacto. |
| direccion | VARCHAR2(200) | Sí |  |  |  | Direccion del negocio. |
| limite_credito | NUMBER(12,2) | No | 0 |  | limite_credito >= 0 | Monto maximo que puede deber. |
| dias_credito | NUMBER(3) | No | 15 |  | dias_credito BETWEEN 0 AND 90 | Dias de plazo para pagar. |
| estado | VARCHAR2(10) | No | 'ACTIVO' |  | Valores: ACTIVO, INACTIVO, SUSPENDIDO | Estado del cliente. |

## CATEGORIA

Categorias para agrupar los productos.

| Columna | Tipo | Nulo | Defecto | Llave | Reglas | Descripción |
|---|---|---|---|---|---|---|
| id_categoria | NUMBER(10) | No |  | PK |  | Identificador de la categoria. |
| nombre_categoria | VARCHAR2(60) | No |  | UQ |  | Nombre de la categoria. |

## PRODUCTO

Catalogo de productos con precio y existencias.

| Columna | Tipo | Nulo | Defecto | Llave | Reglas | Descripción |
|---|---|---|---|---|---|---|
| id_producto | NUMBER(10) | No |  | PK |  | Identificador del producto. |
| id_categoria | NUMBER(10) | No |  | FK -> CATEGORIA.id_categoria |  | Categoria del producto. |
| codigo | VARCHAR2(20) | No |  | UQ |  | Codigo interno. |
| nombre_producto | VARCHAR2(100) | No |  |  |  | Nombre del producto. |
| precio_unitario | NUMBER(12,2) | No |  |  | precio_unitario > 0 | Precio de venta actual. |
| stock_actual | NUMBER(10) | No | 0 |  | stock_actual >= 0 | Unidades disponibles. |
| activo | NUMBER(1) | No | 1 |  | Valores: 0, 1 | 1 = a la venta, 0 = descontinuado. |

## METODO_PAGO

Formas en que un cliente puede pagar.

| Columna | Tipo | Nulo | Defecto | Llave | Reglas | Descripción |
|---|---|---|---|---|---|---|
| id_metodo_pago | NUMBER(10) | No |  | PK |  | Identificador del metodo de pago. |
| nombre_metodo | VARCHAR2(40) | No |  | UQ |  | Efectivo, transferencia, cheque, SINPE Movil. |

## FACTURA

Venta a credito con monto, vencimiento y saldo pendiente.

| Columna | Tipo | Nulo | Defecto | Llave | Reglas | Descripción |
|---|---|---|---|---|---|---|
| id_factura | NUMBER(10) | No |  | PK |  | Identificador de la factura. |
| id_cliente | NUMBER(10) | No |  | FK -> CLIENTE.id_cliente |  | Cliente al que se factura. |
| id_empleado | NUMBER(10) | No |  | FK -> EMPLEADO.id_empleado |  | Vendedor que hizo la venta. |
| numero_factura | VARCHAR2(20) | No |  | UQ |  | Numero visible de la factura. |
| fecha_emision | DATE | No | SYSDATE |  |  | Fecha en que se emitio. |
| fecha_vencimiento | DATE | No |  |  |  | Fecha limite de pago. |
| monto_total | NUMBER(12,2) | No | 0 |  | monto_total >= 0 | Total de la factura (suma del detalle). |
| saldo_pendiente | NUMBER(12,2) | No | 0 |  | saldo_pendiente >= 0 | Lo que falta por pagar (total - notas - pagos). |
| estado | VARCHAR2(10) | No | 'PENDIENTE' |  | Valores: PENDIENTE, PAGADA, ANULADA | Estado de la factura. |

## DETALLE_FACTURA

Productos vendidos en cada factura (tabla intermedia FACTURA-PRODUCTO).

| Columna | Tipo | Nulo | Defecto | Llave | Reglas | Descripción |
|---|---|---|---|---|---|---|
| id_factura | NUMBER(10) | No |  | PK, FK -> FACTURA.id_factura |  | Factura a la que pertenece. |
| id_producto | NUMBER(10) | No |  | PK, FK -> PRODUCTO.id_producto |  | Producto vendido. |
| cantidad | NUMBER(10) | No |  |  | cantidad > 0 | Unidades vendidas. |
| precio_unitario | NUMBER(12,2) | No |  |  | precio_unitario > 0 | Precio al momento de la venta. |

## NOTA_CREDITO

Descuentos o devoluciones que reducen el saldo de una factura.

| Columna | Tipo | Nulo | Defecto | Llave | Reglas | Descripción |
|---|---|---|---|---|---|---|
| id_nota | NUMBER(10) | No |  | PK |  | Identificador de la nota. |
| id_factura | NUMBER(10) | No |  | FK -> FACTURA.id_factura |  | Factura afectada. |
| fecha_nota | DATE | No | SYSDATE |  |  | Fecha de la nota. |
| monto | NUMBER(12,2) | No |  |  | monto > 0 | Monto que se descuenta. |
| motivo | VARCHAR2(200) | No |  |  |  | Razon de la nota de credito. |

## PAGO

Dinero recibido de un cliente.

| Columna | Tipo | Nulo | Defecto | Llave | Reglas | Descripción |
|---|---|---|---|---|---|---|
| id_pago | NUMBER(10) | No |  | PK |  | Identificador del pago. |
| id_cliente | NUMBER(10) | No |  | FK -> CLIENTE.id_cliente |  | Cliente que pago. |
| id_metodo_pago | NUMBER(10) | No |  | FK -> METODO_PAGO.id_metodo_pago |  | Forma de pago usada. |
| fecha_pago | DATE | No | SYSDATE |  |  | Fecha en que se recibio el pago. |
| monto | NUMBER(12,2) | No |  |  | monto > 0 | Monto recibido. |
| referencia | VARCHAR2(50) | Sí |  |  |  | Numero de transferencia, cheque o comprobante. |
| monto_sin_aplicar | NUMBER(12,2) | No | 0 |  | monto_sin_aplicar >= 0 | Parte del pago que aun no se reparte entre facturas. |

## APLICACION_PAGO

Reparto de un pago entre una o mas facturas (tabla intermedia PAGO-FACTURA).

| Columna | Tipo | Nulo | Defecto | Llave | Reglas | Descripción |
|---|---|---|---|---|---|---|
| id_aplicacion | NUMBER(10) | No |  | PK |  | Identificador de la aplicacion. |
| id_pago | NUMBER(10) | No |  | FK -> PAGO.id_pago |  | Pago que se reparte. |
| id_factura | NUMBER(10) | No |  | FK -> FACTURA.id_factura |  | Factura que recibe el monto. |
| monto_aplicado | NUMBER(12,2) | No |  |  | monto_aplicado > 0 | Monto aplicado a la factura. |
| fecha_aplicacion | DATE | No | SYSDATE |  |  | Fecha en que se aplico. |

## GESTION_COBRO

Historial de llamadas, visitas y promesas de pago a los clientes.

| Columna | Tipo | Nulo | Defecto | Llave | Reglas | Descripción |
|---|---|---|---|---|---|---|
| id_gestion | NUMBER(10) | No |  | PK |  | Identificador de la gestion. |
| id_cliente | NUMBER(10) | No |  | FK -> CLIENTE.id_cliente |  | Cliente contactado. |
| id_factura | NUMBER(10) | Sí |  | FK -> FACTURA.id_factura |  | Factura de la que se habla (opcional). |
| id_empleado | NUMBER(10) | No |  | FK -> EMPLEADO.id_empleado |  | Cobrador que hizo la gestion. |
| fecha_hora | DATE | No | SYSDATE |  |  | Fecha y hora del contacto. |
| tipo_gestion | VARCHAR2(15) | No |  |  | Valores: LLAMADA, CORREO, VISITA, WHATSAPP | Medio usado. |
| resultado | VARCHAR2(20) | No |  |  | Valores: PROMESA_PAGO, SIN_RESPUESTA, PAGO_REALIZADO, DISPUTA, OTRO | Resultado del contacto. |
| fecha_promesa | DATE | Sí |  |  |  | Fecha prometida de pago. |
| observacion | VARCHAR2(300) | Sí |  |  |  | Notas de la gestion. |

## BITACORA

Registro de cambios hecho por los disparadores (sin llaves foraneas a proposito).

| Columna | Tipo | Nulo | Defecto | Llave | Reglas | Descripción |
|---|---|---|---|---|---|---|
| id_bitacora | NUMBER(10) | No |  | PK |  | Identificador del registro. |
| tabla_afectada | VARCHAR2(30) | No |  |  |  | Tabla que cambio. |
| operacion | VARCHAR2(10) | No |  |  | Valores: INSERT, UPDATE, DELETE | Tipo de cambio. |
| usuario_bd | VARCHAR2(30) | No |  |  |  | Usuario de la base de datos que hizo el cambio. |
| fecha_hora | DATE | No | SYSDATE |  |  | Momento del cambio. |
| detalle | VARCHAR2(400) | Sí |  |  |  | Resumen del cambio. |
