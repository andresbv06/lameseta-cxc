-- Script 01: tablas, secuencias, indices y comentarios.
-- Ejecutar conectado como el usuario LAMESETA.
SET DEFINE OFF

CREATE SEQUENCE seq_zona START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_empleado START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_cliente START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_categoria START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_producto START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_metodo_pago START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_factura START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_nota_credito START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_pago START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_aplicacion_pago START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_gestion_cobro START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_bitacora START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_numero_factura START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;

CREATE TABLE zona (
    id_zona NUMBER(10) NOT NULL,
    nombre_zona VARCHAR2(60) NOT NULL,
    provincia VARCHAR2(40) NOT NULL,
    CONSTRAINT pk_zona PRIMARY KEY (id_zona),
    CONSTRAINT uq_zona_nombre UNIQUE (nombre_zona)
);

CREATE TABLE empleado (
    id_empleado NUMBER(10) NOT NULL,
    id_zona NUMBER(10),
    nombre VARCHAR2(60) NOT NULL,
    apellido VARCHAR2(60) NOT NULL,
    correo VARCHAR2(100) NOT NULL,
    rol VARCHAR2(10) NOT NULL,
    usuario VARCHAR2(30) NOT NULL,
    clave_hash VARCHAR2(64) NOT NULL,
    activo NUMBER(1) DEFAULT 1 NOT NULL,
    CONSTRAINT pk_empleado PRIMARY KEY (id_empleado),
    CONSTRAINT uq_empleado_usuario UNIQUE (usuario),
    CONSTRAINT uq_empleado_correo UNIQUE (correo),
    CONSTRAINT fk_empleado_zona FOREIGN KEY (id_zona) REFERENCES zona (id_zona),
    CONSTRAINT ck_empleado_correo CHECK (correo IS NULL OR correo LIKE '%_@_%._%'),
    CONSTRAINT ck_empleado_rol CHECK (rol IN ('ADMIN', 'VENDEDOR', 'COBRADOR')),
    CONSTRAINT ck_empleado_activo CHECK (activo IN (0, 1))
);

CREATE TABLE cliente (
    id_cliente NUMBER(10) NOT NULL,
    id_zona NUMBER(10) NOT NULL,
    id_vendedor NUMBER(10) NOT NULL,
    cedula VARCHAR2(20) NOT NULL,
    nombre_comercial VARCHAR2(100) NOT NULL,
    correo VARCHAR2(100),
    telefono VARCHAR2(20),
    direccion VARCHAR2(200),
    limite_credito NUMBER(12,2) DEFAULT 0 NOT NULL,
    dias_credito NUMBER(3) DEFAULT 15 NOT NULL,
    estado VARCHAR2(10) DEFAULT 'ACTIVO' NOT NULL,
    CONSTRAINT pk_cliente PRIMARY KEY (id_cliente),
    CONSTRAINT uq_cliente_cedula UNIQUE (cedula),
    CONSTRAINT fk_cliente_zona FOREIGN KEY (id_zona) REFERENCES zona (id_zona),
    CONSTRAINT fk_cliente_vendedor FOREIGN KEY (id_vendedor) REFERENCES empleado (id_empleado),
    CONSTRAINT ck_cliente_correo CHECK (correo IS NULL OR correo LIKE '%_@_%._%'),
    CONSTRAINT ck_cliente_limite_credito CHECK (limite_credito >= 0),
    CONSTRAINT ck_cliente_dias_credito CHECK (dias_credito BETWEEN 0 AND 90),
    CONSTRAINT ck_cliente_estado CHECK (estado IN ('ACTIVO', 'INACTIVO', 'SUSPENDIDO'))
);

CREATE TABLE categoria (
    id_categoria NUMBER(10) NOT NULL,
    nombre_categoria VARCHAR2(60) NOT NULL,
    CONSTRAINT pk_categoria PRIMARY KEY (id_categoria),
    CONSTRAINT uq_categoria_nombre UNIQUE (nombre_categoria)
);

CREATE TABLE producto (
    id_producto NUMBER(10) NOT NULL,
    id_categoria NUMBER(10) NOT NULL,
    codigo VARCHAR2(20) NOT NULL,
    nombre_producto VARCHAR2(100) NOT NULL,
    precio_unitario NUMBER(12,2) NOT NULL,
    stock_actual NUMBER(10) DEFAULT 0 NOT NULL,
    activo NUMBER(1) DEFAULT 1 NOT NULL,
    CONSTRAINT pk_producto PRIMARY KEY (id_producto),
    CONSTRAINT uq_producto_codigo UNIQUE (codigo),
    CONSTRAINT fk_producto_categoria FOREIGN KEY (id_categoria) REFERENCES categoria (id_categoria),
    CONSTRAINT ck_producto_precio_unitario CHECK (precio_unitario > 0),
    CONSTRAINT ck_producto_stock_actual CHECK (stock_actual >= 0),
    CONSTRAINT ck_producto_activo CHECK (activo IN (0, 1))
);

CREATE TABLE metodo_pago (
    id_metodo_pago NUMBER(10) NOT NULL,
    nombre_metodo VARCHAR2(40) NOT NULL,
    CONSTRAINT pk_metodo_pago PRIMARY KEY (id_metodo_pago),
    CONSTRAINT uq_metodo_pago_nombre UNIQUE (nombre_metodo)
);

CREATE TABLE factura (
    id_factura NUMBER(10) NOT NULL,
    id_cliente NUMBER(10) NOT NULL,
    id_empleado NUMBER(10) NOT NULL,
    numero_factura VARCHAR2(20) NOT NULL,
    fecha_emision DATE DEFAULT SYSDATE NOT NULL,
    fecha_vencimiento DATE NOT NULL,
    monto_total NUMBER(12,2) DEFAULT 0 NOT NULL,
    saldo_pendiente NUMBER(12,2) DEFAULT 0 NOT NULL,
    estado VARCHAR2(10) DEFAULT 'PENDIENTE' NOT NULL,
    CONSTRAINT pk_factura PRIMARY KEY (id_factura),
    CONSTRAINT uq_factura_numero UNIQUE (numero_factura),
    CONSTRAINT fk_factura_cliente FOREIGN KEY (id_cliente) REFERENCES cliente (id_cliente),
    CONSTRAINT fk_factura_empleado FOREIGN KEY (id_empleado) REFERENCES empleado (id_empleado),
    CONSTRAINT ck_factura_monto_total CHECK (monto_total >= 0),
    CONSTRAINT ck_factura_saldo_pendiente CHECK (saldo_pendiente >= 0),
    CONSTRAINT ck_factura_estado CHECK (estado IN ('PENDIENTE', 'PAGADA', 'ANULADA')),
    CONSTRAINT ck_factura_fechas CHECK (fecha_vencimiento >= fecha_emision),
    CONSTRAINT ck_factura_saldo CHECK (saldo_pendiente <= monto_total)
);

CREATE TABLE detalle_factura (
    id_factura NUMBER(10) NOT NULL,
    id_producto NUMBER(10) NOT NULL,
    cantidad NUMBER(10) NOT NULL,
    precio_unitario NUMBER(12,2) NOT NULL,
    CONSTRAINT pk_detalle_factura PRIMARY KEY (id_factura, id_producto),
    CONSTRAINT fk_detalle_factura FOREIGN KEY (id_factura) REFERENCES factura (id_factura) ON DELETE CASCADE,
    CONSTRAINT fk_detalle_producto FOREIGN KEY (id_producto) REFERENCES producto (id_producto),
    CONSTRAINT ck_detalle_factura_cantidad CHECK (cantidad > 0),
    CONSTRAINT ck_detalle_factura_precio_unitario CHECK (precio_unitario > 0)
);

CREATE TABLE nota_credito (
    id_nota NUMBER(10) NOT NULL,
    id_factura NUMBER(10) NOT NULL,
    fecha_nota DATE DEFAULT SYSDATE NOT NULL,
    monto NUMBER(12,2) NOT NULL,
    motivo VARCHAR2(200) NOT NULL,
    CONSTRAINT pk_nota_credito PRIMARY KEY (id_nota),
    CONSTRAINT fk_nota_factura FOREIGN KEY (id_factura) REFERENCES factura (id_factura),
    CONSTRAINT ck_nota_credito_monto CHECK (monto > 0)
);

CREATE TABLE pago (
    id_pago NUMBER(10) NOT NULL,
    id_cliente NUMBER(10) NOT NULL,
    id_metodo_pago NUMBER(10) NOT NULL,
    fecha_pago DATE DEFAULT SYSDATE NOT NULL,
    monto NUMBER(12,2) NOT NULL,
    referencia VARCHAR2(50),
    monto_sin_aplicar NUMBER(12,2) DEFAULT 0 NOT NULL,
    CONSTRAINT pk_pago PRIMARY KEY (id_pago),
    CONSTRAINT fk_pago_cliente FOREIGN KEY (id_cliente) REFERENCES cliente (id_cliente),
    CONSTRAINT fk_pago_metodo FOREIGN KEY (id_metodo_pago) REFERENCES metodo_pago (id_metodo_pago),
    CONSTRAINT ck_pago_monto CHECK (monto > 0),
    CONSTRAINT ck_pago_monto_sin_aplicar CHECK (monto_sin_aplicar >= 0),
    CONSTRAINT ck_pago_sin_aplicar CHECK (monto_sin_aplicar <= monto)
);

CREATE TABLE aplicacion_pago (
    id_aplicacion NUMBER(10) NOT NULL,
    id_pago NUMBER(10) NOT NULL,
    id_factura NUMBER(10) NOT NULL,
    monto_aplicado NUMBER(12,2) NOT NULL,
    fecha_aplicacion DATE DEFAULT SYSDATE NOT NULL,
    CONSTRAINT pk_aplicacion_pago PRIMARY KEY (id_aplicacion),
    CONSTRAINT fk_aplicacion_pago FOREIGN KEY (id_pago) REFERENCES pago (id_pago),
    CONSTRAINT fk_aplicacion_factura FOREIGN KEY (id_factura) REFERENCES factura (id_factura),
    CONSTRAINT ck_aplicacion_pago_monto_aplicado CHECK (monto_aplicado > 0)
);

CREATE TABLE gestion_cobro (
    id_gestion NUMBER(10) NOT NULL,
    id_cliente NUMBER(10) NOT NULL,
    id_factura NUMBER(10),
    id_empleado NUMBER(10) NOT NULL,
    fecha_hora DATE DEFAULT SYSDATE NOT NULL,
    tipo_gestion VARCHAR2(15) NOT NULL,
    resultado VARCHAR2(20) NOT NULL,
    fecha_promesa DATE,
    observacion VARCHAR2(300),
    CONSTRAINT pk_gestion_cobro PRIMARY KEY (id_gestion),
    CONSTRAINT fk_gestion_cliente FOREIGN KEY (id_cliente) REFERENCES cliente (id_cliente),
    CONSTRAINT fk_gestion_factura FOREIGN KEY (id_factura) REFERENCES factura (id_factura),
    CONSTRAINT fk_gestion_empleado FOREIGN KEY (id_empleado) REFERENCES empleado (id_empleado),
    CONSTRAINT ck_gestion_cobro_tipo_gestion CHECK (tipo_gestion IN ('LLAMADA', 'CORREO', 'VISITA', 'WHATSAPP')),
    CONSTRAINT ck_gestion_cobro_resultado CHECK (resultado IN ('PROMESA_PAGO', 'SIN_RESPUESTA', 'PAGO_REALIZADO', 'DISPUTA', 'OTRO'))
);

CREATE TABLE bitacora (
    id_bitacora NUMBER(10) NOT NULL,
    tabla_afectada VARCHAR2(30) NOT NULL,
    operacion VARCHAR2(10) NOT NULL,
    usuario_bd VARCHAR2(30) NOT NULL,
    fecha_hora DATE DEFAULT SYSDATE NOT NULL,
    detalle VARCHAR2(400),
    CONSTRAINT pk_bitacora PRIMARY KEY (id_bitacora),
    CONSTRAINT ck_bitacora_operacion CHECK (operacion IN ('INSERT', 'UPDATE', 'DELETE'))
);

CREATE INDEX idx_empleado_zona ON empleado (id_zona);
CREATE INDEX idx_cliente_zona ON cliente (id_zona);
CREATE INDEX idx_cliente_vendedor ON cliente (id_vendedor);
CREATE INDEX idx_producto_categoria ON producto (id_categoria);
CREATE INDEX idx_factura_cliente ON factura (id_cliente);
CREATE INDEX idx_factura_empleado ON factura (id_empleado);
CREATE INDEX idx_factura_vencimiento ON factura (fecha_vencimiento);
CREATE INDEX idx_factura_estado ON factura (estado);
CREATE INDEX idx_detalle_producto ON detalle_factura (id_producto);
CREATE INDEX idx_nota_factura ON nota_credito (id_factura);
CREATE INDEX idx_pago_cliente ON pago (id_cliente);
CREATE INDEX idx_pago_metodo ON pago (id_metodo_pago);
CREATE INDEX idx_pago_fecha ON pago (fecha_pago);
CREATE INDEX idx_aplicacion_pago ON aplicacion_pago (id_pago);
CREATE INDEX idx_aplicacion_factura ON aplicacion_pago (id_factura);
CREATE INDEX idx_gestion_cliente ON gestion_cobro (id_cliente);
CREATE INDEX idx_gestion_factura ON gestion_cobro (id_factura);
CREATE INDEX idx_gestion_empleado ON gestion_cobro (id_empleado);
CREATE INDEX idx_bitacora_fecha ON bitacora (fecha_hora);

COMMENT ON TABLE zona IS 'Zonas de reparto y cobro de la empresa.';
COMMENT ON COLUMN zona.id_zona IS 'Identificador de la zona.';
COMMENT ON COLUMN zona.nombre_zona IS 'Nombre de la zona.';
COMMENT ON COLUMN zona.provincia IS 'Provincia a la que pertenece.';
COMMENT ON TABLE empleado IS 'Vendedores, cobradores y administradores con su usuario del sistema.';
COMMENT ON COLUMN empleado.id_empleado IS 'Identificador del empleado.';
COMMENT ON COLUMN empleado.id_zona IS 'Zona asignada (puede ser nula para administradores).';
COMMENT ON COLUMN empleado.nombre IS 'Nombre.';
COMMENT ON COLUMN empleado.apellido IS 'Apellidos.';
COMMENT ON COLUMN empleado.correo IS 'Correo electronico.';
COMMENT ON COLUMN empleado.rol IS 'Rol en el sistema.';
COMMENT ON COLUMN empleado.usuario IS 'Nombre de usuario para iniciar sesion.';
COMMENT ON COLUMN empleado.clave_hash IS 'Clave guardada como hash SHA-256 con sal.';
COMMENT ON COLUMN empleado.activo IS '1 = activo, 0 = inactivo.';
COMMENT ON TABLE cliente IS 'Negocios que compran a credito, con su limite y dias de credito.';
COMMENT ON COLUMN cliente.id_cliente IS 'Identificador del cliente.';
COMMENT ON COLUMN cliente.id_zona IS 'Zona donde esta el cliente.';
COMMENT ON COLUMN cliente.id_vendedor IS 'Vendedor que atiende al cliente.';
COMMENT ON COLUMN cliente.cedula IS 'Cedula fisica o juridica.';
COMMENT ON COLUMN cliente.nombre_comercial IS 'Nombre del negocio.';
COMMENT ON COLUMN cliente.correo IS 'Correo de contacto.';
COMMENT ON COLUMN cliente.telefono IS 'Telefono de contacto.';
COMMENT ON COLUMN cliente.direccion IS 'Direccion del negocio.';
COMMENT ON COLUMN cliente.limite_credito IS 'Monto maximo que puede deber.';
COMMENT ON COLUMN cliente.dias_credito IS 'Dias de plazo para pagar.';
COMMENT ON COLUMN cliente.estado IS 'Estado del cliente.';
COMMENT ON TABLE categoria IS 'Categorias para agrupar los productos.';
COMMENT ON COLUMN categoria.id_categoria IS 'Identificador de la categoria.';
COMMENT ON COLUMN categoria.nombre_categoria IS 'Nombre de la categoria.';
COMMENT ON TABLE producto IS 'Catalogo de productos con precio y existencias.';
COMMENT ON COLUMN producto.id_producto IS 'Identificador del producto.';
COMMENT ON COLUMN producto.id_categoria IS 'Categoria del producto.';
COMMENT ON COLUMN producto.codigo IS 'Codigo interno.';
COMMENT ON COLUMN producto.nombre_producto IS 'Nombre del producto.';
COMMENT ON COLUMN producto.precio_unitario IS 'Precio de venta actual.';
COMMENT ON COLUMN producto.stock_actual IS 'Unidades disponibles.';
COMMENT ON COLUMN producto.activo IS '1 = a la venta, 0 = descontinuado.';
COMMENT ON TABLE metodo_pago IS 'Formas en que un cliente puede pagar.';
COMMENT ON COLUMN metodo_pago.id_metodo_pago IS 'Identificador del metodo de pago.';
COMMENT ON COLUMN metodo_pago.nombre_metodo IS 'Efectivo, transferencia, cheque, SINPE Movil.';
COMMENT ON TABLE factura IS 'Venta a credito con monto, vencimiento y saldo pendiente.';
COMMENT ON COLUMN factura.id_factura IS 'Identificador de la factura.';
COMMENT ON COLUMN factura.id_cliente IS 'Cliente al que se factura.';
COMMENT ON COLUMN factura.id_empleado IS 'Vendedor que hizo la venta.';
COMMENT ON COLUMN factura.numero_factura IS 'Numero visible de la factura.';
COMMENT ON COLUMN factura.fecha_emision IS 'Fecha en que se emitio.';
COMMENT ON COLUMN factura.fecha_vencimiento IS 'Fecha limite de pago.';
COMMENT ON COLUMN factura.monto_total IS 'Total de la factura (suma del detalle).';
COMMENT ON COLUMN factura.saldo_pendiente IS 'Lo que falta por pagar (total - notas - pagos).';
COMMENT ON COLUMN factura.estado IS 'Estado de la factura.';
COMMENT ON TABLE detalle_factura IS 'Productos vendidos en cada factura (tabla intermedia FACTURA-PRODUCTO).';
COMMENT ON COLUMN detalle_factura.id_factura IS 'Factura a la que pertenece.';
COMMENT ON COLUMN detalle_factura.id_producto IS 'Producto vendido.';
COMMENT ON COLUMN detalle_factura.cantidad IS 'Unidades vendidas.';
COMMENT ON COLUMN detalle_factura.precio_unitario IS 'Precio al momento de la venta.';
COMMENT ON TABLE nota_credito IS 'Descuentos o devoluciones que reducen el saldo de una factura.';
COMMENT ON COLUMN nota_credito.id_nota IS 'Identificador de la nota.';
COMMENT ON COLUMN nota_credito.id_factura IS 'Factura afectada.';
COMMENT ON COLUMN nota_credito.fecha_nota IS 'Fecha de la nota.';
COMMENT ON COLUMN nota_credito.monto IS 'Monto que se descuenta.';
COMMENT ON COLUMN nota_credito.motivo IS 'Razon de la nota de credito.';
COMMENT ON TABLE pago IS 'Dinero recibido de un cliente.';
COMMENT ON COLUMN pago.id_pago IS 'Identificador del pago.';
COMMENT ON COLUMN pago.id_cliente IS 'Cliente que pago.';
COMMENT ON COLUMN pago.id_metodo_pago IS 'Forma de pago usada.';
COMMENT ON COLUMN pago.fecha_pago IS 'Fecha en que se recibio el pago.';
COMMENT ON COLUMN pago.monto IS 'Monto recibido.';
COMMENT ON COLUMN pago.referencia IS 'Numero de transferencia, cheque o comprobante.';
COMMENT ON COLUMN pago.monto_sin_aplicar IS 'Parte del pago que aun no se reparte entre facturas.';
COMMENT ON TABLE aplicacion_pago IS 'Reparto de un pago entre una o mas facturas (tabla intermedia PAGO-FACTURA).';
COMMENT ON COLUMN aplicacion_pago.id_aplicacion IS 'Identificador de la aplicacion.';
COMMENT ON COLUMN aplicacion_pago.id_pago IS 'Pago que se reparte.';
COMMENT ON COLUMN aplicacion_pago.id_factura IS 'Factura que recibe el monto.';
COMMENT ON COLUMN aplicacion_pago.monto_aplicado IS 'Monto aplicado a la factura.';
COMMENT ON COLUMN aplicacion_pago.fecha_aplicacion IS 'Fecha en que se aplico.';
COMMENT ON TABLE gestion_cobro IS 'Historial de llamadas, visitas y promesas de pago a los clientes.';
COMMENT ON COLUMN gestion_cobro.id_gestion IS 'Identificador de la gestion.';
COMMENT ON COLUMN gestion_cobro.id_cliente IS 'Cliente contactado.';
COMMENT ON COLUMN gestion_cobro.id_factura IS 'Factura de la que se habla (opcional).';
COMMENT ON COLUMN gestion_cobro.id_empleado IS 'Cobrador que hizo la gestion.';
COMMENT ON COLUMN gestion_cobro.fecha_hora IS 'Fecha y hora del contacto.';
COMMENT ON COLUMN gestion_cobro.tipo_gestion IS 'Medio usado.';
COMMENT ON COLUMN gestion_cobro.resultado IS 'Resultado del contacto.';
COMMENT ON COLUMN gestion_cobro.fecha_promesa IS 'Fecha prometida de pago.';
COMMENT ON COLUMN gestion_cobro.observacion IS 'Notas de la gestion.';
COMMENT ON TABLE bitacora IS 'Registro de cambios hecho por los disparadores (sin llaves foraneas a proposito).';
COMMENT ON COLUMN bitacora.id_bitacora IS 'Identificador del registro.';
COMMENT ON COLUMN bitacora.tabla_afectada IS 'Tabla que cambio.';
COMMENT ON COLUMN bitacora.operacion IS 'Tipo de cambio.';
COMMENT ON COLUMN bitacora.usuario_bd IS 'Usuario de la base de datos que hizo el cambio.';
COMMENT ON COLUMN bitacora.fecha_hora IS 'Momento del cambio.';
COMMENT ON COLUMN bitacora.detalle IS 'Resumen del cambio.';
