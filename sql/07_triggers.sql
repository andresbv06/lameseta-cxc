-- Script 07: disparadores (triggers). Se ejecutan solos cuando cambia una tabla.
SET DEFINE OFF

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
