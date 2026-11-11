-- Script 06: procedimientos de negocio y de reportes.
-- Los reportes (sp_rep_*) devuelven una lista de filas que el programa Python recorre.
SET DEFINE OFF

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
