-- Script 10: verificacion. Ejecutar como LAMESETA despues de los scripts 01 a 09.
SET DEFINE OFF
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
