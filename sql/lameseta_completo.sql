-- Instalacion completa (scripts 01 a 10). Ejecutar como LAMESETA despues del script 00.
SET DEFINE OFF

PROMPT >>> 01_tablas
-- Script 01: tablas, secuencias, indices y comentarios.
-- Ejecutar conectado como el usuario LAMESETA (PDB, no CDB$ROOT).

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


PROMPT >>> 02_funciones
-- Script 02: funciones (solo leen datos, no hacen COMMIT).

CREATE OR REPLACE FUNCTION fn_hash_clave(p_usuario IN VARCHAR2, p_clave IN VARCHAR2)
RETURN VARCHAR2 IS
  v_hash VARCHAR2(64);
BEGIN
  SELECT RAWTOHEX(STANDARD_HASH('LM2026:' || LOWER(p_usuario) || ':' || p_clave, 'SHA256'))
    INTO v_hash
    FROM dual;
  RETURN v_hash;
END fn_hash_clave;
/

CREATE OR REPLACE FUNCTION fn_autenticar(p_usuario IN VARCHAR2, p_clave IN VARCHAR2)
RETURN NUMBER IS
  v_id empleado.id_empleado%TYPE;
BEGIN
  SELECT id_empleado
    INTO v_id
    FROM empleado
   WHERE LOWER(usuario) = LOWER(p_usuario)
     AND clave_hash = fn_hash_clave(p_usuario, p_clave)
     AND activo = 1;
  RETURN v_id;
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    RETURN NULL;
END fn_autenticar;
/

CREATE OR REPLACE FUNCTION fn_rol_empleado(p_id_empleado IN NUMBER)
RETURN VARCHAR2 IS
  v_rol empleado.rol%TYPE;
BEGIN
  SELECT rol INTO v_rol FROM empleado WHERE id_empleado = p_id_empleado;
  RETURN v_rol;
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    RETURN NULL;
END fn_rol_empleado;
/

CREATE OR REPLACE FUNCTION fn_nombre_empleado(p_id_empleado IN NUMBER)
RETURN VARCHAR2 IS
  v_nombre VARCHAR2(130);
BEGIN
  SELECT nombre || ' ' || apellido INTO v_nombre FROM empleado WHERE id_empleado = p_id_empleado;
  RETURN v_nombre;
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    RETURN NULL;
END fn_nombre_empleado;
/

CREATE OR REPLACE FUNCTION fn_estado_cliente(p_id_cliente IN NUMBER)
RETURN VARCHAR2 IS
  v_estado cliente.estado%TYPE;
BEGIN
  SELECT estado INTO v_estado FROM cliente WHERE id_cliente = p_id_cliente;
  RETURN v_estado;
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    RETURN NULL;
END fn_estado_cliente;
/

CREATE OR REPLACE FUNCTION fn_nombre_cliente(p_id_cliente IN NUMBER)
RETURN VARCHAR2 IS
  v_nombre cliente.nombre_comercial%TYPE;
BEGIN
  SELECT nombre_comercial INTO v_nombre FROM cliente WHERE id_cliente = p_id_cliente;
  RETURN v_nombre;
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    RETURN NULL;
END fn_nombre_cliente;
/

CREATE OR REPLACE FUNCTION fn_estado_factura(p_id_factura IN NUMBER)
RETURN VARCHAR2 IS
  v_estado factura.estado%TYPE;
BEGIN
  SELECT estado INTO v_estado FROM factura WHERE id_factura = p_id_factura;
  RETURN v_estado;
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    RETURN NULL;
END fn_estado_factura;
/

CREATE OR REPLACE FUNCTION fn_precio_producto(p_id_producto IN NUMBER)
RETURN NUMBER IS
  v_precio producto.precio_unitario%TYPE;
BEGIN
  SELECT precio_unitario INTO v_precio FROM producto WHERE id_producto = p_id_producto;
  RETURN v_precio;
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    RETURN NULL;
END fn_precio_producto;
/

CREATE OR REPLACE FUNCTION fn_stock_producto(p_id_producto IN NUMBER)
RETURN NUMBER IS
  v_stock producto.stock_actual%TYPE;
BEGIN
  SELECT stock_actual INTO v_stock FROM producto WHERE id_producto = p_id_producto;
  RETURN v_stock;
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    RETURN 0;
END fn_stock_producto;
/

CREATE OR REPLACE FUNCTION fn_saldo_factura(p_id_factura IN NUMBER)
RETURN NUMBER IS
  v_saldo factura.saldo_pendiente%TYPE;
BEGIN
  SELECT saldo_pendiente INTO v_saldo FROM factura WHERE id_factura = p_id_factura;
  RETURN v_saldo;
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    RETURN 0;
END fn_saldo_factura;
/

CREATE OR REPLACE FUNCTION fn_total_factura(p_id_factura IN NUMBER)
RETURN NUMBER IS
  v_total NUMBER;
BEGIN
  SELECT NVL(SUM(cantidad * precio_unitario), 0)
    INTO v_total
    FROM detalle_factura
   WHERE id_factura = p_id_factura;
  RETURN v_total;
END fn_total_factura;
/

CREATE OR REPLACE FUNCTION fn_total_notas_factura(p_id_factura IN NUMBER)
RETURN NUMBER IS
  v_total NUMBER;
BEGIN
  SELECT NVL(SUM(monto), 0) INTO v_total FROM nota_credito WHERE id_factura = p_id_factura;
  RETURN v_total;
END fn_total_notas_factura;
/

CREATE OR REPLACE FUNCTION fn_monto_aplicado_factura(p_id_factura IN NUMBER)
RETURN NUMBER IS
  v_total NUMBER;
BEGIN
  SELECT NVL(SUM(monto_aplicado), 0) INTO v_total FROM aplicacion_pago WHERE id_factura = p_id_factura;
  RETURN v_total;
END fn_monto_aplicado_factura;
/

CREATE OR REPLACE FUNCTION fn_monto_aplicado_pago(p_id_pago IN NUMBER)
RETURN NUMBER IS
  v_total NUMBER;
BEGIN
  SELECT NVL(SUM(monto_aplicado), 0) INTO v_total FROM aplicacion_pago WHERE id_pago = p_id_pago;
  RETURN v_total;
END fn_monto_aplicado_pago;
/

CREATE OR REPLACE FUNCTION fn_saldo_cliente(p_id_cliente IN NUMBER)
RETURN NUMBER IS
  v_saldo NUMBER;
BEGIN
  SELECT NVL(SUM(saldo_pendiente), 0)
    INTO v_saldo
    FROM factura
   WHERE id_cliente = p_id_cliente
     AND estado <> 'ANULADA';
  RETURN v_saldo;
END fn_saldo_cliente;
/

CREATE OR REPLACE FUNCTION fn_credito_disponible(p_id_cliente IN NUMBER)
RETURN NUMBER IS
  v_limite cliente.limite_credito%TYPE;
BEGIN
  SELECT limite_credito INTO v_limite FROM cliente WHERE id_cliente = p_id_cliente;
  RETURN v_limite - fn_saldo_cliente(p_id_cliente);
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    RETURN 0;
END fn_credito_disponible;
/

CREATE OR REPLACE FUNCTION fn_dias_mora(p_id_factura IN NUMBER)
RETURN NUMBER IS
  v_dias NUMBER;
BEGIN
  SELECT CASE
           WHEN estado = 'PENDIENTE' AND saldo_pendiente > 0 AND TRUNC(SYSDATE) > TRUNC(fecha_vencimiento)
             THEN TRUNC(SYSDATE) - TRUNC(fecha_vencimiento)
           ELSE 0
         END
    INTO v_dias
    FROM factura
   WHERE id_factura = p_id_factura;
  RETURN v_dias;
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    RETURN 0;
END fn_dias_mora;
/

CREATE OR REPLACE FUNCTION fn_clasificar_mora(p_dias IN NUMBER)
RETURN VARCHAR2 DETERMINISTIC IS
BEGIN
  IF p_dias <= 30 THEN
    RETURN '0-30';
  ELSIF p_dias <= 60 THEN
    RETURN '31-60';
  ELSIF p_dias <= 90 THEN
    RETURN '61-90';
  END IF;
  RETURN 'MAS DE 90';
END fn_clasificar_mora;
/

CREATE OR REPLACE FUNCTION fn_siguiente_numero_factura
RETURN VARCHAR2 IS
  v_numero VARCHAR2(20);
BEGIN
  SELECT 'F-' || LPAD(seq_numero_factura.NEXTVAL, 8, '0') INTO v_numero FROM dual;
  RETURN v_numero;
END fn_siguiente_numero_factura;
/

CREATE OR REPLACE FUNCTION fn_fecha_vencimiento(p_id_cliente IN NUMBER, p_fecha_emision IN DATE)
RETURN DATE IS
  v_dias cliente.dias_credito%TYPE;
BEGIN
  SELECT dias_credito INTO v_dias FROM cliente WHERE id_cliente = p_id_cliente;
  RETURN TRUNC(p_fecha_emision) + v_dias;
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    RETURN TRUNC(p_fecha_emision);
END fn_fecha_vencimiento;
/

CREATE OR REPLACE FUNCTION fn_ventas_empleado(p_id_empleado IN NUMBER, p_desde IN DATE, p_hasta IN DATE)
RETURN NUMBER IS
  v_total NUMBER;
BEGIN
  SELECT NVL(SUM(monto_total), 0)
    INTO v_total
    FROM factura
   WHERE id_empleado = p_id_empleado
     AND estado <> 'ANULADA'
     AND fecha_emision >= TRUNC(p_desde)
     AND fecha_emision < TRUNC(p_hasta) + 1;
  RETURN v_total;
END fn_ventas_empleado;
/

CREATE OR REPLACE FUNCTION fn_cliente_es_moroso(p_id_cliente IN NUMBER)
RETURN NUMBER IS
  v_cantidad NUMBER;
BEGIN
  SELECT COUNT(*)
    INTO v_cantidad
    FROM factura
   WHERE id_cliente = p_id_cliente
     AND estado = 'PENDIENTE'
     AND saldo_pendiente > 0
     AND fecha_vencimiento < TRUNC(SYSDATE);
  IF v_cantidad > 0 THEN
    RETURN 1;
  END IF;
  RETURN 0;
END fn_cliente_es_moroso;
/

CREATE OR REPLACE FUNCTION fn_facturas_pendientes_cliente(p_id_cliente IN NUMBER)
RETURN NUMBER IS
  v_cantidad NUMBER;
BEGIN
  SELECT COUNT(*)
    INTO v_cantidad
    FROM factura
   WHERE id_cliente = p_id_cliente
     AND estado = 'PENDIENTE'
     AND saldo_pendiente > 0;
  RETURN v_cantidad;
END fn_facturas_pendientes_cliente;
/

CREATE OR REPLACE FUNCTION fn_monto_sin_aplicar_cliente(p_id_cliente IN NUMBER)
RETURN NUMBER IS
  v_total NUMBER;
BEGIN
  SELECT NVL(SUM(monto_sin_aplicar), 0) INTO v_total FROM pago WHERE id_cliente = p_id_cliente;
  RETURN v_total;
END fn_monto_sin_aplicar_cliente;
/


PROMPT >>> 03_procedimientos_base
-- Script 03: procedimientos base que usan los paquetes y los disparadores.

CREATE OR REPLACE PROCEDURE sp_registrar_bitacora(
    p_tabla IN VARCHAR2,
    p_operacion IN VARCHAR2,
    p_detalle IN VARCHAR2) IS
BEGIN
  INSERT INTO bitacora (id_bitacora, tabla_afectada, operacion, usuario_bd, fecha_hora, detalle)
  VALUES (seq_bitacora.NEXTVAL, p_tabla, p_operacion, SYS_CONTEXT('USERENV', 'SESSION_USER'),
          SYSDATE, SUBSTR(p_detalle, 1, 400));
END sp_registrar_bitacora;
/

CREATE OR REPLACE PROCEDURE sp_recalcular_factura(p_id_factura IN NUMBER) IS
  v_estado factura.estado%TYPE;
  v_total factura.monto_total%TYPE;
  v_saldo factura.saldo_pendiente%TYPE;
BEGIN
  SELECT estado INTO v_estado FROM factura WHERE id_factura = p_id_factura FOR UPDATE;
  IF v_estado = 'ANULADA' THEN
    RETURN;
  END IF;
  v_total := fn_total_factura(p_id_factura);
  v_saldo := v_total - fn_total_notas_factura(p_id_factura) - fn_monto_aplicado_factura(p_id_factura);
  IF v_saldo < 0 THEN
    RAISE_APPLICATION_ERROR(-20120, 'Las notas o pagos aplicados superan el total de la factura.');
  END IF;
  UPDATE factura
     SET monto_total = v_total,
         saldo_pendiente = v_saldo
   WHERE id_factura = p_id_factura;
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    RAISE_APPLICATION_ERROR(-20002, 'No existe la factura indicada.');
END sp_recalcular_factura;
/


PROMPT >>> 04_vistas
-- Script 04: vistas para los reportes.

CREATE OR REPLACE VIEW vw_estado_cuenta AS
SELECT f.id_cliente,
       c.nombre_comercial,
       f.id_factura,
       f.numero_factura,
       f.fecha_emision,
       f.fecha_vencimiento,
       f.monto_total,
       fn_total_notas_factura(f.id_factura) AS total_notas,
       fn_monto_aplicado_factura(f.id_factura) AS total_pagado,
       f.saldo_pendiente,
       f.estado,
       fn_dias_mora(f.id_factura) AS dias_mora
  FROM factura f
  JOIN cliente c ON c.id_cliente = f.id_cliente;

CREATE OR REPLACE VIEW vw_facturas_vencidas AS
SELECT f.id_factura,
       f.numero_factura,
       f.id_cliente,
       c.nombre_comercial,
       e.nombre || ' ' || e.apellido AS vendedor,
       f.fecha_vencimiento,
       f.saldo_pendiente,
       fn_dias_mora(f.id_factura) AS dias_mora,
       fn_clasificar_mora(fn_dias_mora(f.id_factura)) AS rango_mora
  FROM factura f
  JOIN cliente c ON c.id_cliente = f.id_cliente
  JOIN empleado e ON e.id_empleado = c.id_vendedor
 WHERE f.estado = 'PENDIENTE'
   AND f.saldo_pendiente > 0
   AND f.fecha_vencimiento < TRUNC(SYSDATE);

CREATE OR REPLACE VIEW vw_antiguedad_saldos AS
SELECT c.id_cliente,
       c.nombre_comercial,
       SUM(CASE WHEN fn_dias_mora(f.id_factura) <= 30 THEN f.saldo_pendiente ELSE 0 END) AS rango_0_30,
       SUM(CASE WHEN fn_dias_mora(f.id_factura) BETWEEN 31 AND 60 THEN f.saldo_pendiente ELSE 0 END) AS rango_31_60,
       SUM(CASE WHEN fn_dias_mora(f.id_factura) BETWEEN 61 AND 90 THEN f.saldo_pendiente ELSE 0 END) AS rango_61_90,
       SUM(CASE WHEN fn_dias_mora(f.id_factura) > 90 THEN f.saldo_pendiente ELSE 0 END) AS rango_mas_90,
       SUM(f.saldo_pendiente) AS saldo_total
  FROM cliente c
  JOIN factura f ON f.id_cliente = c.id_cliente
 WHERE f.estado = 'PENDIENTE'
   AND f.saldo_pendiente > 0
 GROUP BY c.id_cliente, c.nombre_comercial;

CREATE OR REPLACE VIEW vw_clientes_morosos AS
SELECT v.id_cliente,
       v.nombre_comercial,
       v.vendedor,
       COUNT(*) AS facturas_vencidas,
       SUM(v.saldo_pendiente) AS monto_vencido,
       MAX(v.dias_mora) AS max_dias_mora
  FROM vw_facturas_vencidas v
 GROUP BY v.id_cliente, v.nombre_comercial, v.vendedor;

CREATE OR REPLACE VIEW vw_clientes_credito AS
SELECT c.id_cliente,
       c.nombre_comercial,
       c.estado,
       c.limite_credito,
       fn_saldo_cliente(c.id_cliente) AS saldo_actual,
       fn_credito_disponible(c.id_cliente) AS credito_disponible,
       fn_cliente_es_moroso(c.id_cliente) AS es_moroso
  FROM cliente c;

CREATE OR REPLACE VIEW vw_ventas_por_zona AS
SELECT z.id_zona,
       z.nombre_zona,
       COUNT(f.id_factura) AS cantidad_facturas,
       NVL(SUM(f.monto_total), 0) AS total_vendido
  FROM zona z
  LEFT JOIN cliente c ON c.id_zona = z.id_zona
  LEFT JOIN factura f ON f.id_cliente = c.id_cliente AND f.estado <> 'ANULADA'
 GROUP BY z.id_zona, z.nombre_zona;

CREATE OR REPLACE VIEW vw_ventas_por_vendedor AS
SELECT e.id_empleado,
       e.nombre || ' ' || e.apellido AS vendedor,
       COUNT(f.id_factura) AS cantidad_facturas,
       NVL(SUM(f.monto_total), 0) AS total_vendido
  FROM empleado e
  LEFT JOIN factura f ON f.id_empleado = e.id_empleado AND f.estado <> 'ANULADA'
 WHERE e.rol = 'VENDEDOR'
 GROUP BY e.id_empleado, e.nombre, e.apellido;

CREATE OR REPLACE VIEW vw_inventario_productos AS
SELECT p.id_producto,
       p.codigo,
       p.nombre_producto,
       k.nombre_categoria,
       p.precio_unitario,
       p.stock_actual,
       p.precio_unitario * p.stock_actual AS valor_inventario,
       p.activo
  FROM producto p
  JOIN categoria k ON k.id_categoria = p.id_categoria;

CREATE OR REPLACE VIEW vw_pagos_sin_aplicar AS
SELECT p.id_pago,
       p.id_cliente,
       c.nombre_comercial,
       m.nombre_metodo,
       p.fecha_pago,
       p.monto,
       p.monto_sin_aplicar,
       p.referencia
  FROM pago p
  JOIN cliente c ON c.id_cliente = p.id_cliente
  JOIN metodo_pago m ON m.id_metodo_pago = p.id_metodo_pago
 WHERE p.monto_sin_aplicar > 0;

CREATE OR REPLACE VIEW vw_gestiones_detalle AS
SELECT g.id_gestion,
       g.fecha_hora,
       g.id_cliente,
       c.nombre_comercial,
       f.numero_factura,
       e.nombre || ' ' || e.apellido AS cobrador,
       g.tipo_gestion,
       g.resultado,
       g.fecha_promesa,
       g.observacion
  FROM gestion_cobro g
  JOIN cliente c ON c.id_cliente = g.id_cliente
  JOIN empleado e ON e.id_empleado = g.id_empleado
  LEFT JOIN factura f ON f.id_factura = g.id_factura;

CREATE OR REPLACE VIEW vw_detalle_factura_completo AS
SELECT d.id_factura,
       f.numero_factura,
       d.id_producto,
       p.codigo,
       p.nombre_producto,
       d.cantidad,
       d.precio_unitario,
       d.cantidad * d.precio_unitario AS subtotal
  FROM detalle_factura d
  JOIN factura f ON f.id_factura = d.id_factura
  JOIN producto p ON p.id_producto = d.id_producto;

CREATE OR REPLACE VIEW vw_resumen_cartera AS
SELECT NVL(SUM(saldo_pendiente), 0) AS cartera_total,
       NVL(SUM(CASE WHEN fecha_vencimiento < TRUNC(SYSDATE) THEN saldo_pendiente ELSE 0 END), 0) AS cartera_vencida,
       NVL(SUM(CASE WHEN fecha_vencimiento >= TRUNC(SYSDATE) THEN saldo_pendiente ELSE 0 END), 0) AS cartera_vigente,
       COUNT(DISTINCT id_cliente) AS clientes_con_saldo,
       COUNT(*) AS facturas_pendientes
  FROM factura
 WHERE estado = 'PENDIENTE'
   AND saldo_pendiente > 0;


PROMPT >>> 05_paquetes_crud
-- Script 05: paquetes con el CRUD de las 13 tablas (insertar, actualizar, eliminar, obtener, listar).
-- Ninguna operacion hace COMMIT: lo controla quien llama (el programa Python o el usuario).

CREATE OR REPLACE PACKAGE pkg_zona AS
  PROCEDURE sp_insertar(
      p_nombre_zona IN zona.nombre_zona%TYPE,
      p_provincia IN zona.provincia%TYPE,
      p_id_zona OUT zona.id_zona%TYPE);
  PROCEDURE sp_actualizar(
      p_id_zona IN zona.id_zona%TYPE,
      p_nombre_zona IN zona.nombre_zona%TYPE,
      p_provincia IN zona.provincia%TYPE);
  PROCEDURE sp_eliminar(
      p_id_zona IN zona.id_zona%TYPE);
  PROCEDURE sp_obtener(
      p_id_zona IN zona.id_zona%TYPE,
      p_cursor OUT SYS_REFCURSOR);
  PROCEDURE sp_listar(
      p_cursor OUT SYS_REFCURSOR);
END pkg_zona;
/

CREATE OR REPLACE PACKAGE BODY pkg_zona AS
  e_hijos EXCEPTION;
  PRAGMA EXCEPTION_INIT(e_hijos, -2292);
  e_padre EXCEPTION;
  PRAGMA EXCEPTION_INIT(e_padre, -2291);
  e_check EXCEPTION;
  PRAGMA EXCEPTION_INIT(e_check, -2290);
  e_nulo EXCEPTION;
  PRAGMA EXCEPTION_INIT(e_nulo, -1400);

  PROCEDURE sp_insertar(
      p_nombre_zona IN zona.nombre_zona%TYPE,
      p_provincia IN zona.provincia%TYPE,
      p_id_zona OUT zona.id_zona%TYPE) IS
  BEGIN
    INSERT INTO zona (id_zona, nombre_zona, provincia)
    VALUES (seq_zona.NEXTVAL, p_nombre_zona, p_provincia)
    RETURNING id_zona INTO p_id_zona;
  EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
      RAISE_APPLICATION_ERROR(-20001, 'Ya existe un registro con ese valor unico en ZONA.');
    WHEN NO_DATA_FOUND THEN
      RAISE_APPLICATION_ERROR(-20002, 'No existe el registro buscado en ZONA.');
    WHEN e_hijos THEN
      RAISE_APPLICATION_ERROR(-20003, 'No se puede borrar: ZONA tiene registros relacionados.');
    WHEN e_padre THEN
      RAISE_APPLICATION_ERROR(-20005, 'Una referencia no existe: revise las llaves de ZONA.');
    WHEN e_check THEN
      RAISE_APPLICATION_ERROR(-20006, 'Un valor no cumple las reglas de validacion de ZONA.');
    WHEN e_nulo THEN
      RAISE_APPLICATION_ERROR(-20007, 'Falta un dato obligatorio en ZONA.');
  END sp_insertar;

  PROCEDURE sp_actualizar(
      p_id_zona IN zona.id_zona%TYPE,
      p_nombre_zona IN zona.nombre_zona%TYPE,
      p_provincia IN zona.provincia%TYPE) IS
  BEGIN
    UPDATE zona
       SET nombre_zona = p_nombre_zona,
           provincia = p_provincia
     WHERE id_zona = p_id_zona;
    IF SQL%ROWCOUNT = 0 THEN
      RAISE_APPLICATION_ERROR(-20002, 'No existe el registro buscado en ZONA.');
    END IF;
  EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
      RAISE_APPLICATION_ERROR(-20001, 'Ya existe un registro con ese valor unico en ZONA.');
    WHEN NO_DATA_FOUND THEN
      RAISE_APPLICATION_ERROR(-20002, 'No existe el registro buscado en ZONA.');
    WHEN e_hijos THEN
      RAISE_APPLICATION_ERROR(-20003, 'No se puede borrar: ZONA tiene registros relacionados.');
    WHEN e_padre THEN
      RAISE_APPLICATION_ERROR(-20005, 'Una referencia no existe: revise las llaves de ZONA.');
    WHEN e_check THEN
      RAISE_APPLICATION_ERROR(-20006, 'Un valor no cumple las reglas de validacion de ZONA.');
    WHEN e_nulo THEN
      RAISE_APPLICATION_ERROR(-20007, 'Falta un dato obligatorio en ZONA.');
  END sp_actualizar;

  PROCEDURE sp_eliminar(
      p_id_zona IN zona.id_zona%TYPE) IS
  BEGIN
    DELETE FROM zona WHERE id_zona = p_id_zona;
    IF SQL%ROWCOUNT = 0 THEN
      RAISE_APPLICATION_ERROR(-20002, 'No existe el registro buscado en ZONA.');
    END IF;
  EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
      RAISE_APPLICATION_ERROR(-20001, 'Ya existe un registro con ese valor unico en ZONA.');
    WHEN NO_DATA_FOUND THEN
      RAISE_APPLICATION_ERROR(-20002, 'No existe el registro buscado en ZONA.');
    WHEN e_hijos THEN
      RAISE_APPLICATION_ERROR(-20003, 'No se puede borrar: ZONA tiene registros relacionados.');
    WHEN e_padre THEN
      RAISE_APPLICATION_ERROR(-20005, 'Una referencia no existe: revise las llaves de ZONA.');
    WHEN e_check THEN
      RAISE_APPLICATION_ERROR(-20006, 'Un valor no cumple las reglas de validacion de ZONA.');
    WHEN e_nulo THEN
      RAISE_APPLICATION_ERROR(-20007, 'Falta un dato obligatorio en ZONA.');
  END sp_eliminar;

  PROCEDURE sp_obtener(
      p_id_zona IN zona.id_zona%TYPE,
      p_cursor OUT SYS_REFCURSOR) IS
  BEGIN
    OPEN p_cursor FOR
      SELECT id_zona, nombre_zona, provincia
        FROM zona
       WHERE id_zona = p_id_zona;
  END sp_obtener;

  PROCEDURE sp_listar(
      p_cursor OUT SYS_REFCURSOR) IS
  BEGIN
    OPEN p_cursor FOR
      SELECT id_zona, nombre_zona, provincia
        FROM zona
       ORDER BY id_zona;
  END sp_listar;
END pkg_zona;
/

CREATE OR REPLACE PACKAGE pkg_empleado AS
  PROCEDURE sp_insertar(
      p_id_zona IN empleado.id_zona%TYPE,
      p_nombre IN empleado.nombre%TYPE,
      p_apellido IN empleado.apellido%TYPE,
      p_correo IN empleado.correo%TYPE,
      p_rol IN empleado.rol%TYPE,
      p_usuario IN empleado.usuario%TYPE,
      p_clave IN VARCHAR2,
      p_activo IN empleado.activo%TYPE,
      p_id_empleado OUT empleado.id_empleado%TYPE);
  PROCEDURE sp_actualizar(
      p_id_empleado IN empleado.id_empleado%TYPE,
      p_id_zona IN empleado.id_zona%TYPE,
      p_nombre IN empleado.nombre%TYPE,
      p_apellido IN empleado.apellido%TYPE,
      p_correo IN empleado.correo%TYPE,
      p_rol IN empleado.rol%TYPE,
      p_activo IN empleado.activo%TYPE);
  PROCEDURE sp_eliminar(
      p_id_empleado IN empleado.id_empleado%TYPE);
  PROCEDURE sp_obtener(
      p_id_empleado IN empleado.id_empleado%TYPE,
      p_cursor OUT SYS_REFCURSOR);
  PROCEDURE sp_listar(
      p_cursor OUT SYS_REFCURSOR);
END pkg_empleado;
/

CREATE OR REPLACE PACKAGE BODY pkg_empleado AS
  e_hijos EXCEPTION;
  PRAGMA EXCEPTION_INIT(e_hijos, -2292);
  e_padre EXCEPTION;
  PRAGMA EXCEPTION_INIT(e_padre, -2291);
  e_check EXCEPTION;
  PRAGMA EXCEPTION_INIT(e_check, -2290);
  e_nulo EXCEPTION;
  PRAGMA EXCEPTION_INIT(e_nulo, -1400);

  PROCEDURE sp_insertar(
      p_id_zona IN empleado.id_zona%TYPE,
      p_nombre IN empleado.nombre%TYPE,
      p_apellido IN empleado.apellido%TYPE,
      p_correo IN empleado.correo%TYPE,
      p_rol IN empleado.rol%TYPE,
      p_usuario IN empleado.usuario%TYPE,
      p_clave IN VARCHAR2,
      p_activo IN empleado.activo%TYPE,
      p_id_empleado OUT empleado.id_empleado%TYPE) IS
  BEGIN
    IF p_clave IS NULL OR LENGTH(p_clave) < 6 THEN
      RAISE_APPLICATION_ERROR(-20020, 'La clave debe tener al menos 6 caracteres.');
    END IF;
    INSERT INTO empleado (id_empleado, id_zona, nombre, apellido, correo, rol, usuario, clave_hash, activo)
    VALUES (seq_empleado.NEXTVAL, p_id_zona, p_nombre, p_apellido, p_correo, p_rol, p_usuario, fn_hash_clave(p_usuario, p_clave), NVL(p_activo, 1))
    RETURNING id_empleado INTO p_id_empleado;
  EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
      RAISE_APPLICATION_ERROR(-20001, 'Ya existe un registro con ese valor unico en EMPLEADO.');
    WHEN NO_DATA_FOUND THEN
      RAISE_APPLICATION_ERROR(-20002, 'No existe el registro buscado en EMPLEADO.');
    WHEN e_hijos THEN
      RAISE_APPLICATION_ERROR(-20003, 'No se puede borrar: EMPLEADO tiene registros relacionados.');
    WHEN e_padre THEN
      RAISE_APPLICATION_ERROR(-20005, 'Una referencia no existe: revise las llaves de EMPLEADO.');
    WHEN e_check THEN
      RAISE_APPLICATION_ERROR(-20006, 'Un valor no cumple las reglas de validacion de EMPLEADO.');
    WHEN e_nulo THEN
      RAISE_APPLICATION_ERROR(-20007, 'Falta un dato obligatorio en EMPLEADO.');
  END sp_insertar;

  PROCEDURE sp_actualizar(
      p_id_empleado IN empleado.id_empleado%TYPE,
      p_id_zona IN empleado.id_zona%TYPE,
      p_nombre IN empleado.nombre%TYPE,
      p_apellido IN empleado.apellido%TYPE,
      p_correo IN empleado.correo%TYPE,
      p_rol IN empleado.rol%TYPE,
      p_activo IN empleado.activo%TYPE) IS
  BEGIN
    UPDATE empleado
       SET id_zona = p_id_zona,
           nombre = p_nombre,
           apellido = p_apellido,
           correo = p_correo,
           rol = p_rol,
           activo = p_activo
     WHERE id_empleado = p_id_empleado;
    IF SQL%ROWCOUNT = 0 THEN
      RAISE_APPLICATION_ERROR(-20002, 'No existe el registro buscado en EMPLEADO.');
    END IF;
  EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
      RAISE_APPLICATION_ERROR(-20001, 'Ya existe un registro con ese valor unico en EMPLEADO.');
    WHEN NO_DATA_FOUND THEN
      RAISE_APPLICATION_ERROR(-20002, 'No existe el registro buscado en EMPLEADO.');
    WHEN e_hijos THEN
      RAISE_APPLICATION_ERROR(-20003, 'No se puede borrar: EMPLEADO tiene registros relacionados.');
    WHEN e_padre THEN
      RAISE_APPLICATION_ERROR(-20005, 'Una referencia no existe: revise las llaves de EMPLEADO.');
    WHEN e_check THEN
      RAISE_APPLICATION_ERROR(-20006, 'Un valor no cumple las reglas de validacion de EMPLEADO.');
    WHEN e_nulo THEN
      RAISE_APPLICATION_ERROR(-20007, 'Falta un dato obligatorio en EMPLEADO.');
  END sp_actualizar;

  PROCEDURE sp_eliminar(
      p_id_empleado IN empleado.id_empleado%TYPE) IS
  BEGIN
    DELETE FROM empleado WHERE id_empleado = p_id_empleado;
    IF SQL%ROWCOUNT = 0 THEN
      RAISE_APPLICATION_ERROR(-20002, 'No existe el registro buscado en EMPLEADO.');
    END IF;
  EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
      RAISE_APPLICATION_ERROR(-20001, 'Ya existe un registro con ese valor unico en EMPLEADO.');
    WHEN NO_DATA_FOUND THEN
      RAISE_APPLICATION_ERROR(-20002, 'No existe el registro buscado en EMPLEADO.');
    WHEN e_hijos THEN
      RAISE_APPLICATION_ERROR(-20003, 'No se puede borrar: EMPLEADO tiene registros relacionados.');
    WHEN e_padre THEN
      RAISE_APPLICATION_ERROR(-20005, 'Una referencia no existe: revise las llaves de EMPLEADO.');
    WHEN e_check THEN
      RAISE_APPLICATION_ERROR(-20006, 'Un valor no cumple las reglas de validacion de EMPLEADO.');
    WHEN e_nulo THEN
      RAISE_APPLICATION_ERROR(-20007, 'Falta un dato obligatorio en EMPLEADO.');
  END sp_eliminar;

  PROCEDURE sp_obtener(
      p_id_empleado IN empleado.id_empleado%TYPE,
      p_cursor OUT SYS_REFCURSOR) IS
  BEGIN
    OPEN p_cursor FOR
      SELECT id_empleado, id_zona, nombre, apellido, correo, rol, usuario, activo
        FROM empleado
       WHERE id_empleado = p_id_empleado;
  END sp_obtener;

  PROCEDURE sp_listar(
      p_cursor OUT SYS_REFCURSOR) IS
  BEGIN
    OPEN p_cursor FOR
      SELECT id_empleado, id_zona, nombre, apellido, correo, rol, usuario, activo
        FROM empleado
       ORDER BY id_empleado;
  END sp_listar;
END pkg_empleado;
/

CREATE OR REPLACE PACKAGE pkg_cliente AS
  PROCEDURE sp_insertar(
      p_id_zona IN cliente.id_zona%TYPE,
      p_id_vendedor IN cliente.id_vendedor%TYPE,
      p_cedula IN cliente.cedula%TYPE,
      p_nombre_comercial IN cliente.nombre_comercial%TYPE,
      p_correo IN cliente.correo%TYPE,
      p_telefono IN cliente.telefono%TYPE,
      p_direccion IN cliente.direccion%TYPE,
      p_limite_credito IN cliente.limite_credito%TYPE,
      p_dias_credito IN cliente.dias_credito%TYPE,
      p_estado IN cliente.estado%TYPE,
      p_id_cliente OUT cliente.id_cliente%TYPE);
  PROCEDURE sp_actualizar(
      p_id_cliente IN cliente.id_cliente%TYPE,
      p_id_zona IN cliente.id_zona%TYPE,
      p_id_vendedor IN cliente.id_vendedor%TYPE,
      p_cedula IN cliente.cedula%TYPE,
      p_nombre_comercial IN cliente.nombre_comercial%TYPE,
      p_correo IN cliente.correo%TYPE,
      p_telefono IN cliente.telefono%TYPE,
      p_direccion IN cliente.direccion%TYPE,
      p_limite_credito IN cliente.limite_credito%TYPE,
      p_dias_credito IN cliente.dias_credito%TYPE,
      p_estado IN cliente.estado%TYPE);
  PROCEDURE sp_eliminar(
      p_id_cliente IN cliente.id_cliente%TYPE);
  PROCEDURE sp_obtener(
      p_id_cliente IN cliente.id_cliente%TYPE,
      p_cursor OUT SYS_REFCURSOR);
  PROCEDURE sp_listar(
      p_cursor OUT SYS_REFCURSOR);
END pkg_cliente;
/

CREATE OR REPLACE PACKAGE BODY pkg_cliente AS
  e_hijos EXCEPTION;
  PRAGMA EXCEPTION_INIT(e_hijos, -2292);
  e_padre EXCEPTION;
  PRAGMA EXCEPTION_INIT(e_padre, -2291);
  e_check EXCEPTION;
  PRAGMA EXCEPTION_INIT(e_check, -2290);
  e_nulo EXCEPTION;
  PRAGMA EXCEPTION_INIT(e_nulo, -1400);

  PROCEDURE sp_insertar(
      p_id_zona IN cliente.id_zona%TYPE,
      p_id_vendedor IN cliente.id_vendedor%TYPE,
      p_cedula IN cliente.cedula%TYPE,
      p_nombre_comercial IN cliente.nombre_comercial%TYPE,
      p_correo IN cliente.correo%TYPE,
      p_telefono IN cliente.telefono%TYPE,
      p_direccion IN cliente.direccion%TYPE,
      p_limite_credito IN cliente.limite_credito%TYPE,
      p_dias_credito IN cliente.dias_credito%TYPE,
      p_estado IN cliente.estado%TYPE,
      p_id_cliente OUT cliente.id_cliente%TYPE) IS
  BEGIN
    IF NVL(fn_rol_empleado(p_id_vendedor), 'X') <> 'VENDEDOR' THEN
      RAISE_APPLICATION_ERROR(-20030, 'El vendedor no existe o no tiene rol VENDEDOR.');
    END IF;
    INSERT INTO cliente (id_cliente, id_zona, id_vendedor, cedula, nombre_comercial, correo, telefono, direccion, limite_credito, dias_credito, estado)
    VALUES (seq_cliente.NEXTVAL, p_id_zona, p_id_vendedor, p_cedula, p_nombre_comercial, p_correo, p_telefono, p_direccion, NVL(p_limite_credito, 0), NVL(p_dias_credito, 15), NVL(p_estado, 'ACTIVO'))
    RETURNING id_cliente INTO p_id_cliente;
  EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
      RAISE_APPLICATION_ERROR(-20001, 'Ya existe un registro con ese valor unico en CLIENTE.');
    WHEN NO_DATA_FOUND THEN
      RAISE_APPLICATION_ERROR(-20002, 'No existe el registro buscado en CLIENTE.');
    WHEN e_hijos THEN
      RAISE_APPLICATION_ERROR(-20003, 'No se puede borrar: CLIENTE tiene registros relacionados.');
    WHEN e_padre THEN
      RAISE_APPLICATION_ERROR(-20005, 'Una referencia no existe: revise las llaves de CLIENTE.');
    WHEN e_check THEN
      RAISE_APPLICATION_ERROR(-20006, 'Un valor no cumple las reglas de validacion de CLIENTE.');
    WHEN e_nulo THEN
      RAISE_APPLICATION_ERROR(-20007, 'Falta un dato obligatorio en CLIENTE.');
  END sp_insertar;

  PROCEDURE sp_actualizar(
      p_id_cliente IN cliente.id_cliente%TYPE,
      p_id_zona IN cliente.id_zona%TYPE,
      p_id_vendedor IN cliente.id_vendedor%TYPE,
      p_cedula IN cliente.cedula%TYPE,
      p_nombre_comercial IN cliente.nombre_comercial%TYPE,
      p_correo IN cliente.correo%TYPE,
      p_telefono IN cliente.telefono%TYPE,
      p_direccion IN cliente.direccion%TYPE,
      p_limite_credito IN cliente.limite_credito%TYPE,
      p_dias_credito IN cliente.dias_credito%TYPE,
      p_estado IN cliente.estado%TYPE) IS
  BEGIN
    IF NVL(fn_rol_empleado(p_id_vendedor), 'X') <> 'VENDEDOR' THEN
      RAISE_APPLICATION_ERROR(-20030, 'El vendedor no existe o no tiene rol VENDEDOR.');
    END IF;
    UPDATE cliente
       SET id_zona = p_id_zona,
           id_vendedor = p_id_vendedor,
           cedula = p_cedula,
           nombre_comercial = p_nombre_comercial,
           correo = p_correo,
           telefono = p_telefono,
           direccion = p_direccion,
           limite_credito = p_limite_credito,
           dias_credito = p_dias_credito,
           estado = p_estado
     WHERE id_cliente = p_id_cliente;
    IF SQL%ROWCOUNT = 0 THEN
      RAISE_APPLICATION_ERROR(-20002, 'No existe el registro buscado en CLIENTE.');
    END IF;
  EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
      RAISE_APPLICATION_ERROR(-20001, 'Ya existe un registro con ese valor unico en CLIENTE.');
    WHEN NO_DATA_FOUND THEN
      RAISE_APPLICATION_ERROR(-20002, 'No existe el registro buscado en CLIENTE.');
    WHEN e_hijos THEN
      RAISE_APPLICATION_ERROR(-20003, 'No se puede borrar: CLIENTE tiene registros relacionados.');
    WHEN e_padre THEN
      RAISE_APPLICATION_ERROR(-20005, 'Una referencia no existe: revise las llaves de CLIENTE.');
    WHEN e_check THEN
      RAISE_APPLICATION_ERROR(-20006, 'Un valor no cumple las reglas de validacion de CLIENTE.');
    WHEN e_nulo THEN
      RAISE_APPLICATION_ERROR(-20007, 'Falta un dato obligatorio en CLIENTE.');
  END sp_actualizar;

  PROCEDURE sp_eliminar(
      p_id_cliente IN cliente.id_cliente%TYPE) IS
  BEGIN
    DELETE FROM cliente WHERE id_cliente = p_id_cliente;
    IF SQL%ROWCOUNT = 0 THEN
      RAISE_APPLICATION_ERROR(-20002, 'No existe el registro buscado en CLIENTE.');
    END IF;
  EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
      RAISE_APPLICATION_ERROR(-20001, 'Ya existe un registro con ese valor unico en CLIENTE.');
    WHEN NO_DATA_FOUND THEN
      RAISE_APPLICATION_ERROR(-20002, 'No existe el registro buscado en CLIENTE.');
    WHEN e_hijos THEN
      RAISE_APPLICATION_ERROR(-20003, 'No se puede borrar: CLIENTE tiene registros relacionados.');
    WHEN e_padre THEN
      RAISE_APPLICATION_ERROR(-20005, 'Una referencia no existe: revise las llaves de CLIENTE.');
    WHEN e_check THEN
      RAISE_APPLICATION_ERROR(-20006, 'Un valor no cumple las reglas de validacion de CLIENTE.');
    WHEN e_nulo THEN
      RAISE_APPLICATION_ERROR(-20007, 'Falta un dato obligatorio en CLIENTE.');
  END sp_eliminar;

  PROCEDURE sp_obtener(
      p_id_cliente IN cliente.id_cliente%TYPE,
      p_cursor OUT SYS_REFCURSOR) IS
  BEGIN
    OPEN p_cursor FOR
      SELECT id_cliente, id_zona, id_vendedor, cedula, nombre_comercial, correo, telefono, direccion, limite_credito, dias_credito, estado
        FROM cliente
       WHERE id_cliente = p_id_cliente;
  END sp_obtener;

  PROCEDURE sp_listar(
      p_cursor OUT SYS_REFCURSOR) IS
  BEGIN
    OPEN p_cursor FOR
      SELECT id_cliente, id_zona, id_vendedor, cedula, nombre_comercial, correo, telefono, direccion, limite_credito, dias_credito, estado
        FROM cliente
       ORDER BY id_cliente;
  END sp_listar;
END pkg_cliente;
/

CREATE OR REPLACE PACKAGE pkg_categoria AS
  PROCEDURE sp_insertar(
      p_nombre_categoria IN categoria.nombre_categoria%TYPE,
      p_id_categoria OUT categoria.id_categoria%TYPE);
  PROCEDURE sp_actualizar(
      p_id_categoria IN categoria.id_categoria%TYPE,
      p_nombre_categoria IN categoria.nombre_categoria%TYPE);
  PROCEDURE sp_eliminar(
      p_id_categoria IN categoria.id_categoria%TYPE);
  PROCEDURE sp_obtener(
      p_id_categoria IN categoria.id_categoria%TYPE,
      p_cursor OUT SYS_REFCURSOR);
  PROCEDURE sp_listar(
      p_cursor OUT SYS_REFCURSOR);
END pkg_categoria;
/

CREATE OR REPLACE PACKAGE BODY pkg_categoria AS
  e_hijos EXCEPTION;
  PRAGMA EXCEPTION_INIT(e_hijos, -2292);
  e_padre EXCEPTION;
  PRAGMA EXCEPTION_INIT(e_padre, -2291);
  e_check EXCEPTION;
  PRAGMA EXCEPTION_INIT(e_check, -2290);
  e_nulo EXCEPTION;
  PRAGMA EXCEPTION_INIT(e_nulo, -1400);

  PROCEDURE sp_insertar(
      p_nombre_categoria IN categoria.nombre_categoria%TYPE,
      p_id_categoria OUT categoria.id_categoria%TYPE) IS
  BEGIN
    INSERT INTO categoria (id_categoria, nombre_categoria)
    VALUES (seq_categoria.NEXTVAL, p_nombre_categoria)
    RETURNING id_categoria INTO p_id_categoria;
  EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
      RAISE_APPLICATION_ERROR(-20001, 'Ya existe un registro con ese valor unico en CATEGORIA.');
    WHEN NO_DATA_FOUND THEN
      RAISE_APPLICATION_ERROR(-20002, 'No existe el registro buscado en CATEGORIA.');
    WHEN e_hijos THEN
      RAISE_APPLICATION_ERROR(-20003, 'No se puede borrar: CATEGORIA tiene registros relacionados.');
    WHEN e_padre THEN
      RAISE_APPLICATION_ERROR(-20005, 'Una referencia no existe: revise las llaves de CATEGORIA.');
    WHEN e_check THEN
      RAISE_APPLICATION_ERROR(-20006, 'Un valor no cumple las reglas de validacion de CATEGORIA.');
    WHEN e_nulo THEN
      RAISE_APPLICATION_ERROR(-20007, 'Falta un dato obligatorio en CATEGORIA.');
  END sp_insertar;

  PROCEDURE sp_actualizar(
      p_id_categoria IN categoria.id_categoria%TYPE,
      p_nombre_categoria IN categoria.nombre_categoria%TYPE) IS
  BEGIN
    UPDATE categoria
       SET nombre_categoria = p_nombre_categoria
     WHERE id_categoria = p_id_categoria;
    IF SQL%ROWCOUNT = 0 THEN
      RAISE_APPLICATION_ERROR(-20002, 'No existe el registro buscado en CATEGORIA.');
    END IF;
  EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
      RAISE_APPLICATION_ERROR(-20001, 'Ya existe un registro con ese valor unico en CATEGORIA.');
    WHEN NO_DATA_FOUND THEN
      RAISE_APPLICATION_ERROR(-20002, 'No existe el registro buscado en CATEGORIA.');
    WHEN e_hijos THEN
      RAISE_APPLICATION_ERROR(-20003, 'No se puede borrar: CATEGORIA tiene registros relacionados.');
    WHEN e_padre THEN
      RAISE_APPLICATION_ERROR(-20005, 'Una referencia no existe: revise las llaves de CATEGORIA.');
    WHEN e_check THEN
      RAISE_APPLICATION_ERROR(-20006, 'Un valor no cumple las reglas de validacion de CATEGORIA.');
    WHEN e_nulo THEN
      RAISE_APPLICATION_ERROR(-20007, 'Falta un dato obligatorio en CATEGORIA.');
  END sp_actualizar;

  PROCEDURE sp_eliminar(
      p_id_categoria IN categoria.id_categoria%TYPE) IS
  BEGIN
    DELETE FROM categoria WHERE id_categoria = p_id_categoria;
    IF SQL%ROWCOUNT = 0 THEN
      RAISE_APPLICATION_ERROR(-20002, 'No existe el registro buscado en CATEGORIA.');
    END IF;
  EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
      RAISE_APPLICATION_ERROR(-20001, 'Ya existe un registro con ese valor unico en CATEGORIA.');
    WHEN NO_DATA_FOUND THEN
      RAISE_APPLICATION_ERROR(-20002, 'No existe el registro buscado en CATEGORIA.');
    WHEN e_hijos THEN
      RAISE_APPLICATION_ERROR(-20003, 'No se puede borrar: CATEGORIA tiene registros relacionados.');
    WHEN e_padre THEN
      RAISE_APPLICATION_ERROR(-20005, 'Una referencia no existe: revise las llaves de CATEGORIA.');
    WHEN e_check THEN
      RAISE_APPLICATION_ERROR(-20006, 'Un valor no cumple las reglas de validacion de CATEGORIA.');
    WHEN e_nulo THEN
      RAISE_APPLICATION_ERROR(-20007, 'Falta un dato obligatorio en CATEGORIA.');
  END sp_eliminar;

  PROCEDURE sp_obtener(
      p_id_categoria IN categoria.id_categoria%TYPE,
      p_cursor OUT SYS_REFCURSOR) IS
  BEGIN
    OPEN p_cursor FOR
      SELECT id_categoria, nombre_categoria
        FROM categoria
       WHERE id_categoria = p_id_categoria;
  END sp_obtener;

  PROCEDURE sp_listar(
      p_cursor OUT SYS_REFCURSOR) IS
  BEGIN
    OPEN p_cursor FOR
      SELECT id_categoria, nombre_categoria
        FROM categoria
       ORDER BY id_categoria;
  END sp_listar;
END pkg_categoria;
/

CREATE OR REPLACE PACKAGE pkg_producto AS
  PROCEDURE sp_insertar(
      p_id_categoria IN producto.id_categoria%TYPE,
      p_codigo IN producto.codigo%TYPE,
      p_nombre_producto IN producto.nombre_producto%TYPE,
      p_precio_unitario IN producto.precio_unitario%TYPE,
      p_stock_actual IN producto.stock_actual%TYPE,
      p_activo IN producto.activo%TYPE,
      p_id_producto OUT producto.id_producto%TYPE);
  PROCEDURE sp_actualizar(
      p_id_producto IN producto.id_producto%TYPE,
      p_id_categoria IN producto.id_categoria%TYPE,
      p_codigo IN producto.codigo%TYPE,
      p_nombre_producto IN producto.nombre_producto%TYPE,
      p_precio_unitario IN producto.precio_unitario%TYPE,
      p_activo IN producto.activo%TYPE);
  PROCEDURE sp_eliminar(
      p_id_producto IN producto.id_producto%TYPE);
  PROCEDURE sp_obtener(
      p_id_producto IN producto.id_producto%TYPE,
      p_cursor OUT SYS_REFCURSOR);
  PROCEDURE sp_listar(
      p_cursor OUT SYS_REFCURSOR);
END pkg_producto;
/

CREATE OR REPLACE PACKAGE BODY pkg_producto AS
  e_hijos EXCEPTION;
  PRAGMA EXCEPTION_INIT(e_hijos, -2292);
  e_padre EXCEPTION;
  PRAGMA EXCEPTION_INIT(e_padre, -2291);
  e_check EXCEPTION;
  PRAGMA EXCEPTION_INIT(e_check, -2290);
  e_nulo EXCEPTION;
  PRAGMA EXCEPTION_INIT(e_nulo, -1400);

  PROCEDURE sp_insertar(
      p_id_categoria IN producto.id_categoria%TYPE,
      p_codigo IN producto.codigo%TYPE,
      p_nombre_producto IN producto.nombre_producto%TYPE,
      p_precio_unitario IN producto.precio_unitario%TYPE,
      p_stock_actual IN producto.stock_actual%TYPE,
      p_activo IN producto.activo%TYPE,
      p_id_producto OUT producto.id_producto%TYPE) IS
  BEGIN
    INSERT INTO producto (id_producto, id_categoria, codigo, nombre_producto, precio_unitario, stock_actual, activo)
    VALUES (seq_producto.NEXTVAL, p_id_categoria, p_codigo, p_nombre_producto, p_precio_unitario, NVL(p_stock_actual, 0), NVL(p_activo, 1))
    RETURNING id_producto INTO p_id_producto;
  EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
      RAISE_APPLICATION_ERROR(-20001, 'Ya existe un registro con ese valor unico en PRODUCTO.');
    WHEN NO_DATA_FOUND THEN
      RAISE_APPLICATION_ERROR(-20002, 'No existe el registro buscado en PRODUCTO.');
    WHEN e_hijos THEN
      RAISE_APPLICATION_ERROR(-20003, 'No se puede borrar: PRODUCTO tiene registros relacionados.');
    WHEN e_padre THEN
      RAISE_APPLICATION_ERROR(-20005, 'Una referencia no existe: revise las llaves de PRODUCTO.');
    WHEN e_check THEN
      RAISE_APPLICATION_ERROR(-20006, 'Un valor no cumple las reglas de validacion de PRODUCTO.');
    WHEN e_nulo THEN
      RAISE_APPLICATION_ERROR(-20007, 'Falta un dato obligatorio en PRODUCTO.');
  END sp_insertar;

  PROCEDURE sp_actualizar(
      p_id_producto IN producto.id_producto%TYPE,
      p_id_categoria IN producto.id_categoria%TYPE,
      p_codigo IN producto.codigo%TYPE,
      p_nombre_producto IN producto.nombre_producto%TYPE,
      p_precio_unitario IN producto.precio_unitario%TYPE,
      p_activo IN producto.activo%TYPE) IS
  BEGIN
    UPDATE producto
       SET id_categoria = p_id_categoria,
           codigo = p_codigo,
           nombre_producto = p_nombre_producto,
           precio_unitario = p_precio_unitario,
           activo = p_activo
     WHERE id_producto = p_id_producto;
    IF SQL%ROWCOUNT = 0 THEN
      RAISE_APPLICATION_ERROR(-20002, 'No existe el registro buscado en PRODUCTO.');
    END IF;
  EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
      RAISE_APPLICATION_ERROR(-20001, 'Ya existe un registro con ese valor unico en PRODUCTO.');
    WHEN NO_DATA_FOUND THEN
      RAISE_APPLICATION_ERROR(-20002, 'No existe el registro buscado en PRODUCTO.');
    WHEN e_hijos THEN
      RAISE_APPLICATION_ERROR(-20003, 'No se puede borrar: PRODUCTO tiene registros relacionados.');
    WHEN e_padre THEN
      RAISE_APPLICATION_ERROR(-20005, 'Una referencia no existe: revise las llaves de PRODUCTO.');
    WHEN e_check THEN
      RAISE_APPLICATION_ERROR(-20006, 'Un valor no cumple las reglas de validacion de PRODUCTO.');
    WHEN e_nulo THEN
      RAISE_APPLICATION_ERROR(-20007, 'Falta un dato obligatorio en PRODUCTO.');
  END sp_actualizar;

  PROCEDURE sp_eliminar(
      p_id_producto IN producto.id_producto%TYPE) IS
  BEGIN
    DELETE FROM producto WHERE id_producto = p_id_producto;
    IF SQL%ROWCOUNT = 0 THEN
      RAISE_APPLICATION_ERROR(-20002, 'No existe el registro buscado en PRODUCTO.');
    END IF;
  EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
      RAISE_APPLICATION_ERROR(-20001, 'Ya existe un registro con ese valor unico en PRODUCTO.');
    WHEN NO_DATA_FOUND THEN
      RAISE_APPLICATION_ERROR(-20002, 'No existe el registro buscado en PRODUCTO.');
    WHEN e_hijos THEN
      RAISE_APPLICATION_ERROR(-20003, 'No se puede borrar: PRODUCTO tiene registros relacionados.');
    WHEN e_padre THEN
      RAISE_APPLICATION_ERROR(-20005, 'Una referencia no existe: revise las llaves de PRODUCTO.');
    WHEN e_check THEN
      RAISE_APPLICATION_ERROR(-20006, 'Un valor no cumple las reglas de validacion de PRODUCTO.');
    WHEN e_nulo THEN
      RAISE_APPLICATION_ERROR(-20007, 'Falta un dato obligatorio en PRODUCTO.');
  END sp_eliminar;

  PROCEDURE sp_obtener(
      p_id_producto IN producto.id_producto%TYPE,
      p_cursor OUT SYS_REFCURSOR) IS
  BEGIN
    OPEN p_cursor FOR
      SELECT id_producto, id_categoria, codigo, nombre_producto, precio_unitario, stock_actual, activo
        FROM producto
       WHERE id_producto = p_id_producto;
  END sp_obtener;

  PROCEDURE sp_listar(
      p_cursor OUT SYS_REFCURSOR) IS
  BEGIN
    OPEN p_cursor FOR
      SELECT id_producto, id_categoria, codigo, nombre_producto, precio_unitario, stock_actual, activo
        FROM producto
       ORDER BY id_producto;
  END sp_listar;
END pkg_producto;
/

CREATE OR REPLACE PACKAGE pkg_metodo_pago AS
  PROCEDURE sp_insertar(
      p_nombre_metodo IN metodo_pago.nombre_metodo%TYPE,
      p_id_metodo_pago OUT metodo_pago.id_metodo_pago%TYPE);
  PROCEDURE sp_actualizar(
      p_id_metodo_pago IN metodo_pago.id_metodo_pago%TYPE,
      p_nombre_metodo IN metodo_pago.nombre_metodo%TYPE);
  PROCEDURE sp_eliminar(
      p_id_metodo_pago IN metodo_pago.id_metodo_pago%TYPE);
  PROCEDURE sp_obtener(
      p_id_metodo_pago IN metodo_pago.id_metodo_pago%TYPE,
      p_cursor OUT SYS_REFCURSOR);
  PROCEDURE sp_listar(
      p_cursor OUT SYS_REFCURSOR);
END pkg_metodo_pago;
/

CREATE OR REPLACE PACKAGE BODY pkg_metodo_pago AS
  e_hijos EXCEPTION;
  PRAGMA EXCEPTION_INIT(e_hijos, -2292);
  e_padre EXCEPTION;
  PRAGMA EXCEPTION_INIT(e_padre, -2291);
  e_check EXCEPTION;
  PRAGMA EXCEPTION_INIT(e_check, -2290);
  e_nulo EXCEPTION;
  PRAGMA EXCEPTION_INIT(e_nulo, -1400);

  PROCEDURE sp_insertar(
      p_nombre_metodo IN metodo_pago.nombre_metodo%TYPE,
      p_id_metodo_pago OUT metodo_pago.id_metodo_pago%TYPE) IS
  BEGIN
    INSERT INTO metodo_pago (id_metodo_pago, nombre_metodo)
    VALUES (seq_metodo_pago.NEXTVAL, p_nombre_metodo)
    RETURNING id_metodo_pago INTO p_id_metodo_pago;
  EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
      RAISE_APPLICATION_ERROR(-20001, 'Ya existe un registro con ese valor unico en METODO_PAGO.');
    WHEN NO_DATA_FOUND THEN
      RAISE_APPLICATION_ERROR(-20002, 'No existe el registro buscado en METODO_PAGO.');
    WHEN e_hijos THEN
      RAISE_APPLICATION_ERROR(-20003, 'No se puede borrar: METODO_PAGO tiene registros relacionados.');
    WHEN e_padre THEN
      RAISE_APPLICATION_ERROR(-20005, 'Una referencia no existe: revise las llaves de METODO_PAGO.');
    WHEN e_check THEN
      RAISE_APPLICATION_ERROR(-20006, 'Un valor no cumple las reglas de validacion de METODO_PAGO.');
    WHEN e_nulo THEN
      RAISE_APPLICATION_ERROR(-20007, 'Falta un dato obligatorio en METODO_PAGO.');
  END sp_insertar;

  PROCEDURE sp_actualizar(
      p_id_metodo_pago IN metodo_pago.id_metodo_pago%TYPE,
      p_nombre_metodo IN metodo_pago.nombre_metodo%TYPE) IS
  BEGIN
    UPDATE metodo_pago
       SET nombre_metodo = p_nombre_metodo
     WHERE id_metodo_pago = p_id_metodo_pago;
    IF SQL%ROWCOUNT = 0 THEN
      RAISE_APPLICATION_ERROR(-20002, 'No existe el registro buscado en METODO_PAGO.');
    END IF;
  EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
      RAISE_APPLICATION_ERROR(-20001, 'Ya existe un registro con ese valor unico en METODO_PAGO.');
    WHEN NO_DATA_FOUND THEN
      RAISE_APPLICATION_ERROR(-20002, 'No existe el registro buscado en METODO_PAGO.');
    WHEN e_hijos THEN
      RAISE_APPLICATION_ERROR(-20003, 'No se puede borrar: METODO_PAGO tiene registros relacionados.');
    WHEN e_padre THEN
      RAISE_APPLICATION_ERROR(-20005, 'Una referencia no existe: revise las llaves de METODO_PAGO.');
    WHEN e_check THEN
      RAISE_APPLICATION_ERROR(-20006, 'Un valor no cumple las reglas de validacion de METODO_PAGO.');
    WHEN e_nulo THEN
      RAISE_APPLICATION_ERROR(-20007, 'Falta un dato obligatorio en METODO_PAGO.');
  END sp_actualizar;

  PROCEDURE sp_eliminar(
      p_id_metodo_pago IN metodo_pago.id_metodo_pago%TYPE) IS
  BEGIN
    DELETE FROM metodo_pago WHERE id_metodo_pago = p_id_metodo_pago;
    IF SQL%ROWCOUNT = 0 THEN
      RAISE_APPLICATION_ERROR(-20002, 'No existe el registro buscado en METODO_PAGO.');
    END IF;
  EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
      RAISE_APPLICATION_ERROR(-20001, 'Ya existe un registro con ese valor unico en METODO_PAGO.');
    WHEN NO_DATA_FOUND THEN
      RAISE_APPLICATION_ERROR(-20002, 'No existe el registro buscado en METODO_PAGO.');
    WHEN e_hijos THEN
      RAISE_APPLICATION_ERROR(-20003, 'No se puede borrar: METODO_PAGO tiene registros relacionados.');
    WHEN e_padre THEN
      RAISE_APPLICATION_ERROR(-20005, 'Una referencia no existe: revise las llaves de METODO_PAGO.');
    WHEN e_check THEN
      RAISE_APPLICATION_ERROR(-20006, 'Un valor no cumple las reglas de validacion de METODO_PAGO.');
    WHEN e_nulo THEN
      RAISE_APPLICATION_ERROR(-20007, 'Falta un dato obligatorio en METODO_PAGO.');
  END sp_eliminar;

  PROCEDURE sp_obtener(
      p_id_metodo_pago IN metodo_pago.id_metodo_pago%TYPE,
      p_cursor OUT SYS_REFCURSOR) IS
  BEGIN
    OPEN p_cursor FOR
      SELECT id_metodo_pago, nombre_metodo
        FROM metodo_pago
       WHERE id_metodo_pago = p_id_metodo_pago;
  END sp_obtener;

  PROCEDURE sp_listar(
      p_cursor OUT SYS_REFCURSOR) IS
  BEGIN
    OPEN p_cursor FOR
      SELECT id_metodo_pago, nombre_metodo
        FROM metodo_pago
       ORDER BY id_metodo_pago;
  END sp_listar;
END pkg_metodo_pago;
/

CREATE OR REPLACE PACKAGE pkg_factura AS
  PROCEDURE sp_insertar(
      p_id_cliente IN factura.id_cliente%TYPE,
      p_id_empleado IN factura.id_empleado%TYPE,
      p_fecha_emision IN factura.fecha_emision%TYPE,
      p_id_factura OUT factura.id_factura%TYPE);
  PROCEDURE sp_actualizar(
      p_id_factura IN factura.id_factura%TYPE,
      p_id_empleado IN factura.id_empleado%TYPE,
      p_fecha_vencimiento IN factura.fecha_vencimiento%TYPE);
  PROCEDURE sp_eliminar(
      p_id_factura IN factura.id_factura%TYPE);
  PROCEDURE sp_obtener(
      p_id_factura IN factura.id_factura%TYPE,
      p_cursor OUT SYS_REFCURSOR);
  PROCEDURE sp_listar(
      p_cursor OUT SYS_REFCURSOR);
END pkg_factura;
/

CREATE OR REPLACE PACKAGE BODY pkg_factura AS
  e_hijos EXCEPTION;
  PRAGMA EXCEPTION_INIT(e_hijos, -2292);
  e_padre EXCEPTION;
  PRAGMA EXCEPTION_INIT(e_padre, -2291);
  e_check EXCEPTION;
  PRAGMA EXCEPTION_INIT(e_check, -2290);
  e_nulo EXCEPTION;
  PRAGMA EXCEPTION_INIT(e_nulo, -1400);

  PROCEDURE sp_insertar(
      p_id_cliente IN factura.id_cliente%TYPE,
      p_id_empleado IN factura.id_empleado%TYPE,
      p_fecha_emision IN factura.fecha_emision%TYPE,
      p_id_factura OUT factura.id_factura%TYPE) IS
  BEGIN
    IF NVL(fn_estado_cliente(p_id_cliente), 'X') <> 'ACTIVO' THEN
      RAISE_APPLICATION_ERROR(-20040, 'Solo se puede facturar a clientes ACTIVOS.');
    END IF;
    INSERT INTO factura (id_factura, id_cliente, id_empleado, numero_factura, fecha_emision, fecha_vencimiento, monto_total, saldo_pendiente, estado)
    VALUES (seq_factura.NEXTVAL, p_id_cliente, p_id_empleado, fn_siguiente_numero_factura, NVL(p_fecha_emision, TRUNC(SYSDATE)), fn_fecha_vencimiento(p_id_cliente, NVL(p_fecha_emision, TRUNC(SYSDATE))), 0, 0, 'PENDIENTE')
    RETURNING id_factura INTO p_id_factura;
  EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
      RAISE_APPLICATION_ERROR(-20001, 'Ya existe un registro con ese valor unico en FACTURA.');
    WHEN NO_DATA_FOUND THEN
      RAISE_APPLICATION_ERROR(-20002, 'No existe el registro buscado en FACTURA.');
    WHEN e_hijos THEN
      RAISE_APPLICATION_ERROR(-20003, 'No se puede borrar: FACTURA tiene registros relacionados.');
    WHEN e_padre THEN
      RAISE_APPLICATION_ERROR(-20005, 'Una referencia no existe: revise las llaves de FACTURA.');
    WHEN e_check THEN
      RAISE_APPLICATION_ERROR(-20006, 'Un valor no cumple las reglas de validacion de FACTURA.');
    WHEN e_nulo THEN
      RAISE_APPLICATION_ERROR(-20007, 'Falta un dato obligatorio en FACTURA.');
  END sp_insertar;

  PROCEDURE sp_actualizar(
      p_id_factura IN factura.id_factura%TYPE,
      p_id_empleado IN factura.id_empleado%TYPE,
      p_fecha_vencimiento IN factura.fecha_vencimiento%TYPE) IS
  BEGIN
    IF NVL(fn_estado_factura(p_id_factura), 'X') = 'ANULADA' THEN
      RAISE_APPLICATION_ERROR(-20041, 'Una factura anulada no se puede modificar.');
    END IF;
    UPDATE factura
       SET id_empleado = p_id_empleado,
           fecha_vencimiento = p_fecha_vencimiento
     WHERE id_factura = p_id_factura;
    IF SQL%ROWCOUNT = 0 THEN
      RAISE_APPLICATION_ERROR(-20002, 'No existe el registro buscado en FACTURA.');
    END IF;
  EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
      RAISE_APPLICATION_ERROR(-20001, 'Ya existe un registro con ese valor unico en FACTURA.');
    WHEN NO_DATA_FOUND THEN
      RAISE_APPLICATION_ERROR(-20002, 'No existe el registro buscado en FACTURA.');
    WHEN e_hijos THEN
      RAISE_APPLICATION_ERROR(-20003, 'No se puede borrar: FACTURA tiene registros relacionados.');
    WHEN e_padre THEN
      RAISE_APPLICATION_ERROR(-20005, 'Una referencia no existe: revise las llaves de FACTURA.');
    WHEN e_check THEN
      RAISE_APPLICATION_ERROR(-20006, 'Un valor no cumple las reglas de validacion de FACTURA.');
    WHEN e_nulo THEN
      RAISE_APPLICATION_ERROR(-20007, 'Falta un dato obligatorio en FACTURA.');
  END sp_actualizar;

  PROCEDURE sp_eliminar(
      p_id_factura IN factura.id_factura%TYPE) IS
  BEGIN
    DELETE FROM factura WHERE id_factura = p_id_factura;
    IF SQL%ROWCOUNT = 0 THEN
      RAISE_APPLICATION_ERROR(-20002, 'No existe el registro buscado en FACTURA.');
    END IF;
  EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
      RAISE_APPLICATION_ERROR(-20001, 'Ya existe un registro con ese valor unico en FACTURA.');
    WHEN NO_DATA_FOUND THEN
      RAISE_APPLICATION_ERROR(-20002, 'No existe el registro buscado en FACTURA.');
    WHEN e_hijos THEN
      RAISE_APPLICATION_ERROR(-20003, 'No se puede borrar: FACTURA tiene registros relacionados.');
    WHEN e_padre THEN
      RAISE_APPLICATION_ERROR(-20005, 'Una referencia no existe: revise las llaves de FACTURA.');
    WHEN e_check THEN
      RAISE_APPLICATION_ERROR(-20006, 'Un valor no cumple las reglas de validacion de FACTURA.');
    WHEN e_nulo THEN
      RAISE_APPLICATION_ERROR(-20007, 'Falta un dato obligatorio en FACTURA.');
  END sp_eliminar;

  PROCEDURE sp_obtener(
      p_id_factura IN factura.id_factura%TYPE,
      p_cursor OUT SYS_REFCURSOR) IS
  BEGIN
    OPEN p_cursor FOR
      SELECT id_factura, id_cliente, id_empleado, numero_factura, fecha_emision, fecha_vencimiento, monto_total, saldo_pendiente, estado
        FROM factura
       WHERE id_factura = p_id_factura;
  END sp_obtener;

  PROCEDURE sp_listar(
      p_cursor OUT SYS_REFCURSOR) IS
  BEGIN
    OPEN p_cursor FOR
      SELECT id_factura, id_cliente, id_empleado, numero_factura, fecha_emision, fecha_vencimiento, monto_total, saldo_pendiente, estado
        FROM factura
       ORDER BY id_factura;
  END sp_listar;
END pkg_factura;
/

CREATE OR REPLACE PACKAGE pkg_detalle_factura AS
  PROCEDURE sp_insertar(
      p_id_factura IN detalle_factura.id_factura%TYPE,
      p_id_producto IN detalle_factura.id_producto%TYPE,
      p_cantidad IN detalle_factura.cantidad%TYPE,
      p_precio_unitario IN detalle_factura.precio_unitario%TYPE);
  PROCEDURE sp_actualizar(
      p_id_factura IN detalle_factura.id_factura%TYPE,
      p_id_producto IN detalle_factura.id_producto%TYPE,
      p_cantidad IN detalle_factura.cantidad%TYPE,
      p_precio_unitario IN detalle_factura.precio_unitario%TYPE);
  PROCEDURE sp_eliminar(
      p_id_factura IN detalle_factura.id_factura%TYPE,
      p_id_producto IN detalle_factura.id_producto%TYPE);
  PROCEDURE sp_obtener(
      p_id_factura IN detalle_factura.id_factura%TYPE,
      p_id_producto IN detalle_factura.id_producto%TYPE,
      p_cursor OUT SYS_REFCURSOR);
  PROCEDURE sp_listar(
      p_cursor OUT SYS_REFCURSOR);
END pkg_detalle_factura;
/

CREATE OR REPLACE PACKAGE BODY pkg_detalle_factura AS
  e_hijos EXCEPTION;
  PRAGMA EXCEPTION_INIT(e_hijos, -2292);
  e_padre EXCEPTION;
  PRAGMA EXCEPTION_INIT(e_padre, -2291);
  e_check EXCEPTION;
  PRAGMA EXCEPTION_INIT(e_check, -2290);
  e_nulo EXCEPTION;
  PRAGMA EXCEPTION_INIT(e_nulo, -1400);

  PROCEDURE sp_insertar(
      p_id_factura IN detalle_factura.id_factura%TYPE,
      p_id_producto IN detalle_factura.id_producto%TYPE,
      p_cantidad IN detalle_factura.cantidad%TYPE,
      p_precio_unitario IN detalle_factura.precio_unitario%TYPE) IS
  BEGIN
    IF NVL(fn_estado_factura(p_id_factura), 'X') <> 'PENDIENTE' THEN
      RAISE_APPLICATION_ERROR(-20050, 'Solo se puede agregar detalle a facturas PENDIENTES.');
    END IF;
    IF fn_stock_producto(p_id_producto) < p_cantidad THEN
      RAISE_APPLICATION_ERROR(-20051, 'No hay existencias suficientes del producto.');
    END IF;
    INSERT INTO detalle_factura (id_factura, id_producto, cantidad, precio_unitario)
    VALUES (p_id_factura, p_id_producto, p_cantidad, NVL(p_precio_unitario, fn_precio_producto(p_id_producto)));
    sp_recalcular_factura(p_id_factura);
  EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
      RAISE_APPLICATION_ERROR(-20001, 'Ya existe un registro con ese valor unico en DETALLE_FACTURA.');
    WHEN NO_DATA_FOUND THEN
      RAISE_APPLICATION_ERROR(-20002, 'No existe el registro buscado en DETALLE_FACTURA.');
    WHEN e_hijos THEN
      RAISE_APPLICATION_ERROR(-20003, 'No se puede borrar: DETALLE_FACTURA tiene registros relacionados.');
    WHEN e_padre THEN
      RAISE_APPLICATION_ERROR(-20005, 'Una referencia no existe: revise las llaves de DETALLE_FACTURA.');
    WHEN e_check THEN
      RAISE_APPLICATION_ERROR(-20006, 'Un valor no cumple las reglas de validacion de DETALLE_FACTURA.');
    WHEN e_nulo THEN
      RAISE_APPLICATION_ERROR(-20007, 'Falta un dato obligatorio en DETALLE_FACTURA.');
  END sp_insertar;

  PROCEDURE sp_actualizar(
      p_id_factura IN detalle_factura.id_factura%TYPE,
      p_id_producto IN detalle_factura.id_producto%TYPE,
      p_cantidad IN detalle_factura.cantidad%TYPE,
      p_precio_unitario IN detalle_factura.precio_unitario%TYPE) IS
    v_cantidad_actual detalle_factura.cantidad%TYPE;
  BEGIN
    IF NVL(fn_estado_factura(p_id_factura), 'X') <> 'PENDIENTE' THEN
      RAISE_APPLICATION_ERROR(-20050, 'Solo se puede modificar el detalle de facturas PENDIENTES.');
    END IF;
    SELECT cantidad INTO v_cantidad_actual
      FROM detalle_factura
     WHERE id_factura = p_id_factura AND id_producto = p_id_producto;
    IF p_cantidad > v_cantidad_actual
       AND fn_stock_producto(p_id_producto) < p_cantidad - v_cantidad_actual THEN
      RAISE_APPLICATION_ERROR(-20051, 'No hay existencias suficientes del producto.');
    END IF;
    UPDATE detalle_factura
       SET cantidad = p_cantidad,
           precio_unitario = p_precio_unitario
     WHERE id_factura = p_id_factura AND id_producto = p_id_producto;
    IF SQL%ROWCOUNT = 0 THEN
      RAISE_APPLICATION_ERROR(-20002, 'No existe el registro buscado en DETALLE_FACTURA.');
    END IF;
    sp_recalcular_factura(p_id_factura);
  EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
      RAISE_APPLICATION_ERROR(-20001, 'Ya existe un registro con ese valor unico en DETALLE_FACTURA.');
    WHEN NO_DATA_FOUND THEN
      RAISE_APPLICATION_ERROR(-20002, 'No existe el registro buscado en DETALLE_FACTURA.');
    WHEN e_hijos THEN
      RAISE_APPLICATION_ERROR(-20003, 'No se puede borrar: DETALLE_FACTURA tiene registros relacionados.');
    WHEN e_padre THEN
      RAISE_APPLICATION_ERROR(-20005, 'Una referencia no existe: revise las llaves de DETALLE_FACTURA.');
    WHEN e_check THEN
      RAISE_APPLICATION_ERROR(-20006, 'Un valor no cumple las reglas de validacion de DETALLE_FACTURA.');
    WHEN e_nulo THEN
      RAISE_APPLICATION_ERROR(-20007, 'Falta un dato obligatorio en DETALLE_FACTURA.');
  END sp_actualizar;

  PROCEDURE sp_eliminar(
      p_id_factura IN detalle_factura.id_factura%TYPE,
      p_id_producto IN detalle_factura.id_producto%TYPE) IS
  BEGIN
    IF NVL(fn_estado_factura(p_id_factura), 'X') <> 'PENDIENTE' THEN
      RAISE_APPLICATION_ERROR(-20050, 'Solo se puede quitar detalle de facturas PENDIENTES.');
    END IF;
    DELETE FROM detalle_factura WHERE id_factura = p_id_factura AND id_producto = p_id_producto;
    IF SQL%ROWCOUNT = 0 THEN
      RAISE_APPLICATION_ERROR(-20002, 'No existe el registro buscado en DETALLE_FACTURA.');
    END IF;
    sp_recalcular_factura(p_id_factura);
  EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
      RAISE_APPLICATION_ERROR(-20001, 'Ya existe un registro con ese valor unico en DETALLE_FACTURA.');
    WHEN NO_DATA_FOUND THEN
      RAISE_APPLICATION_ERROR(-20002, 'No existe el registro buscado en DETALLE_FACTURA.');
    WHEN e_hijos THEN
      RAISE_APPLICATION_ERROR(-20003, 'No se puede borrar: DETALLE_FACTURA tiene registros relacionados.');
    WHEN e_padre THEN
      RAISE_APPLICATION_ERROR(-20005, 'Una referencia no existe: revise las llaves de DETALLE_FACTURA.');
    WHEN e_check THEN
      RAISE_APPLICATION_ERROR(-20006, 'Un valor no cumple las reglas de validacion de DETALLE_FACTURA.');
    WHEN e_nulo THEN
      RAISE_APPLICATION_ERROR(-20007, 'Falta un dato obligatorio en DETALLE_FACTURA.');
  END sp_eliminar;

  PROCEDURE sp_obtener(
      p_id_factura IN detalle_factura.id_factura%TYPE,
      p_id_producto IN detalle_factura.id_producto%TYPE,
      p_cursor OUT SYS_REFCURSOR) IS
  BEGIN
    OPEN p_cursor FOR
      SELECT id_factura, id_producto, cantidad, precio_unitario
        FROM detalle_factura
       WHERE id_factura = p_id_factura AND id_producto = p_id_producto;
  END sp_obtener;

  PROCEDURE sp_listar(
      p_cursor OUT SYS_REFCURSOR) IS
  BEGIN
    OPEN p_cursor FOR
      SELECT id_factura, id_producto, cantidad, precio_unitario
        FROM detalle_factura
       ORDER BY id_factura, id_producto;
  END sp_listar;
END pkg_detalle_factura;
/

CREATE OR REPLACE PACKAGE pkg_nota_credito AS
  PROCEDURE sp_insertar(
      p_id_factura IN nota_credito.id_factura%TYPE,
      p_fecha_nota IN nota_credito.fecha_nota%TYPE,
      p_monto IN nota_credito.monto%TYPE,
      p_motivo IN nota_credito.motivo%TYPE,
      p_id_nota OUT nota_credito.id_nota%TYPE);
  PROCEDURE sp_actualizar(
      p_id_nota IN nota_credito.id_nota%TYPE,
      p_monto IN nota_credito.monto%TYPE,
      p_motivo IN nota_credito.motivo%TYPE);
  PROCEDURE sp_eliminar(
      p_id_nota IN nota_credito.id_nota%TYPE);
  PROCEDURE sp_obtener(
      p_id_nota IN nota_credito.id_nota%TYPE,
      p_cursor OUT SYS_REFCURSOR);
  PROCEDURE sp_listar(
      p_cursor OUT SYS_REFCURSOR);
END pkg_nota_credito;
/

CREATE OR REPLACE PACKAGE BODY pkg_nota_credito AS
  e_hijos EXCEPTION;
  PRAGMA EXCEPTION_INIT(e_hijos, -2292);
  e_padre EXCEPTION;
  PRAGMA EXCEPTION_INIT(e_padre, -2291);
  e_check EXCEPTION;
  PRAGMA EXCEPTION_INIT(e_check, -2290);
  e_nulo EXCEPTION;
  PRAGMA EXCEPTION_INIT(e_nulo, -1400);

  PROCEDURE sp_insertar(
      p_id_factura IN nota_credito.id_factura%TYPE,
      p_fecha_nota IN nota_credito.fecha_nota%TYPE,
      p_monto IN nota_credito.monto%TYPE,
      p_motivo IN nota_credito.motivo%TYPE,
      p_id_nota OUT nota_credito.id_nota%TYPE) IS
  BEGIN
    IF NVL(fn_estado_factura(p_id_factura), 'X') = 'ANULADA' THEN
      RAISE_APPLICATION_ERROR(-20060, 'No se puede crear una nota para una factura anulada.');
    END IF;
    IF p_monto > fn_saldo_factura(p_id_factura) THEN
      RAISE_APPLICATION_ERROR(-20061, 'La nota de credito supera el saldo pendiente de la factura.');
    END IF;
    INSERT INTO nota_credito (id_nota, id_factura, fecha_nota, monto, motivo)
    VALUES (seq_nota_credito.NEXTVAL, p_id_factura, NVL(p_fecha_nota, SYSDATE), p_monto, p_motivo)
    RETURNING id_nota INTO p_id_nota;
    sp_recalcular_factura(p_id_factura);
  EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
      RAISE_APPLICATION_ERROR(-20001, 'Ya existe un registro con ese valor unico en NOTA_CREDITO.');
    WHEN NO_DATA_FOUND THEN
      RAISE_APPLICATION_ERROR(-20002, 'No existe el registro buscado en NOTA_CREDITO.');
    WHEN e_hijos THEN
      RAISE_APPLICATION_ERROR(-20003, 'No se puede borrar: NOTA_CREDITO tiene registros relacionados.');
    WHEN e_padre THEN
      RAISE_APPLICATION_ERROR(-20005, 'Una referencia no existe: revise las llaves de NOTA_CREDITO.');
    WHEN e_check THEN
      RAISE_APPLICATION_ERROR(-20006, 'Un valor no cumple las reglas de validacion de NOTA_CREDITO.');
    WHEN e_nulo THEN
      RAISE_APPLICATION_ERROR(-20007, 'Falta un dato obligatorio en NOTA_CREDITO.');
  END sp_insertar;

  PROCEDURE sp_actualizar(
      p_id_nota IN nota_credito.id_nota%TYPE,
      p_monto IN nota_credito.monto%TYPE,
      p_motivo IN nota_credito.motivo%TYPE) IS
    v_id_factura nota_credito.id_factura%TYPE;
    v_monto_actual nota_credito.monto%TYPE;
  BEGIN
    SELECT id_factura, monto INTO v_id_factura, v_monto_actual
      FROM nota_credito WHERE id_nota = p_id_nota;
    IF p_monto - v_monto_actual > fn_saldo_factura(v_id_factura) THEN
      RAISE_APPLICATION_ERROR(-20061, 'La nota de credito supera el saldo pendiente de la factura.');
    END IF;
    UPDATE nota_credito
       SET monto = p_monto,
           motivo = p_motivo
     WHERE id_nota = p_id_nota;
    IF SQL%ROWCOUNT = 0 THEN
      RAISE_APPLICATION_ERROR(-20002, 'No existe el registro buscado en NOTA_CREDITO.');
    END IF;
    sp_recalcular_factura(v_id_factura);
  EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
      RAISE_APPLICATION_ERROR(-20001, 'Ya existe un registro con ese valor unico en NOTA_CREDITO.');
    WHEN NO_DATA_FOUND THEN
      RAISE_APPLICATION_ERROR(-20002, 'No existe el registro buscado en NOTA_CREDITO.');
    WHEN e_hijos THEN
      RAISE_APPLICATION_ERROR(-20003, 'No se puede borrar: NOTA_CREDITO tiene registros relacionados.');
    WHEN e_padre THEN
      RAISE_APPLICATION_ERROR(-20005, 'Una referencia no existe: revise las llaves de NOTA_CREDITO.');
    WHEN e_check THEN
      RAISE_APPLICATION_ERROR(-20006, 'Un valor no cumple las reglas de validacion de NOTA_CREDITO.');
    WHEN e_nulo THEN
      RAISE_APPLICATION_ERROR(-20007, 'Falta un dato obligatorio en NOTA_CREDITO.');
  END sp_actualizar;

  PROCEDURE sp_eliminar(
      p_id_nota IN nota_credito.id_nota%TYPE) IS
    v_id_factura nota_credito.id_factura%TYPE;
  BEGIN
    SELECT id_factura INTO v_id_factura FROM nota_credito WHERE id_nota = p_id_nota;
    DELETE FROM nota_credito WHERE id_nota = p_id_nota;
    IF SQL%ROWCOUNT = 0 THEN
      RAISE_APPLICATION_ERROR(-20002, 'No existe el registro buscado en NOTA_CREDITO.');
    END IF;
    sp_recalcular_factura(v_id_factura);
  EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
      RAISE_APPLICATION_ERROR(-20001, 'Ya existe un registro con ese valor unico en NOTA_CREDITO.');
    WHEN NO_DATA_FOUND THEN
      RAISE_APPLICATION_ERROR(-20002, 'No existe el registro buscado en NOTA_CREDITO.');
    WHEN e_hijos THEN
      RAISE_APPLICATION_ERROR(-20003, 'No se puede borrar: NOTA_CREDITO tiene registros relacionados.');
    WHEN e_padre THEN
      RAISE_APPLICATION_ERROR(-20005, 'Una referencia no existe: revise las llaves de NOTA_CREDITO.');
    WHEN e_check THEN
      RAISE_APPLICATION_ERROR(-20006, 'Un valor no cumple las reglas de validacion de NOTA_CREDITO.');
    WHEN e_nulo THEN
      RAISE_APPLICATION_ERROR(-20007, 'Falta un dato obligatorio en NOTA_CREDITO.');
  END sp_eliminar;

  PROCEDURE sp_obtener(
      p_id_nota IN nota_credito.id_nota%TYPE,
      p_cursor OUT SYS_REFCURSOR) IS
  BEGIN
    OPEN p_cursor FOR
      SELECT id_nota, id_factura, fecha_nota, monto, motivo
        FROM nota_credito
       WHERE id_nota = p_id_nota;
  END sp_obtener;

  PROCEDURE sp_listar(
      p_cursor OUT SYS_REFCURSOR) IS
  BEGIN
    OPEN p_cursor FOR
      SELECT id_nota, id_factura, fecha_nota, monto, motivo
        FROM nota_credito
       ORDER BY id_nota;
  END sp_listar;
END pkg_nota_credito;
/

CREATE OR REPLACE PACKAGE pkg_pago AS
  PROCEDURE sp_insertar(
      p_id_cliente IN pago.id_cliente%TYPE,
      p_id_metodo_pago IN pago.id_metodo_pago%TYPE,
      p_fecha_pago IN pago.fecha_pago%TYPE,
      p_monto IN pago.monto%TYPE,
      p_referencia IN pago.referencia%TYPE,
      p_id_pago OUT pago.id_pago%TYPE);
  PROCEDURE sp_actualizar(
      p_id_pago IN pago.id_pago%TYPE,
      p_id_metodo_pago IN pago.id_metodo_pago%TYPE,
      p_fecha_pago IN pago.fecha_pago%TYPE,
      p_monto IN pago.monto%TYPE,
      p_referencia IN pago.referencia%TYPE);
  PROCEDURE sp_eliminar(
      p_id_pago IN pago.id_pago%TYPE);
  PROCEDURE sp_obtener(
      p_id_pago IN pago.id_pago%TYPE,
      p_cursor OUT SYS_REFCURSOR);
  PROCEDURE sp_listar(
      p_cursor OUT SYS_REFCURSOR);
END pkg_pago;
/

CREATE OR REPLACE PACKAGE BODY pkg_pago AS
  e_hijos EXCEPTION;
  PRAGMA EXCEPTION_INIT(e_hijos, -2292);
  e_padre EXCEPTION;
  PRAGMA EXCEPTION_INIT(e_padre, -2291);
  e_check EXCEPTION;
  PRAGMA EXCEPTION_INIT(e_check, -2290);
  e_nulo EXCEPTION;
  PRAGMA EXCEPTION_INIT(e_nulo, -1400);

  PROCEDURE sp_insertar(
      p_id_cliente IN pago.id_cliente%TYPE,
      p_id_metodo_pago IN pago.id_metodo_pago%TYPE,
      p_fecha_pago IN pago.fecha_pago%TYPE,
      p_monto IN pago.monto%TYPE,
      p_referencia IN pago.referencia%TYPE,
      p_id_pago OUT pago.id_pago%TYPE) IS
  BEGIN
    INSERT INTO pago (id_pago, id_cliente, id_metodo_pago, fecha_pago, monto, referencia, monto_sin_aplicar)
    VALUES (seq_pago.NEXTVAL, p_id_cliente, p_id_metodo_pago, NVL(p_fecha_pago, SYSDATE), p_monto, p_referencia, p_monto)
    RETURNING id_pago INTO p_id_pago;
  EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
      RAISE_APPLICATION_ERROR(-20001, 'Ya existe un registro con ese valor unico en PAGO.');
    WHEN NO_DATA_FOUND THEN
      RAISE_APPLICATION_ERROR(-20002, 'No existe el registro buscado en PAGO.');
    WHEN e_hijos THEN
      RAISE_APPLICATION_ERROR(-20003, 'No se puede borrar: PAGO tiene registros relacionados.');
    WHEN e_padre THEN
      RAISE_APPLICATION_ERROR(-20005, 'Una referencia no existe: revise las llaves de PAGO.');
    WHEN e_check THEN
      RAISE_APPLICATION_ERROR(-20006, 'Un valor no cumple las reglas de validacion de PAGO.');
    WHEN e_nulo THEN
      RAISE_APPLICATION_ERROR(-20007, 'Falta un dato obligatorio en PAGO.');
  END sp_insertar;

  PROCEDURE sp_actualizar(
      p_id_pago IN pago.id_pago%TYPE,
      p_id_metodo_pago IN pago.id_metodo_pago%TYPE,
      p_fecha_pago IN pago.fecha_pago%TYPE,
      p_monto IN pago.monto%TYPE,
      p_referencia IN pago.referencia%TYPE) IS
    v_aplicado pago.monto%TYPE;
  BEGIN
    v_aplicado := fn_monto_aplicado_pago(p_id_pago);
    IF p_monto < v_aplicado THEN
      RAISE_APPLICATION_ERROR(-20080, 'El monto no puede ser menor a lo que ya se aplico a facturas.');
    END IF;
    UPDATE pago
       SET id_metodo_pago = p_id_metodo_pago,
           fecha_pago = p_fecha_pago,
           monto = p_monto,
           referencia = p_referencia,
           monto_sin_aplicar = p_monto - v_aplicado
     WHERE id_pago = p_id_pago;
    IF SQL%ROWCOUNT = 0 THEN
      RAISE_APPLICATION_ERROR(-20002, 'No existe el registro buscado en PAGO.');
    END IF;
  EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
      RAISE_APPLICATION_ERROR(-20001, 'Ya existe un registro con ese valor unico en PAGO.');
    WHEN NO_DATA_FOUND THEN
      RAISE_APPLICATION_ERROR(-20002, 'No existe el registro buscado en PAGO.');
    WHEN e_hijos THEN
      RAISE_APPLICATION_ERROR(-20003, 'No se puede borrar: PAGO tiene registros relacionados.');
    WHEN e_padre THEN
      RAISE_APPLICATION_ERROR(-20005, 'Una referencia no existe: revise las llaves de PAGO.');
    WHEN e_check THEN
      RAISE_APPLICATION_ERROR(-20006, 'Un valor no cumple las reglas de validacion de PAGO.');
    WHEN e_nulo THEN
      RAISE_APPLICATION_ERROR(-20007, 'Falta un dato obligatorio en PAGO.');
  END sp_actualizar;

  PROCEDURE sp_eliminar(
      p_id_pago IN pago.id_pago%TYPE) IS
  BEGIN
    DELETE FROM pago WHERE id_pago = p_id_pago;
    IF SQL%ROWCOUNT = 0 THEN
      RAISE_APPLICATION_ERROR(-20002, 'No existe el registro buscado en PAGO.');
    END IF;
  EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
      RAISE_APPLICATION_ERROR(-20001, 'Ya existe un registro con ese valor unico en PAGO.');
    WHEN NO_DATA_FOUND THEN
      RAISE_APPLICATION_ERROR(-20002, 'No existe el registro buscado en PAGO.');
    WHEN e_hijos THEN
      RAISE_APPLICATION_ERROR(-20003, 'No se puede borrar: PAGO tiene registros relacionados.');
    WHEN e_padre THEN
      RAISE_APPLICATION_ERROR(-20005, 'Una referencia no existe: revise las llaves de PAGO.');
    WHEN e_check THEN
      RAISE_APPLICATION_ERROR(-20006, 'Un valor no cumple las reglas de validacion de PAGO.');
    WHEN e_nulo THEN
      RAISE_APPLICATION_ERROR(-20007, 'Falta un dato obligatorio en PAGO.');
  END sp_eliminar;

  PROCEDURE sp_obtener(
      p_id_pago IN pago.id_pago%TYPE,
      p_cursor OUT SYS_REFCURSOR) IS
  BEGIN
    OPEN p_cursor FOR
      SELECT id_pago, id_cliente, id_metodo_pago, fecha_pago, monto, referencia, monto_sin_aplicar
        FROM pago
       WHERE id_pago = p_id_pago;
  END sp_obtener;

  PROCEDURE sp_listar(
      p_cursor OUT SYS_REFCURSOR) IS
  BEGIN
    OPEN p_cursor FOR
      SELECT id_pago, id_cliente, id_metodo_pago, fecha_pago, monto, referencia, monto_sin_aplicar
        FROM pago
       ORDER BY id_pago;
  END sp_listar;
END pkg_pago;
/

CREATE OR REPLACE PACKAGE pkg_aplicacion_pago AS
  PROCEDURE sp_insertar(
      p_id_pago IN aplicacion_pago.id_pago%TYPE,
      p_id_factura IN aplicacion_pago.id_factura%TYPE,
      p_monto_aplicado IN aplicacion_pago.monto_aplicado%TYPE,
      p_fecha_aplicacion IN aplicacion_pago.fecha_aplicacion%TYPE,
      p_id_aplicacion OUT aplicacion_pago.id_aplicacion%TYPE);
  PROCEDURE sp_actualizar(
      p_id_aplicacion IN aplicacion_pago.id_aplicacion%TYPE,
      p_monto_aplicado IN aplicacion_pago.monto_aplicado%TYPE);
  PROCEDURE sp_eliminar(
      p_id_aplicacion IN aplicacion_pago.id_aplicacion%TYPE);
  PROCEDURE sp_obtener(
      p_id_aplicacion IN aplicacion_pago.id_aplicacion%TYPE,
      p_cursor OUT SYS_REFCURSOR);
  PROCEDURE sp_listar(
      p_cursor OUT SYS_REFCURSOR);
END pkg_aplicacion_pago;
/

CREATE OR REPLACE PACKAGE BODY pkg_aplicacion_pago AS
  e_hijos EXCEPTION;
  PRAGMA EXCEPTION_INIT(e_hijos, -2292);
  e_padre EXCEPTION;
  PRAGMA EXCEPTION_INIT(e_padre, -2291);
  e_check EXCEPTION;
  PRAGMA EXCEPTION_INIT(e_check, -2290);
  e_nulo EXCEPTION;
  PRAGMA EXCEPTION_INIT(e_nulo, -1400);

  PROCEDURE sp_insertar(
      p_id_pago IN aplicacion_pago.id_pago%TYPE,
      p_id_factura IN aplicacion_pago.id_factura%TYPE,
      p_monto_aplicado IN aplicacion_pago.monto_aplicado%TYPE,
      p_fecha_aplicacion IN aplicacion_pago.fecha_aplicacion%TYPE,
      p_id_aplicacion OUT aplicacion_pago.id_aplicacion%TYPE) IS
    v_cliente_pago pago.id_cliente%TYPE;
    v_cliente_factura factura.id_cliente%TYPE;
    v_sin_aplicar pago.monto_sin_aplicar%TYPE;
    v_saldo factura.saldo_pendiente%TYPE;
    v_estado factura.estado%TYPE;
  BEGIN
    SELECT id_cliente, monto_sin_aplicar INTO v_cliente_pago, v_sin_aplicar
      FROM pago WHERE id_pago = p_id_pago FOR UPDATE;
    SELECT id_cliente, saldo_pendiente, estado INTO v_cliente_factura, v_saldo, v_estado
      FROM factura WHERE id_factura = p_id_factura FOR UPDATE;
    IF v_cliente_pago <> v_cliente_factura THEN
      RAISE_APPLICATION_ERROR(-20090, 'El pago y la factura son de clientes distintos.');
    END IF;
    IF v_estado = 'ANULADA' THEN
      RAISE_APPLICATION_ERROR(-20091, 'No se puede aplicar un pago a una factura anulada.');
    END IF;
    IF p_monto_aplicado > v_sin_aplicar THEN
      RAISE_APPLICATION_ERROR(-20092, 'El monto supera lo que queda sin aplicar del pago.');
    END IF;
    IF p_monto_aplicado > v_saldo THEN
      RAISE_APPLICATION_ERROR(-20093, 'El monto supera el saldo pendiente de la factura.');
    END IF;
    INSERT INTO aplicacion_pago (id_aplicacion, id_pago, id_factura, monto_aplicado, fecha_aplicacion)
    VALUES (seq_aplicacion_pago.NEXTVAL, p_id_pago, p_id_factura, p_monto_aplicado, NVL(p_fecha_aplicacion, SYSDATE))
    RETURNING id_aplicacion INTO p_id_aplicacion;
    UPDATE pago SET monto_sin_aplicar = monto_sin_aplicar - p_monto_aplicado
     WHERE id_pago = p_id_pago;
    sp_recalcular_factura(p_id_factura);
  EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
      RAISE_APPLICATION_ERROR(-20001, 'Ya existe un registro con ese valor unico en APLICACION_PAGO.');
    WHEN NO_DATA_FOUND THEN
      RAISE_APPLICATION_ERROR(-20002, 'No existe el registro buscado en APLICACION_PAGO.');
    WHEN e_hijos THEN
      RAISE_APPLICATION_ERROR(-20003, 'No se puede borrar: APLICACION_PAGO tiene registros relacionados.');
    WHEN e_padre THEN
      RAISE_APPLICATION_ERROR(-20005, 'Una referencia no existe: revise las llaves de APLICACION_PAGO.');
    WHEN e_check THEN
      RAISE_APPLICATION_ERROR(-20006, 'Un valor no cumple las reglas de validacion de APLICACION_PAGO.');
    WHEN e_nulo THEN
      RAISE_APPLICATION_ERROR(-20007, 'Falta un dato obligatorio en APLICACION_PAGO.');
  END sp_insertar;

  PROCEDURE sp_actualizar(
      p_id_aplicacion IN aplicacion_pago.id_aplicacion%TYPE,
      p_monto_aplicado IN aplicacion_pago.monto_aplicado%TYPE) IS
    v_id_pago aplicacion_pago.id_pago%TYPE;
    v_id_factura aplicacion_pago.id_factura%TYPE;
    v_actual aplicacion_pago.monto_aplicado%TYPE;
    v_sin_aplicar pago.monto_sin_aplicar%TYPE;
    v_saldo factura.saldo_pendiente%TYPE;
  BEGIN
    SELECT id_pago, id_factura, monto_aplicado INTO v_id_pago, v_id_factura, v_actual
      FROM aplicacion_pago WHERE id_aplicacion = p_id_aplicacion FOR UPDATE;
    SELECT monto_sin_aplicar INTO v_sin_aplicar FROM pago WHERE id_pago = v_id_pago FOR UPDATE;
    SELECT saldo_pendiente INTO v_saldo FROM factura WHERE id_factura = v_id_factura FOR UPDATE;
    IF p_monto_aplicado - v_actual > v_sin_aplicar THEN
      RAISE_APPLICATION_ERROR(-20092, 'El monto supera lo que queda sin aplicar del pago.');
    END IF;
    IF p_monto_aplicado - v_actual > v_saldo THEN
      RAISE_APPLICATION_ERROR(-20093, 'El monto supera el saldo pendiente de la factura.');
    END IF;
    UPDATE aplicacion_pago
       SET monto_aplicado = p_monto_aplicado
     WHERE id_aplicacion = p_id_aplicacion;
    IF SQL%ROWCOUNT = 0 THEN
      RAISE_APPLICATION_ERROR(-20002, 'No existe el registro buscado en APLICACION_PAGO.');
    END IF;
    UPDATE pago SET monto_sin_aplicar = monto_sin_aplicar - (p_monto_aplicado - v_actual)
     WHERE id_pago = v_id_pago;
    sp_recalcular_factura(v_id_factura);
  EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
      RAISE_APPLICATION_ERROR(-20001, 'Ya existe un registro con ese valor unico en APLICACION_PAGO.');
    WHEN NO_DATA_FOUND THEN
      RAISE_APPLICATION_ERROR(-20002, 'No existe el registro buscado en APLICACION_PAGO.');
    WHEN e_hijos THEN
      RAISE_APPLICATION_ERROR(-20003, 'No se puede borrar: APLICACION_PAGO tiene registros relacionados.');
    WHEN e_padre THEN
      RAISE_APPLICATION_ERROR(-20005, 'Una referencia no existe: revise las llaves de APLICACION_PAGO.');
    WHEN e_check THEN
      RAISE_APPLICATION_ERROR(-20006, 'Un valor no cumple las reglas de validacion de APLICACION_PAGO.');
    WHEN e_nulo THEN
      RAISE_APPLICATION_ERROR(-20007, 'Falta un dato obligatorio en APLICACION_PAGO.');
  END sp_actualizar;

  PROCEDURE sp_eliminar(
      p_id_aplicacion IN aplicacion_pago.id_aplicacion%TYPE) IS
    v_id_pago aplicacion_pago.id_pago%TYPE;
    v_id_factura aplicacion_pago.id_factura%TYPE;
    v_actual aplicacion_pago.monto_aplicado%TYPE;
  BEGIN
    SELECT id_pago, id_factura, monto_aplicado INTO v_id_pago, v_id_factura, v_actual
      FROM aplicacion_pago WHERE id_aplicacion = p_id_aplicacion FOR UPDATE;
    DELETE FROM aplicacion_pago WHERE id_aplicacion = p_id_aplicacion;
    IF SQL%ROWCOUNT = 0 THEN
      RAISE_APPLICATION_ERROR(-20002, 'No existe el registro buscado en APLICACION_PAGO.');
    END IF;
    UPDATE pago SET monto_sin_aplicar = monto_sin_aplicar + v_actual
     WHERE id_pago = v_id_pago;
    sp_recalcular_factura(v_id_factura);
  EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
      RAISE_APPLICATION_ERROR(-20001, 'Ya existe un registro con ese valor unico en APLICACION_PAGO.');
    WHEN NO_DATA_FOUND THEN
      RAISE_APPLICATION_ERROR(-20002, 'No existe el registro buscado en APLICACION_PAGO.');
    WHEN e_hijos THEN
      RAISE_APPLICATION_ERROR(-20003, 'No se puede borrar: APLICACION_PAGO tiene registros relacionados.');
    WHEN e_padre THEN
      RAISE_APPLICATION_ERROR(-20005, 'Una referencia no existe: revise las llaves de APLICACION_PAGO.');
    WHEN e_check THEN
      RAISE_APPLICATION_ERROR(-20006, 'Un valor no cumple las reglas de validacion de APLICACION_PAGO.');
    WHEN e_nulo THEN
      RAISE_APPLICATION_ERROR(-20007, 'Falta un dato obligatorio en APLICACION_PAGO.');
  END sp_eliminar;

  PROCEDURE sp_obtener(
      p_id_aplicacion IN aplicacion_pago.id_aplicacion%TYPE,
      p_cursor OUT SYS_REFCURSOR) IS
  BEGIN
    OPEN p_cursor FOR
      SELECT id_aplicacion, id_pago, id_factura, monto_aplicado, fecha_aplicacion
        FROM aplicacion_pago
       WHERE id_aplicacion = p_id_aplicacion;
  END sp_obtener;

  PROCEDURE sp_listar(
      p_cursor OUT SYS_REFCURSOR) IS
  BEGIN
    OPEN p_cursor FOR
      SELECT id_aplicacion, id_pago, id_factura, monto_aplicado, fecha_aplicacion
        FROM aplicacion_pago
       ORDER BY id_aplicacion;
  END sp_listar;
END pkg_aplicacion_pago;
/

CREATE OR REPLACE PACKAGE pkg_gestion_cobro AS
  PROCEDURE sp_insertar(
      p_id_cliente IN gestion_cobro.id_cliente%TYPE,
      p_id_factura IN gestion_cobro.id_factura%TYPE,
      p_id_empleado IN gestion_cobro.id_empleado%TYPE,
      p_fecha_hora IN gestion_cobro.fecha_hora%TYPE,
      p_tipo_gestion IN gestion_cobro.tipo_gestion%TYPE,
      p_resultado IN gestion_cobro.resultado%TYPE,
      p_fecha_promesa IN gestion_cobro.fecha_promesa%TYPE,
      p_observacion IN gestion_cobro.observacion%TYPE,
      p_id_gestion OUT gestion_cobro.id_gestion%TYPE);
  PROCEDURE sp_actualizar(
      p_id_gestion IN gestion_cobro.id_gestion%TYPE,
      p_tipo_gestion IN gestion_cobro.tipo_gestion%TYPE,
      p_resultado IN gestion_cobro.resultado%TYPE,
      p_fecha_promesa IN gestion_cobro.fecha_promesa%TYPE,
      p_observacion IN gestion_cobro.observacion%TYPE);
  PROCEDURE sp_eliminar(
      p_id_gestion IN gestion_cobro.id_gestion%TYPE);
  PROCEDURE sp_obtener(
      p_id_gestion IN gestion_cobro.id_gestion%TYPE,
      p_cursor OUT SYS_REFCURSOR);
  PROCEDURE sp_listar(
      p_cursor OUT SYS_REFCURSOR);
END pkg_gestion_cobro;
/

CREATE OR REPLACE PACKAGE BODY pkg_gestion_cobro AS
  e_hijos EXCEPTION;
  PRAGMA EXCEPTION_INIT(e_hijos, -2292);
  e_padre EXCEPTION;
  PRAGMA EXCEPTION_INIT(e_padre, -2291);
  e_check EXCEPTION;
  PRAGMA EXCEPTION_INIT(e_check, -2290);
  e_nulo EXCEPTION;
  PRAGMA EXCEPTION_INIT(e_nulo, -1400);

  PROCEDURE sp_insertar(
      p_id_cliente IN gestion_cobro.id_cliente%TYPE,
      p_id_factura IN gestion_cobro.id_factura%TYPE,
      p_id_empleado IN gestion_cobro.id_empleado%TYPE,
      p_fecha_hora IN gestion_cobro.fecha_hora%TYPE,
      p_tipo_gestion IN gestion_cobro.tipo_gestion%TYPE,
      p_resultado IN gestion_cobro.resultado%TYPE,
      p_fecha_promesa IN gestion_cobro.fecha_promesa%TYPE,
      p_observacion IN gestion_cobro.observacion%TYPE,
      p_id_gestion OUT gestion_cobro.id_gestion%TYPE) IS
  BEGIN
    IF p_resultado = 'PROMESA_PAGO' AND p_fecha_promesa IS NULL THEN
      RAISE_APPLICATION_ERROR(-20100, 'Una promesa de pago necesita la fecha prometida.');
    END IF;
    INSERT INTO gestion_cobro (id_gestion, id_cliente, id_factura, id_empleado, fecha_hora, tipo_gestion, resultado, fecha_promesa, observacion)
    VALUES (seq_gestion_cobro.NEXTVAL, p_id_cliente, p_id_factura, p_id_empleado, NVL(p_fecha_hora, SYSDATE), p_tipo_gestion, p_resultado, p_fecha_promesa, p_observacion)
    RETURNING id_gestion INTO p_id_gestion;
  EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
      RAISE_APPLICATION_ERROR(-20001, 'Ya existe un registro con ese valor unico en GESTION_COBRO.');
    WHEN NO_DATA_FOUND THEN
      RAISE_APPLICATION_ERROR(-20002, 'No existe el registro buscado en GESTION_COBRO.');
    WHEN e_hijos THEN
      RAISE_APPLICATION_ERROR(-20003, 'No se puede borrar: GESTION_COBRO tiene registros relacionados.');
    WHEN e_padre THEN
      RAISE_APPLICATION_ERROR(-20005, 'Una referencia no existe: revise las llaves de GESTION_COBRO.');
    WHEN e_check THEN
      RAISE_APPLICATION_ERROR(-20006, 'Un valor no cumple las reglas de validacion de GESTION_COBRO.');
    WHEN e_nulo THEN
      RAISE_APPLICATION_ERROR(-20007, 'Falta un dato obligatorio en GESTION_COBRO.');
  END sp_insertar;

  PROCEDURE sp_actualizar(
      p_id_gestion IN gestion_cobro.id_gestion%TYPE,
      p_tipo_gestion IN gestion_cobro.tipo_gestion%TYPE,
      p_resultado IN gestion_cobro.resultado%TYPE,
      p_fecha_promesa IN gestion_cobro.fecha_promesa%TYPE,
      p_observacion IN gestion_cobro.observacion%TYPE) IS
  BEGIN
    IF p_resultado = 'PROMESA_PAGO' AND p_fecha_promesa IS NULL THEN
      RAISE_APPLICATION_ERROR(-20100, 'Una promesa de pago necesita la fecha prometida.');
    END IF;
    UPDATE gestion_cobro
       SET tipo_gestion = p_tipo_gestion,
           resultado = p_resultado,
           fecha_promesa = p_fecha_promesa,
           observacion = p_observacion
     WHERE id_gestion = p_id_gestion;
    IF SQL%ROWCOUNT = 0 THEN
      RAISE_APPLICATION_ERROR(-20002, 'No existe el registro buscado en GESTION_COBRO.');
    END IF;
  EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
      RAISE_APPLICATION_ERROR(-20001, 'Ya existe un registro con ese valor unico en GESTION_COBRO.');
    WHEN NO_DATA_FOUND THEN
      RAISE_APPLICATION_ERROR(-20002, 'No existe el registro buscado en GESTION_COBRO.');
    WHEN e_hijos THEN
      RAISE_APPLICATION_ERROR(-20003, 'No se puede borrar: GESTION_COBRO tiene registros relacionados.');
    WHEN e_padre THEN
      RAISE_APPLICATION_ERROR(-20005, 'Una referencia no existe: revise las llaves de GESTION_COBRO.');
    WHEN e_check THEN
      RAISE_APPLICATION_ERROR(-20006, 'Un valor no cumple las reglas de validacion de GESTION_COBRO.');
    WHEN e_nulo THEN
      RAISE_APPLICATION_ERROR(-20007, 'Falta un dato obligatorio en GESTION_COBRO.');
  END sp_actualizar;

  PROCEDURE sp_eliminar(
      p_id_gestion IN gestion_cobro.id_gestion%TYPE) IS
  BEGIN
    DELETE FROM gestion_cobro WHERE id_gestion = p_id_gestion;
    IF SQL%ROWCOUNT = 0 THEN
      RAISE_APPLICATION_ERROR(-20002, 'No existe el registro buscado en GESTION_COBRO.');
    END IF;
  EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
      RAISE_APPLICATION_ERROR(-20001, 'Ya existe un registro con ese valor unico en GESTION_COBRO.');
    WHEN NO_DATA_FOUND THEN
      RAISE_APPLICATION_ERROR(-20002, 'No existe el registro buscado en GESTION_COBRO.');
    WHEN e_hijos THEN
      RAISE_APPLICATION_ERROR(-20003, 'No se puede borrar: GESTION_COBRO tiene registros relacionados.');
    WHEN e_padre THEN
      RAISE_APPLICATION_ERROR(-20005, 'Una referencia no existe: revise las llaves de GESTION_COBRO.');
    WHEN e_check THEN
      RAISE_APPLICATION_ERROR(-20006, 'Un valor no cumple las reglas de validacion de GESTION_COBRO.');
    WHEN e_nulo THEN
      RAISE_APPLICATION_ERROR(-20007, 'Falta un dato obligatorio en GESTION_COBRO.');
  END sp_eliminar;

  PROCEDURE sp_obtener(
      p_id_gestion IN gestion_cobro.id_gestion%TYPE,
      p_cursor OUT SYS_REFCURSOR) IS
  BEGIN
    OPEN p_cursor FOR
      SELECT id_gestion, id_cliente, id_factura, id_empleado, fecha_hora, tipo_gestion, resultado, fecha_promesa, observacion
        FROM gestion_cobro
       WHERE id_gestion = p_id_gestion;
  END sp_obtener;

  PROCEDURE sp_listar(
      p_cursor OUT SYS_REFCURSOR) IS
  BEGIN
    OPEN p_cursor FOR
      SELECT id_gestion, id_cliente, id_factura, id_empleado, fecha_hora, tipo_gestion, resultado, fecha_promesa, observacion
        FROM gestion_cobro
       ORDER BY id_gestion;
  END sp_listar;
END pkg_gestion_cobro;
/

CREATE OR REPLACE PACKAGE pkg_bitacora AS
  PROCEDURE sp_insertar(
      p_tabla_afectada IN bitacora.tabla_afectada%TYPE,
      p_operacion IN bitacora.operacion%TYPE,
      p_detalle IN bitacora.detalle%TYPE,
      p_id_bitacora OUT bitacora.id_bitacora%TYPE);
  PROCEDURE sp_actualizar(
      p_id_bitacora IN bitacora.id_bitacora%TYPE,
      p_detalle IN bitacora.detalle%TYPE);
  PROCEDURE sp_eliminar(
      p_id_bitacora IN bitacora.id_bitacora%TYPE);
  PROCEDURE sp_obtener(
      p_id_bitacora IN bitacora.id_bitacora%TYPE,
      p_cursor OUT SYS_REFCURSOR);
  PROCEDURE sp_listar(
      p_cursor OUT SYS_REFCURSOR);
END pkg_bitacora;
/

CREATE OR REPLACE PACKAGE BODY pkg_bitacora AS
  e_hijos EXCEPTION;
  PRAGMA EXCEPTION_INIT(e_hijos, -2292);
  e_padre EXCEPTION;
  PRAGMA EXCEPTION_INIT(e_padre, -2291);
  e_check EXCEPTION;
  PRAGMA EXCEPTION_INIT(e_check, -2290);
  e_nulo EXCEPTION;
  PRAGMA EXCEPTION_INIT(e_nulo, -1400);

  PROCEDURE sp_insertar(
      p_tabla_afectada IN bitacora.tabla_afectada%TYPE,
      p_operacion IN bitacora.operacion%TYPE,
      p_detalle IN bitacora.detalle%TYPE,
      p_id_bitacora OUT bitacora.id_bitacora%TYPE) IS
  BEGIN
    INSERT INTO bitacora (id_bitacora, tabla_afectada, operacion, usuario_bd, fecha_hora, detalle)
    VALUES (seq_bitacora.NEXTVAL, p_tabla_afectada, p_operacion, SYS_CONTEXT('USERENV', 'SESSION_USER'), SYSDATE, p_detalle)
    RETURNING id_bitacora INTO p_id_bitacora;
  EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
      RAISE_APPLICATION_ERROR(-20001, 'Ya existe un registro con ese valor unico en BITACORA.');
    WHEN NO_DATA_FOUND THEN
      RAISE_APPLICATION_ERROR(-20002, 'No existe el registro buscado en BITACORA.');
    WHEN e_hijos THEN
      RAISE_APPLICATION_ERROR(-20003, 'No se puede borrar: BITACORA tiene registros relacionados.');
    WHEN e_padre THEN
      RAISE_APPLICATION_ERROR(-20005, 'Una referencia no existe: revise las llaves de BITACORA.');
    WHEN e_check THEN
      RAISE_APPLICATION_ERROR(-20006, 'Un valor no cumple las reglas de validacion de BITACORA.');
    WHEN e_nulo THEN
      RAISE_APPLICATION_ERROR(-20007, 'Falta un dato obligatorio en BITACORA.');
  END sp_insertar;

  PROCEDURE sp_actualizar(
      p_id_bitacora IN bitacora.id_bitacora%TYPE,
      p_detalle IN bitacora.detalle%TYPE) IS
  BEGIN
    UPDATE bitacora
       SET detalle = p_detalle
     WHERE id_bitacora = p_id_bitacora;
    IF SQL%ROWCOUNT = 0 THEN
      RAISE_APPLICATION_ERROR(-20002, 'No existe el registro buscado en BITACORA.');
    END IF;
  EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
      RAISE_APPLICATION_ERROR(-20001, 'Ya existe un registro con ese valor unico en BITACORA.');
    WHEN NO_DATA_FOUND THEN
      RAISE_APPLICATION_ERROR(-20002, 'No existe el registro buscado en BITACORA.');
    WHEN e_hijos THEN
      RAISE_APPLICATION_ERROR(-20003, 'No se puede borrar: BITACORA tiene registros relacionados.');
    WHEN e_padre THEN
      RAISE_APPLICATION_ERROR(-20005, 'Una referencia no existe: revise las llaves de BITACORA.');
    WHEN e_check THEN
      RAISE_APPLICATION_ERROR(-20006, 'Un valor no cumple las reglas de validacion de BITACORA.');
    WHEN e_nulo THEN
      RAISE_APPLICATION_ERROR(-20007, 'Falta un dato obligatorio en BITACORA.');
  END sp_actualizar;

  PROCEDURE sp_eliminar(
      p_id_bitacora IN bitacora.id_bitacora%TYPE) IS
    v_fecha bitacora.fecha_hora%TYPE;
  BEGIN
    SELECT fecha_hora INTO v_fecha FROM bitacora WHERE id_bitacora = p_id_bitacora;
    IF v_fecha > SYSDATE - 365 THEN
      RAISE_APPLICATION_ERROR(-20110, 'Solo se pueden borrar registros de bitacora con mas de 365 dias.');
    END IF;
    DELETE FROM bitacora WHERE id_bitacora = p_id_bitacora;
    IF SQL%ROWCOUNT = 0 THEN
      RAISE_APPLICATION_ERROR(-20002, 'No existe el registro buscado en BITACORA.');
    END IF;
  EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
      RAISE_APPLICATION_ERROR(-20001, 'Ya existe un registro con ese valor unico en BITACORA.');
    WHEN NO_DATA_FOUND THEN
      RAISE_APPLICATION_ERROR(-20002, 'No existe el registro buscado en BITACORA.');
    WHEN e_hijos THEN
      RAISE_APPLICATION_ERROR(-20003, 'No se puede borrar: BITACORA tiene registros relacionados.');
    WHEN e_padre THEN
      RAISE_APPLICATION_ERROR(-20005, 'Una referencia no existe: revise las llaves de BITACORA.');
    WHEN e_check THEN
      RAISE_APPLICATION_ERROR(-20006, 'Un valor no cumple las reglas de validacion de BITACORA.');
    WHEN e_nulo THEN
      RAISE_APPLICATION_ERROR(-20007, 'Falta un dato obligatorio en BITACORA.');
  END sp_eliminar;

  PROCEDURE sp_obtener(
      p_id_bitacora IN bitacora.id_bitacora%TYPE,
      p_cursor OUT SYS_REFCURSOR) IS
  BEGIN
    OPEN p_cursor FOR
      SELECT id_bitacora, tabla_afectada, operacion, usuario_bd, fecha_hora, detalle
        FROM bitacora
       WHERE id_bitacora = p_id_bitacora;
  END sp_obtener;

  PROCEDURE sp_listar(
      p_cursor OUT SYS_REFCURSOR) IS
  BEGIN
    OPEN p_cursor FOR
      SELECT id_bitacora, tabla_afectada, operacion, usuario_bd, fecha_hora, detalle
        FROM bitacora
       ORDER BY id_bitacora;
  END sp_listar;
END pkg_bitacora;
/


PROMPT >>> 06_procedimientos_negocio
-- Script 06: procedimientos de negocio y de reportes.
-- No hacen COMMIT. Los reportes devuelven un cursor (SYS_REFCURSOR).

CREATE OR REPLACE PROCEDURE sp_iniciar_sesion(
    p_usuario IN VARCHAR2,
    p_clave IN VARCHAR2,
    p_id_empleado OUT NUMBER,
    p_rol OUT VARCHAR2,
    p_nombre OUT VARCHAR2) IS
BEGIN
  p_id_empleado := fn_autenticar(p_usuario, p_clave);
  IF p_id_empleado IS NULL THEN
    RAISE_APPLICATION_ERROR(-20190, 'Usuario o clave incorrectos, o el usuario esta inactivo.');
  END IF;
  p_rol := fn_rol_empleado(p_id_empleado);
  p_nombre := fn_nombre_empleado(p_id_empleado);
END sp_iniciar_sesion;
/

CREATE OR REPLACE PROCEDURE sp_cambiar_clave_empleado(
    p_id_empleado IN NUMBER,
    p_clave_actual IN VARCHAR2,
    p_clave_nueva IN VARCHAR2) IS
  v_usuario empleado.usuario%TYPE;
  v_hash empleado.clave_hash%TYPE;
BEGIN
  SELECT usuario, clave_hash INTO v_usuario, v_hash
    FROM empleado WHERE id_empleado = p_id_empleado;
  IF v_hash <> fn_hash_clave(v_usuario, p_clave_actual) THEN
    RAISE_APPLICATION_ERROR(-20180, 'La clave actual no es correcta.');
  END IF;
  IF p_clave_nueva IS NULL OR LENGTH(p_clave_nueva) < 6 THEN
    RAISE_APPLICATION_ERROR(-20020, 'La clave debe tener al menos 6 caracteres.');
  END IF;
  UPDATE empleado
     SET clave_hash = fn_hash_clave(v_usuario, p_clave_nueva)
   WHERE id_empleado = p_id_empleado;
  sp_registrar_bitacora('EMPLEADO', 'UPDATE', 'Cambio de clave del empleado ' || p_id_empleado);
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    RAISE_APPLICATION_ERROR(-20002, 'No existe el empleado indicado.');
END sp_cambiar_clave_empleado;
/

CREATE OR REPLACE PROCEDURE sp_inactivar_empleado(p_id_empleado IN NUMBER) IS
BEGIN
  UPDATE empleado SET activo = 0 WHERE id_empleado = p_id_empleado;
  IF SQL%ROWCOUNT = 0 THEN
    RAISE_APPLICATION_ERROR(-20002, 'No existe el empleado indicado.');
  END IF;
  sp_registrar_bitacora('EMPLEADO', 'UPDATE', 'Empleado ' || p_id_empleado || ' inactivado');
END sp_inactivar_empleado;
/

CREATE OR REPLACE PROCEDURE sp_suspender_cliente(p_id_cliente IN NUMBER, p_motivo IN VARCHAR2) IS
BEGIN
  UPDATE cliente SET estado = 'SUSPENDIDO' WHERE id_cliente = p_id_cliente;
  IF SQL%ROWCOUNT = 0 THEN
    RAISE_APPLICATION_ERROR(-20002, 'No existe el cliente indicado.');
  END IF;
  sp_registrar_bitacora('CLIENTE', 'UPDATE',
    'Cliente ' || p_id_cliente || ' suspendido: ' || SUBSTR(p_motivo, 1, 200));
END sp_suspender_cliente;
/

CREATE OR REPLACE PROCEDURE sp_activar_cliente(p_id_cliente IN NUMBER) IS
BEGIN
  UPDATE cliente SET estado = 'ACTIVO' WHERE id_cliente = p_id_cliente;
  IF SQL%ROWCOUNT = 0 THEN
    RAISE_APPLICATION_ERROR(-20002, 'No existe el cliente indicado.');
  END IF;
  sp_registrar_bitacora('CLIENTE', 'UPDATE', 'Cliente ' || p_id_cliente || ' activado');
END sp_activar_cliente;
/

CREATE OR REPLACE PROCEDURE sp_cambiar_limite_credito(
    p_id_cliente IN NUMBER,
    p_nuevo_limite IN NUMBER,
    p_id_empleado IN NUMBER) IS
BEGIN
  IF NVL(fn_rol_empleado(p_id_empleado), 'X') <> 'ADMIN' THEN
    RAISE_APPLICATION_ERROR(-20150, 'Solo un ADMIN puede cambiar el limite de credito.');
  END IF;
  IF p_nuevo_limite IS NULL OR p_nuevo_limite < 0 THEN
    RAISE_APPLICATION_ERROR(-20151, 'El limite de credito no puede ser negativo.');
  END IF;
  UPDATE cliente SET limite_credito = p_nuevo_limite WHERE id_cliente = p_id_cliente;
  IF SQL%ROWCOUNT = 0 THEN
    RAISE_APPLICATION_ERROR(-20002, 'No existe el cliente indicado.');
  END IF;
END sp_cambiar_limite_credito;
/

CREATE OR REPLACE PROCEDURE sp_reasignar_cartera(
    p_id_vendedor_origen IN NUMBER,
    p_id_vendedor_destino IN NUMBER,
    p_clientes_movidos OUT NUMBER) IS
  CURSOR c_clientes IS
    SELECT id_cliente
      FROM cliente
     WHERE id_vendedor = p_id_vendedor_origen;
BEGIN
  IF NVL(fn_rol_empleado(p_id_vendedor_origen), 'X') <> 'VENDEDOR'
     OR NVL(fn_rol_empleado(p_id_vendedor_destino), 'X') <> 'VENDEDOR' THEN
    RAISE_APPLICATION_ERROR(-20030, 'Los dos empleados deben existir y tener rol VENDEDOR.');
  END IF;
  p_clientes_movidos := 0;
  FOR r IN c_clientes LOOP
    UPDATE cliente SET id_vendedor = p_id_vendedor_destino WHERE id_cliente = r.id_cliente;
    p_clientes_movidos := p_clientes_movidos + 1;
  END LOOP;
  sp_registrar_bitacora('CLIENTE', 'UPDATE',
    'Cartera de vendedor ' || p_id_vendedor_origen || ' pasada a ' || p_id_vendedor_destino
    || ' (' || p_clientes_movidos || ' clientes)');
END sp_reasignar_cartera;
/

CREATE OR REPLACE PROCEDURE sp_ajustar_stock(
    p_id_producto IN NUMBER,
    p_cantidad IN NUMBER,
    p_motivo IN VARCHAR2) IS
BEGIN
  IF fn_stock_producto(p_id_producto) + p_cantidad < 0 THEN
    RAISE_APPLICATION_ERROR(-20160, 'El ajuste dejaria las existencias en negativo.');
  END IF;
  UPDATE producto SET stock_actual = stock_actual + p_cantidad WHERE id_producto = p_id_producto;
  IF SQL%ROWCOUNT = 0 THEN
    RAISE_APPLICATION_ERROR(-20002, 'No existe el producto indicado.');
  END IF;
  sp_registrar_bitacora('PRODUCTO', 'UPDATE',
    'Ajuste de stock producto ' || p_id_producto || ' cantidad ' || p_cantidad || ': ' || SUBSTR(p_motivo, 1, 150));
END sp_ajustar_stock;
/

CREATE OR REPLACE PROCEDURE sp_actualizar_precio_producto(
    p_id_producto IN NUMBER,
    p_nuevo_precio IN NUMBER) IS
  v_anterior producto.precio_unitario%TYPE;
BEGIN
  IF p_nuevo_precio IS NULL OR p_nuevo_precio <= 0 THEN
    RAISE_APPLICATION_ERROR(-20161, 'El precio debe ser mayor a cero.');
  END IF;
  SELECT precio_unitario INTO v_anterior FROM producto WHERE id_producto = p_id_producto FOR UPDATE;
  UPDATE producto SET precio_unitario = p_nuevo_precio WHERE id_producto = p_id_producto;
  sp_registrar_bitacora('PRODUCTO', 'UPDATE',
    'Precio producto ' || p_id_producto || ' de ' || v_anterior || ' a ' || p_nuevo_precio);
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    RAISE_APPLICATION_ERROR(-20002, 'No existe el producto indicado.');
END sp_actualizar_precio_producto;
/

CREATE OR REPLACE PROCEDURE sp_finalizar_factura(p_id_factura IN NUMBER) IS
  v_id_cliente factura.id_cliente%TYPE;
  v_estado factura.estado%TYPE;
  v_limite cliente.limite_credito%TYPE;
BEGIN
  SELECT id_cliente, estado INTO v_id_cliente, v_estado
    FROM factura WHERE id_factura = p_id_factura FOR UPDATE;
  IF v_estado <> 'PENDIENTE' THEN
    RAISE_APPLICATION_ERROR(-20130, 'Solo se pueden finalizar facturas PENDIENTES.');
  END IF;
  IF fn_total_factura(p_id_factura) <= 0 THEN
    RAISE_APPLICATION_ERROR(-20131, 'La factura no tiene productos.');
  END IF;
  SELECT limite_credito INTO v_limite FROM cliente WHERE id_cliente = v_id_cliente;
  IF fn_saldo_cliente(v_id_cliente) > v_limite THEN
    RAISE_APPLICATION_ERROR(-20132, 'La factura supera el limite de credito del cliente.');
  END IF;
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    RAISE_APPLICATION_ERROR(-20002, 'No existe la factura indicada.');
END sp_finalizar_factura;
/

CREATE OR REPLACE PROCEDURE sp_anular_factura(p_id_factura IN NUMBER, p_motivo IN VARCHAR2) IS
  CURSOR c_detalle IS
    SELECT id_producto, cantidad
      FROM detalle_factura
     WHERE id_factura = p_id_factura;
  v_estado factura.estado%TYPE;
BEGIN
  SELECT estado INTO v_estado FROM factura WHERE id_factura = p_id_factura FOR UPDATE;
  IF v_estado = 'ANULADA' THEN
    RAISE_APPLICATION_ERROR(-20140, 'La factura ya esta anulada.');
  END IF;
  IF fn_monto_aplicado_factura(p_id_factura) > 0 THEN
    RAISE_APPLICATION_ERROR(-20141, 'La factura tiene pagos aplicados: reverse primero esas aplicaciones.');
  END IF;
  FOR r IN c_detalle LOOP
    UPDATE producto SET stock_actual = stock_actual + r.cantidad WHERE id_producto = r.id_producto;
  END LOOP;
  UPDATE factura SET estado = 'ANULADA', saldo_pendiente = 0 WHERE id_factura = p_id_factura;
  sp_registrar_bitacora('FACTURA', 'UPDATE',
    'Anulada factura ' || p_id_factura || ': ' || SUBSTR(p_motivo, 1, 200));
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    RAISE_APPLICATION_ERROR(-20002, 'No existe la factura indicada.');
END sp_anular_factura;
/

CREATE OR REPLACE PROCEDURE sp_registrar_nota_credito(
    p_id_factura IN NUMBER,
    p_monto IN NUMBER,
    p_motivo IN VARCHAR2,
    p_id_empleado IN NUMBER,
    p_id_nota OUT NUMBER) IS
BEGIN
  IF NVL(fn_rol_empleado(p_id_empleado), 'X') <> 'ADMIN' THEN
    RAISE_APPLICATION_ERROR(-20150, 'Solo un ADMIN puede registrar notas de credito.');
  END IF;
  pkg_nota_credito.sp_insertar(p_id_factura, SYSDATE, p_monto, p_motivo, p_id_nota);
END sp_registrar_nota_credito;
/

CREATE OR REPLACE PROCEDURE sp_aplicar_pago_automatico(
    p_id_pago IN NUMBER,
    p_total_aplicado OUT NUMBER) IS
  CURSOR c_facturas(p_cliente NUMBER) IS
    SELECT id_factura, saldo_pendiente
      FROM factura
     WHERE id_cliente = p_cliente
       AND estado = 'PENDIENTE'
       AND saldo_pendiente > 0
     ORDER BY fecha_vencimiento, id_factura;
  v_id_cliente pago.id_cliente%TYPE;
  v_sin_aplicar pago.monto_sin_aplicar%TYPE;
  v_monto NUMBER;
  v_id_aplicacion NUMBER;
BEGIN
  SELECT id_cliente, monto_sin_aplicar INTO v_id_cliente, v_sin_aplicar
    FROM pago WHERE id_pago = p_id_pago FOR UPDATE;
  p_total_aplicado := 0;
  FOR f IN c_facturas(v_id_cliente) LOOP
    EXIT WHEN v_sin_aplicar <= 0;
    v_monto := LEAST(v_sin_aplicar, f.saldo_pendiente);
    pkg_aplicacion_pago.sp_insertar(p_id_pago, f.id_factura, v_monto, SYSDATE, v_id_aplicacion);
    v_sin_aplicar := v_sin_aplicar - v_monto;
    p_total_aplicado := p_total_aplicado + v_monto;
  END LOOP;
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    RAISE_APPLICATION_ERROR(-20002, 'No existe el pago indicado.');
END sp_aplicar_pago_automatico;
/

CREATE OR REPLACE PROCEDURE sp_registrar_pago_y_aplicar(
    p_id_cliente IN NUMBER,
    p_id_metodo_pago IN NUMBER,
    p_fecha_pago IN DATE,
    p_monto IN NUMBER,
    p_referencia IN VARCHAR2,
    p_id_pago OUT NUMBER,
    p_aplicado OUT NUMBER,
    p_sobrante OUT NUMBER) IS
BEGIN
  pkg_pago.sp_insertar(p_id_cliente, p_id_metodo_pago, p_fecha_pago, p_monto, p_referencia, p_id_pago);
  sp_aplicar_pago_automatico(p_id_pago, p_aplicado);
  p_sobrante := p_monto - p_aplicado;
END sp_registrar_pago_y_aplicar;
/

CREATE OR REPLACE PROCEDURE sp_registrar_gestion_cobro(
    p_id_cliente IN NUMBER,
    p_id_factura IN NUMBER,
    p_id_empleado IN NUMBER,
    p_tipo_gestion IN VARCHAR2,
    p_resultado IN VARCHAR2,
    p_fecha_promesa IN DATE,
    p_observacion IN VARCHAR2,
    p_id_gestion OUT NUMBER) IS
BEGIN
  IF NVL(fn_rol_empleado(p_id_empleado), 'X') NOT IN ('COBRADOR', 'ADMIN') THEN
    RAISE_APPLICATION_ERROR(-20171, 'Solo un COBRADOR o ADMIN puede registrar gestiones de cobro.');
  END IF;
  IF fn_saldo_cliente(p_id_cliente) <= 0 THEN
    RAISE_APPLICATION_ERROR(-20170, 'El cliente no tiene saldo pendiente.');
  END IF;
  pkg_gestion_cobro.sp_insertar(p_id_cliente, p_id_factura, p_id_empleado, SYSDATE,
                                p_tipo_gestion, p_resultado, p_fecha_promesa, p_observacion, p_id_gestion);
END sp_registrar_gestion_cobro;
/

CREATE OR REPLACE PROCEDURE sp_purgar_bitacora(
    p_dias IN NUMBER,
    p_borrados OUT NUMBER) IS
  CURSOR c_viejos IS
    SELECT id_bitacora
      FROM bitacora
     WHERE fecha_hora < SYSDATE - p_dias;
BEGIN
  IF p_dias < 365 THEN
    RAISE_APPLICATION_ERROR(-20110, 'Solo se pueden borrar registros de bitacora con mas de 365 dias.');
  END IF;
  p_borrados := 0;
  FOR r IN c_viejos LOOP
    pkg_bitacora.sp_eliminar(r.id_bitacora);
    p_borrados := p_borrados + 1;
  END LOOP;
END sp_purgar_bitacora;
/

CREATE OR REPLACE PROCEDURE sp_rep_estado_cuenta(p_id_cliente IN NUMBER, p_cursor OUT SYS_REFCURSOR) IS
BEGIN
  OPEN p_cursor FOR
    SELECT numero_factura, fecha_emision, fecha_vencimiento, monto_total, total_notas,
           total_pagado, saldo_pendiente, estado, dias_mora
      FROM vw_estado_cuenta
     WHERE id_cliente = p_id_cliente
     ORDER BY fecha_emision, id_factura;
END sp_rep_estado_cuenta;
/

CREATE OR REPLACE PROCEDURE sp_rep_antiguedad_saldos(p_cursor OUT SYS_REFCURSOR) IS
BEGIN
  OPEN p_cursor FOR
    SELECT id_cliente, nombre_comercial, rango_0_30, rango_31_60, rango_61_90, rango_mas_90, saldo_total
      FROM vw_antiguedad_saldos
     ORDER BY saldo_total DESC;
END sp_rep_antiguedad_saldos;
/

CREATE OR REPLACE PROCEDURE sp_rep_clientes_morosos(p_cursor OUT SYS_REFCURSOR) IS
BEGIN
  OPEN p_cursor FOR
    SELECT id_cliente, nombre_comercial, vendedor, facturas_vencidas, monto_vencido, max_dias_mora
      FROM vw_clientes_morosos
     ORDER BY monto_vencido DESC;
END sp_rep_clientes_morosos;
/

CREATE OR REPLACE PROCEDURE sp_rep_facturas_vencidas(p_cursor OUT SYS_REFCURSOR) IS
BEGIN
  OPEN p_cursor FOR
    SELECT numero_factura, nombre_comercial, vendedor, fecha_vencimiento, saldo_pendiente, dias_mora, rango_mora
      FROM vw_facturas_vencidas
     ORDER BY dias_mora DESC;
END sp_rep_facturas_vencidas;
/

CREATE OR REPLACE PROCEDURE sp_rep_ventas_por_zona(
    p_desde IN DATE,
    p_hasta IN DATE,
    p_cursor OUT SYS_REFCURSOR) IS
BEGIN
  OPEN p_cursor FOR
    SELECT z.nombre_zona,
           COUNT(f.id_factura) AS cantidad_facturas,
           NVL(SUM(f.monto_total), 0) AS total_vendido
      FROM zona z
      LEFT JOIN cliente c ON c.id_zona = z.id_zona
      LEFT JOIN factura f ON f.id_cliente = c.id_cliente
                         AND f.estado <> 'ANULADA'
                         AND f.fecha_emision >= TRUNC(p_desde)
                         AND f.fecha_emision < TRUNC(p_hasta) + 1
     GROUP BY z.nombre_zona
     ORDER BY total_vendido DESC;
END sp_rep_ventas_por_zona;
/

CREATE OR REPLACE PROCEDURE sp_rep_ventas_por_vendedor(
    p_desde IN DATE,
    p_hasta IN DATE,
    p_cursor OUT SYS_REFCURSOR) IS
BEGIN
  OPEN p_cursor FOR
    SELECT e.nombre || ' ' || e.apellido AS vendedor,
           COUNT(f.id_factura) AS cantidad_facturas,
           fn_ventas_empleado(e.id_empleado, p_desde, p_hasta) AS total_vendido
      FROM empleado e
      LEFT JOIN factura f ON f.id_empleado = e.id_empleado
                         AND f.estado <> 'ANULADA'
                         AND f.fecha_emision >= TRUNC(p_desde)
                         AND f.fecha_emision < TRUNC(p_hasta) + 1
     WHERE e.rol = 'VENDEDOR'
     GROUP BY e.id_empleado, e.nombre, e.apellido
     ORDER BY total_vendido DESC;
END sp_rep_ventas_por_vendedor;
/

CREATE OR REPLACE PROCEDURE sp_rep_inventario_bajo(p_minimo IN NUMBER, p_cursor OUT SYS_REFCURSOR) IS
BEGIN
  OPEN p_cursor FOR
    SELECT codigo, nombre_producto, nombre_categoria, stock_actual, precio_unitario
      FROM vw_inventario_productos
     WHERE activo = 1
       AND stock_actual <= p_minimo
     ORDER BY stock_actual, nombre_producto;
END sp_rep_inventario_bajo;
/

CREATE OR REPLACE PROCEDURE sp_rep_pagos_sin_aplicar(p_cursor OUT SYS_REFCURSOR) IS
BEGIN
  OPEN p_cursor FOR
    SELECT id_pago, nombre_comercial, nombre_metodo, fecha_pago, monto, monto_sin_aplicar, referencia
      FROM vw_pagos_sin_aplicar
     ORDER BY fecha_pago;
END sp_rep_pagos_sin_aplicar;
/

CREATE OR REPLACE PROCEDURE sp_rep_gestiones_cliente(p_id_cliente IN NUMBER, p_cursor OUT SYS_REFCURSOR) IS
BEGIN
  OPEN p_cursor FOR
    SELECT fecha_hora, numero_factura, cobrador, tipo_gestion, resultado, fecha_promesa, observacion
      FROM vw_gestiones_detalle
     WHERE id_cliente = p_id_cliente
     ORDER BY fecha_hora DESC;
END sp_rep_gestiones_cliente;
/

CREATE OR REPLACE PROCEDURE sp_rep_resumen_cartera(p_cursor OUT SYS_REFCURSOR) IS
BEGIN
  OPEN p_cursor FOR
    SELECT cartera_total, cartera_vencida, cartera_vigente, clientes_con_saldo, facturas_pendientes
      FROM vw_resumen_cartera;
END sp_rep_resumen_cartera;
/

CREATE OR REPLACE PROCEDURE sp_rep_credito_clientes(p_cursor OUT SYS_REFCURSOR) IS
BEGIN
  OPEN p_cursor FOR
    SELECT id_cliente, nombre_comercial, estado, limite_credito, saldo_actual, credito_disponible, es_moroso
      FROM vw_clientes_credito
     ORDER BY nombre_comercial;
END sp_rep_credito_clientes;
/

CREATE OR REPLACE PROCEDURE sp_rep_detalle_factura(p_id_factura IN NUMBER, p_cursor OUT SYS_REFCURSOR) IS
BEGIN
  OPEN p_cursor FOR
    SELECT codigo, nombre_producto, cantidad, precio_unitario, subtotal
      FROM vw_detalle_factura_completo
     WHERE id_factura = p_id_factura
     ORDER BY nombre_producto;
END sp_rep_detalle_factura;
/


PROMPT >>> 07_triggers
-- Script 07: disparadores.

CREATE OR REPLACE TRIGGER trg_factura_estado
BEFORE INSERT OR UPDATE OF monto_total, saldo_pendiente, estado ON factura
FOR EACH ROW
BEGIN
  IF :NEW.estado <> 'ANULADA' THEN
    IF :NEW.monto_total > 0 AND :NEW.saldo_pendiente = 0 THEN
      :NEW.estado := 'PAGADA';
    ELSE
      :NEW.estado := 'PENDIENTE';
    END IF;
  END IF;
END trg_factura_estado;
/

CREATE OR REPLACE TRIGGER trg_pago_monto_sin_aplicar
BEFORE INSERT ON pago
FOR EACH ROW
BEGIN
  IF :NEW.monto_sin_aplicar IS NULL OR :NEW.monto_sin_aplicar = 0 THEN
    :NEW.monto_sin_aplicar := :NEW.monto;
  END IF;
END trg_pago_monto_sin_aplicar;
/

CREATE OR REPLACE TRIGGER trg_detalle_stock
AFTER INSERT OR UPDATE OR DELETE ON detalle_factura
FOR EACH ROW
BEGIN
  IF INSERTING THEN
    UPDATE producto SET stock_actual = stock_actual - :NEW.cantidad
     WHERE id_producto = :NEW.id_producto;
  ELSIF UPDATING THEN
    UPDATE producto SET stock_actual = stock_actual + :OLD.cantidad - :NEW.cantidad
     WHERE id_producto = :OLD.id_producto;
  ELSE
    UPDATE producto SET stock_actual = stock_actual + :OLD.cantidad
     WHERE id_producto = :OLD.id_producto;
  END IF;
END trg_detalle_stock;
/

CREATE OR REPLACE TRIGGER trg_bitacora_factura
AFTER INSERT OR UPDATE OR DELETE ON factura
FOR EACH ROW
BEGIN
  IF INSERTING THEN
    sp_registrar_bitacora('FACTURA', 'INSERT',
      'id=' || :NEW.id_factura || ' numero=' || :NEW.numero_factura || ' cliente=' || :NEW.id_cliente);
  ELSIF UPDATING THEN
    sp_registrar_bitacora('FACTURA', 'UPDATE',
      'id=' || :NEW.id_factura || ' estado ' || :OLD.estado || '->' || :NEW.estado
      || ' total=' || :NEW.monto_total || ' saldo=' || :NEW.saldo_pendiente);
  ELSE
    sp_registrar_bitacora('FACTURA', 'DELETE',
      'id=' || :OLD.id_factura || ' numero=' || :OLD.numero_factura);
  END IF;
END trg_bitacora_factura;
/

CREATE OR REPLACE TRIGGER trg_bitacora_pago
AFTER INSERT OR UPDATE OR DELETE ON pago
FOR EACH ROW
BEGIN
  IF INSERTING THEN
    sp_registrar_bitacora('PAGO', 'INSERT',
      'id=' || :NEW.id_pago || ' cliente=' || :NEW.id_cliente || ' monto=' || :NEW.monto);
  ELSIF UPDATING THEN
    sp_registrar_bitacora('PAGO', 'UPDATE',
      'id=' || :NEW.id_pago || ' monto=' || :NEW.monto || ' sin aplicar=' || :NEW.monto_sin_aplicar);
  ELSE
    sp_registrar_bitacora('PAGO', 'DELETE', 'id=' || :OLD.id_pago || ' monto=' || :OLD.monto);
  END IF;
END trg_bitacora_pago;
/

CREATE OR REPLACE TRIGGER trg_bitacora_nota_credito
AFTER INSERT OR DELETE ON nota_credito
FOR EACH ROW
BEGIN
  IF INSERTING THEN
    sp_registrar_bitacora('NOTA_CREDITO', 'INSERT',
      'id=' || :NEW.id_nota || ' factura=' || :NEW.id_factura || ' monto=' || :NEW.monto);
  ELSE
    sp_registrar_bitacora('NOTA_CREDITO', 'DELETE',
      'id=' || :OLD.id_nota || ' factura=' || :OLD.id_factura || ' monto=' || :OLD.monto);
  END IF;
END trg_bitacora_nota_credito;
/

CREATE OR REPLACE TRIGGER trg_bitacora_cliente_limite
AFTER UPDATE OF limite_credito ON cliente
FOR EACH ROW
WHEN (OLD.limite_credito <> NEW.limite_credito)
BEGIN
  sp_registrar_bitacora('CLIENTE', 'UPDATE',
    'id=' || :NEW.id_cliente || ' limite ' || :OLD.limite_credito || '->' || :NEW.limite_credito);
END trg_bitacora_cliente_limite;
/


PROMPT >>> 08_permisos
-- Script 08: permisos por rol. Ejecutar como LAMESETA, despues de crear los roles (script 00).
-- Las tablas NO se comparten: el usuario de la aplicacion solo puede ejecutar procedimientos y paquetes.

BEGIN
  FOR o IN (SELECT object_name
              FROM user_objects
             WHERE object_type IN ('PACKAGE', 'PROCEDURE', 'FUNCTION')) LOOP
    EXECUTE IMMEDIATE 'GRANT EXECUTE ON ' || o.object_name || ' TO rol_admin';
  END LOOP;
END;
/

GRANT EXECUTE ON pkg_zona TO rol_vendedor;
GRANT EXECUTE ON pkg_categoria TO rol_vendedor;
GRANT EXECUTE ON pkg_cliente TO rol_vendedor;
GRANT EXECUTE ON pkg_producto TO rol_vendedor;
GRANT EXECUTE ON pkg_factura TO rol_vendedor;
GRANT EXECUTE ON pkg_detalle_factura TO rol_vendedor;
GRANT EXECUTE ON sp_iniciar_sesion TO rol_vendedor;
GRANT EXECUTE ON sp_cambiar_clave_empleado TO rol_vendedor;
GRANT EXECUTE ON sp_finalizar_factura TO rol_vendedor;
GRANT EXECUTE ON sp_rep_estado_cuenta TO rol_vendedor;
GRANT EXECUTE ON sp_rep_detalle_factura TO rol_vendedor;
GRANT EXECUTE ON sp_rep_inventario_bajo TO rol_vendedor;
GRANT EXECUTE ON sp_rep_ventas_por_vendedor TO rol_vendedor;
GRANT EXECUTE ON sp_rep_credito_clientes TO rol_vendedor;
GRANT EXECUTE ON fn_saldo_cliente TO rol_vendedor;
GRANT EXECUTE ON fn_credito_disponible TO rol_vendedor;
GRANT EXECUTE ON fn_stock_producto TO rol_vendedor;

GRANT EXECUTE ON pkg_cliente TO rol_cobrador;
GRANT EXECUTE ON pkg_factura TO rol_cobrador;
GRANT EXECUTE ON pkg_metodo_pago TO rol_cobrador;
GRANT EXECUTE ON pkg_pago TO rol_cobrador;
GRANT EXECUTE ON pkg_aplicacion_pago TO rol_cobrador;
GRANT EXECUTE ON pkg_gestion_cobro TO rol_cobrador;
GRANT EXECUTE ON sp_iniciar_sesion TO rol_cobrador;
GRANT EXECUTE ON sp_cambiar_clave_empleado TO rol_cobrador;
GRANT EXECUTE ON sp_aplicar_pago_automatico TO rol_cobrador;
GRANT EXECUTE ON sp_registrar_pago_y_aplicar TO rol_cobrador;
GRANT EXECUTE ON sp_registrar_gestion_cobro TO rol_cobrador;
GRANT EXECUTE ON sp_rep_estado_cuenta TO rol_cobrador;
GRANT EXECUTE ON sp_rep_antiguedad_saldos TO rol_cobrador;
GRANT EXECUTE ON sp_rep_clientes_morosos TO rol_cobrador;
GRANT EXECUTE ON sp_rep_facturas_vencidas TO rol_cobrador;
GRANT EXECUTE ON sp_rep_pagos_sin_aplicar TO rol_cobrador;
GRANT EXECUTE ON sp_rep_gestiones_cliente TO rol_cobrador;
GRANT EXECUTE ON sp_rep_resumen_cartera TO rol_cobrador;
GRANT EXECUTE ON sp_rep_credito_clientes TO rol_cobrador;
GRANT EXECUTE ON sp_rep_detalle_factura TO rol_cobrador;
GRANT EXECUTE ON fn_saldo_cliente TO rol_cobrador;
GRANT EXECUTE ON fn_cliente_es_moroso TO rol_cobrador;


PROMPT >>> 09_datos_prueba
-- Script 09: datos de prueba. Todo se carga con los paquetes y procedimientos (no con INSERT directos),
-- asi tambien se prueban. Ejecutar una sola vez sobre tablas vacias.
-- Usuarios de ejemplo: admin / Admin2026, mrojas y lsolis / Vende2026, jvargas y kmora / Cobra2026.
SET SERVEROUTPUT ON

DECLARE
  v_z1 NUMBER; v_z2 NUMBER; v_z3 NUMBER; v_z4 NUMBER;
  v_k1 NUMBER; v_k2 NUMBER; v_k3 NUMBER; v_k4 NUMBER;
  v_m1 NUMBER; v_m2 NUMBER; v_m3 NUMBER; v_m4 NUMBER;
  v_admin NUMBER; v_v1 NUMBER; v_v2 NUMBER; v_c1 NUMBER; v_c2 NUMBER;
  v_cl1 NUMBER; v_cl2 NUMBER; v_cl3 NUMBER; v_cl4 NUMBER;
  v_cl5 NUMBER; v_cl6 NUMBER; v_cl7 NUMBER; v_cl8 NUMBER;
  v_p1 NUMBER; v_p2 NUMBER; v_p3 NUMBER; v_p4 NUMBER; v_p5 NUMBER; v_p6 NUMBER;
  v_p7 NUMBER; v_p8 NUMBER; v_p9 NUMBER; v_p10 NUMBER; v_p11 NUMBER; v_p12 NUMBER;
  v_f1 NUMBER; v_f2 NUMBER; v_f3 NUMBER; v_f4 NUMBER; v_f5 NUMBER; v_f6 NUMBER;
  v_f7 NUMBER; v_f8 NUMBER; v_f9 NUMBER; v_f10 NUMBER; v_f11 NUMBER; v_f12 NUMBER;
  v_pago NUMBER; v_aplicado NUMBER; v_sobrante NUMBER; v_nota NUMBER; v_gestion NUMBER;

  PROCEDURE crear_factura(p_cliente NUMBER, p_vendedor NUMBER, p_dias NUMBER,
                          p_prod1 NUMBER, p_cant1 NUMBER, p_prod2 NUMBER, p_cant2 NUMBER,
                          p_id OUT NUMBER) IS
  BEGIN
    pkg_factura.sp_insertar(p_cliente, p_vendedor, TRUNC(SYSDATE) - p_dias, p_id);
    pkg_detalle_factura.sp_insertar(p_id, p_prod1, p_cant1, NULL);
    pkg_detalle_factura.sp_insertar(p_id, p_prod2, p_cant2, NULL);
    sp_finalizar_factura(p_id);
  END crear_factura;
BEGIN
  pkg_zona.sp_insertar('Alajuela Centro', 'Alajuela', v_z1);
  pkg_zona.sp_insertar('Heredia Norte', 'Heredia', v_z2);
  pkg_zona.sp_insertar('San Jose Oeste', 'San Jose', v_z3);
  pkg_zona.sp_insertar('Cartago Sur', 'Cartago', v_z4);

  pkg_categoria.sp_insertar('Abarrotes', v_k1);
  pkg_categoria.sp_insertar('Bebidas', v_k2);
  pkg_categoria.sp_insertar('Limpieza', v_k3);
  pkg_categoria.sp_insertar('Snacks', v_k4);

  pkg_metodo_pago.sp_insertar('Efectivo', v_m1);
  pkg_metodo_pago.sp_insertar('Transferencia', v_m2);
  pkg_metodo_pago.sp_insertar('Cheque', v_m3);
  pkg_metodo_pago.sp_insertar('SINPE Movil', v_m4);

  pkg_empleado.sp_insertar(NULL, 'Marta', 'Jimenez', 'admin@lameseta.test', 'ADMIN', 'admin', 'Admin2026', 1, v_admin);
  pkg_empleado.sp_insertar(v_z1, 'Mauricio', 'Rojas', 'mrojas@lameseta.test', 'VENDEDOR', 'mrojas', 'Vende2026', 1, v_v1);
  pkg_empleado.sp_insertar(v_z2, 'Laura', 'Solis', 'lsolis@lameseta.test', 'VENDEDOR', 'lsolis', 'Vende2026', 1, v_v2);
  pkg_empleado.sp_insertar(v_z1, 'Jorge', 'Vargas', 'jvargas@lameseta.test', 'COBRADOR', 'jvargas', 'Cobra2026', 1, v_c1);
  pkg_empleado.sp_insertar(v_z3, 'Karla', 'Mora', 'kmora@lameseta.test', 'COBRADOR', 'kmora', 'Cobra2026', 1, v_c2);

  pkg_cliente.sp_insertar(v_z1, v_v1, '3-101-100001', 'Pulperia La Esperanza', 'esperanza@correo.test', '2440-1001', 'Alajuela centro', 1500000, 15, 'ACTIVO', v_cl1);
  pkg_cliente.sp_insertar(v_z1, v_v1, '3-101-100002', 'Minisuper Don Beto', 'donbeto@correo.test', '2440-1002', 'Alajuela, La Agonia', 3000000, 30, 'ACTIVO', v_cl2);
  pkg_cliente.sp_insertar(v_z2, v_v2, '3-101-100003', 'Soda El Rincon', 'elrincon@correo.test', '2260-1003', 'Heredia, Barva', 800000, 15, 'ACTIVO', v_cl3);
  pkg_cliente.sp_insertar(v_z2, v_v2, '3-101-100004', 'Abastecedor Los Angeles', 'losangeles@correo.test', '2260-1004', 'Heredia, San Rafael', 1200000, 30, 'ACTIVO', v_cl4);
  pkg_cliente.sp_insertar(v_z3, v_v1, '3-101-100005', 'Pulperia Santa Rosa', 'santarosa@correo.test', '2220-1005', 'San Jose, Escazu', 700000, 15, 'ACTIVO', v_cl5);
  pkg_cliente.sp_insertar(v_z3, v_v2, '3-101-100006', 'Minisuper El Ahorro', 'elahorro@correo.test', '2220-1006', 'San Jose, Santa Ana', 2500000, 30, 'ACTIVO', v_cl6);
  pkg_cliente.sp_insertar(v_z4, v_v1, '3-101-100007', 'Cafeteria Central', 'central@correo.test', '2550-1007', 'Cartago centro', 600000, 15, 'ACTIVO', v_cl7);
  pkg_cliente.sp_insertar(v_z4, v_v2, '3-101-100008', 'Pulperia Dona Lela', 'donalela@correo.test', '2550-1008', 'Cartago, Paraiso', 500000, 15, 'ACTIVO', v_cl8);

  pkg_producto.sp_insertar(v_k1, 'ARR-001', 'Arroz 1 kg', 1450, 500, 1, v_p1);
  pkg_producto.sp_insertar(v_k1, 'FRI-001', 'Frijoles 800 g', 1300, 500, 1, v_p2);
  pkg_producto.sp_insertar(v_k1, 'ACE-001', 'Aceite 900 ml', 2850, 500, 1, v_p3);
  pkg_producto.sp_insertar(v_k1, 'AZU-001', 'Azucar 1 kg', 1250, 500, 1, v_p4);
  pkg_producto.sp_insertar(v_k1, 'CAF-001', 'Cafe molido 500 g', 4200, 500, 1, v_p5);
  pkg_producto.sp_insertar(v_k2, 'GAS-001', 'Gaseosa 2 L', 1900, 500, 1, v_p6);
  pkg_producto.sp_insertar(v_k2, 'AGU-001', 'Agua 600 ml', 650, 15, 1, v_p7);
  pkg_producto.sp_insertar(v_k2, 'JUG-001', 'Jugo 1 L', 1750, 500, 1, v_p8);
  pkg_producto.sp_insertar(v_k3, 'JAB-001', 'Jabon liquido 1 L', 3200, 500, 1, v_p9);
  pkg_producto.sp_insertar(v_k3, 'DET-001', 'Detergente 1 kg', 3900, 500, 1, v_p10);
  pkg_producto.sp_insertar(v_k3, 'PAP-001', 'Papel higienico 12 rollos', 5200, 500, 1, v_p11);
  pkg_producto.sp_insertar(v_k4, 'SNK-001', 'Papas fritas 150 g', 1100, 8, 1, v_p12);

  crear_factura(v_cl1, v_v1, 50, v_p1, 40, v_p2, 30, v_f1);
  crear_factura(v_cl1, v_v1, 10, v_p3, 20, v_p4, 30, v_f2);
  crear_factura(v_cl2, v_v1, 80, v_p5, 25, v_p6, 60, v_f3);
  crear_factura(v_cl2, v_v1, 20, v_p11, 15, v_p10, 10, v_f4);
  crear_factura(v_cl3, v_v2, 120, v_p9, 20, v_p8, 40, v_f5);
  crear_factura(v_cl4, v_v2, 40, v_p1, 60, v_p4, 40, v_f6);
  crear_factura(v_cl5, v_v1, 5, v_p5, 10, v_p3, 10, v_f7);
  crear_factura(v_cl6, v_v2, 65, v_p6, 80, v_p10, 15, v_f8);
  crear_factura(v_cl7, v_v1, 30, v_p12, 5, v_p11, 10, v_f9);
  crear_factura(v_cl8, v_v2, 15, v_p7, 10, v_p2, 20, v_f10);
  crear_factura(v_cl3, v_v2, 8, v_p8, 10, v_p1, 10, v_f11);
  crear_factura(v_cl6, v_v2, 3, v_p9, 10, v_p3, 10, v_f12);

  sp_registrar_pago_y_aplicar(v_cl1, v_m2, TRUNC(SYSDATE) - 5, 100000, 'TRF-0001', v_pago, v_aplicado, v_sobrante);
  sp_registrar_pago_y_aplicar(v_cl2, v_m3, TRUNC(SYSDATE) - 4, 300000, 'CHQ-5521', v_pago, v_aplicado, v_sobrante);
  sp_registrar_pago_y_aplicar(v_cl3, v_m4, TRUNC(SYSDATE) - 2, 50000, 'SINPE-8871', v_pago, v_aplicado, v_sobrante);
  sp_registrar_pago_y_aplicar(v_cl4, v_m1, TRUNC(SYSDATE) - 1, 200000, NULL, v_pago, v_aplicado, v_sobrante);

  sp_registrar_nota_credito(v_f8, 10500, 'Devolucion de unidades danadas', v_admin, v_nota);

  sp_registrar_gestion_cobro(v_cl3, v_f5, v_c1, 'LLAMADA', 'PROMESA_PAGO', TRUNC(SYSDATE) + 7, 'Promete pagar el viernes', v_gestion);
  sp_registrar_gestion_cobro(v_cl6, v_f8, v_c2, 'VISITA', 'SIN_RESPUESTA', NULL, 'Local cerrado', v_gestion);
  sp_registrar_gestion_cobro(v_cl2, v_f4, v_c1, 'WHATSAPP', 'PROMESA_PAGO', TRUNC(SYSDATE) + 5, 'Pagara el saldo con SINPE', v_gestion);
  sp_registrar_gestion_cobro(v_cl7, v_f9, v_c1, 'LLAMADA', 'DISPUTA', NULL, 'Dice que falto producto en la entrega', v_gestion);

  INSERT INTO bitacora (id_bitacora, tabla_afectada, operacion, usuario_bd, fecha_hora, detalle)
  VALUES (seq_bitacora.NEXTVAL, 'ZONA', 'INSERT', 'LAMESETA', SYSDATE - 400, 'Registro antiguo de prueba');

  COMMIT;
  DBMS_OUTPUT.PUT_LINE('Datos de prueba cargados.');
END;
/


PROMPT >>> 10_verificacion
-- Script 10: verificacion. Ejecutar como LAMESETA despues de los scripts 01 a 09.
SET SERVEROUTPUT ON

PROMPT === 1. Cantidad de objetos por tipo ===
SELECT object_type, COUNT(*) AS cantidad
  FROM user_objects
 WHERE object_type IN ('TABLE', 'SEQUENCE', 'VIEW', 'FUNCTION', 'PROCEDURE', 'PACKAGE', 'PACKAGE BODY', 'TRIGGER')
 GROUP BY object_type
 ORDER BY object_type;

PROMPT === 2. Objetos invalidos (debe salir vacio) ===
SELECT object_name, object_type, status FROM user_objects WHERE status <> 'VALID';

PROMPT === 3. Errores de compilacion (debe salir vacio) ===
SELECT name, type, line, text FROM user_errors ORDER BY name, type, sequence;

PROMPT === 4. Procedimientos dentro de cada paquete ===
SELECT object_name AS paquete, COUNT(*) AS procedimientos
  FROM user_procedures
 WHERE object_type = 'PACKAGE' AND procedure_name IS NOT NULL
 GROUP BY object_name
 ORDER BY object_name;

PROMPT === 5. Cursores: lineas con CURSOR o SYS_REFCURSOR en el codigo ===
SELECT type, COUNT(*) AS lineas_con_cursor
  FROM user_source
 WHERE type IN ('PROCEDURE', 'PACKAGE BODY')
   AND REGEXP_LIKE(text, 'SYS_REFCURSOR|^[[:space:]]*CURSOR[[:space:]]', 'i')
 GROUP BY type;

PROMPT === 6. Filas por tabla ===
SELECT 'ZONA' AS tabla, COUNT(*) AS filas FROM zona UNION ALL
SELECT 'EMPLEADO', COUNT(*) FROM empleado UNION ALL
SELECT 'CLIENTE', COUNT(*) FROM cliente UNION ALL
SELECT 'CATEGORIA', COUNT(*) FROM categoria UNION ALL
SELECT 'PRODUCTO', COUNT(*) FROM producto UNION ALL
SELECT 'METODO_PAGO', COUNT(*) FROM metodo_pago UNION ALL
SELECT 'FACTURA', COUNT(*) FROM factura UNION ALL
SELECT 'DETALLE_FACTURA', COUNT(*) FROM detalle_factura UNION ALL
SELECT 'NOTA_CREDITO', COUNT(*) FROM nota_credito UNION ALL
SELECT 'PAGO', COUNT(*) FROM pago UNION ALL
SELECT 'APLICACION_PAGO', COUNT(*) FROM aplicacion_pago UNION ALL
SELECT 'GESTION_COBRO', COUNT(*) FROM gestion_cobro UNION ALL
SELECT 'BITACORA', COUNT(*) FROM bitacora;

PROMPT === 7. Facturas cuyo saldo no cuadra (debe salir vacio) ===
SELECT numero_factura, saldo_pendiente,
       monto_total - fn_total_notas_factura(id_factura) - fn_monto_aplicado_factura(id_factura) AS saldo_calculado
  FROM factura
 WHERE estado <> 'ANULADA'
   AND saldo_pendiente <> monto_total - fn_total_notas_factura(id_factura) - fn_monto_aplicado_factura(id_factura);

PROMPT === 8. Pagos cuyo monto sin aplicar no cuadra (debe salir vacio) ===
SELECT id_pago, monto, monto_sin_aplicar, fn_monto_aplicado_pago(id_pago) AS aplicado
  FROM pago
 WHERE monto_sin_aplicar <> monto - fn_monto_aplicado_pago(id_pago);

PROMPT === 9. Prueba del CRUD y de los errores esperados (todo se deshace con ROLLBACK) ===
DECLARE
  v_zona NUMBER;
  v_id NUMBER;
  v_factura NUMBER;
  v_cliente NUMBER;
  v_vendedor NUMBER;
  v_producto NUMBER;
  v_cursor SYS_REFCURSOR;
  v_nombre zona.nombre_zona%TYPE;
  v_provincia zona.provincia%TYPE;

  PROCEDURE resultado(p_prueba VARCHAR2, p_esperado NUMBER, p_obtenido NUMBER) IS
  BEGIN
    IF p_esperado = p_obtenido THEN
      DBMS_OUTPUT.PUT_LINE('OK    ' || p_prueba || ' (error ' || p_esperado || ' esperado)');
    ELSE
      DBMS_OUTPUT.PUT_LINE('FALLO ' || p_prueba || ': se esperaba ' || p_esperado || ' y salio ' || p_obtenido);
    END IF;
  END resultado;
BEGIN
  pkg_zona.sp_insertar('Zona de prueba', 'Limon', v_zona);
  pkg_zona.sp_actualizar(v_zona, 'Zona de prueba 2', 'Limon');
  pkg_zona.sp_obtener(v_zona, v_cursor);
  FETCH v_cursor INTO v_id, v_nombre, v_provincia;
  CLOSE v_cursor;
  DBMS_OUTPUT.PUT_LINE('OK    CRUD de zona: ' || v_nombre);
  pkg_zona.sp_eliminar(v_zona);

  SELECT id_zona INTO v_id FROM zona WHERE nombre_zona = 'Alajuela Centro';

  BEGIN
    pkg_zona.sp_insertar('Alajuela Centro', 'Alajuela', v_zona);
    resultado('zona duplicada', -20001, 0);
  EXCEPTION
    WHEN OTHERS THEN resultado('zona duplicada', -20001, SQLCODE);
  END;

  BEGIN
    pkg_zona.sp_eliminar(v_id);
    resultado('borrar zona con clientes', -20003, 0);
  EXCEPTION
    WHEN OTHERS THEN resultado('borrar zona con clientes', -20003, SQLCODE);
  END;

  BEGIN
    pkg_empleado.sp_insertar(NULL, 'Prueba', 'Clave', 'prueba@lameseta.test', 'COBRADOR', 'ptest', '123', 1, v_id);
    resultado('clave muy corta', -20020, 0);
  EXCEPTION
    WHEN OTHERS THEN resultado('clave muy corta', -20020, SQLCODE);
  END;

  SELECT MIN(id_empleado) INTO v_vendedor FROM empleado WHERE rol = 'VENDEDOR';
  SELECT id_cliente INTO v_cliente FROM cliente WHERE cedula = '3-101-100008';
  SELECT id_producto INTO v_producto FROM producto WHERE codigo = 'PAP-001';

  pkg_factura.sp_insertar(v_cliente, v_vendedor, SYSDATE, v_factura);

  BEGIN
    pkg_detalle_factura.sp_insertar(v_factura, v_producto, 999999, NULL);
    resultado('stock insuficiente', -20051, 0);
  EXCEPTION
    WHEN OTHERS THEN resultado('stock insuficiente', -20051, SQLCODE);
  END;

  pkg_detalle_factura.sp_insertar(v_factura, v_producto, 200, NULL);
  BEGIN
    sp_finalizar_factura(v_factura);
    resultado('factura sobre el limite de credito', -20132, 0);
  EXCEPTION
    WHEN OTHERS THEN resultado('factura sobre el limite de credito', -20132, SQLCODE);
  END;

  SELECT MIN(id_factura) INTO v_factura FROM factura WHERE saldo_pendiente > 0;
  BEGIN
    pkg_nota_credito.sp_insertar(v_factura, SYSDATE, 999999999, 'prueba', v_id);
    resultado('nota mayor al saldo', -20061, 0);
  EXCEPTION
    WHEN OTHERS THEN resultado('nota mayor al saldo', -20061, SQLCODE);
  END;
END;
/
ROLLBACK;

