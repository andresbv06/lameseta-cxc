-- Script 03: procedimientos base que usan los paquetes y los disparadores.
SET DEFINE OFF

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
