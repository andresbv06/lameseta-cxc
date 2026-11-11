-- Script 04: vistas (consultas guardadas) para los reportes.
SET DEFINE OFF

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
