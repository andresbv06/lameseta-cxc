-- Script 02: funciones. Solo consultan datos, no los cambian.
SET DEFINE OFF

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
