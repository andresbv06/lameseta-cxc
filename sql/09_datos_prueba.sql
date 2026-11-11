-- Script 09: datos de prueba. Todo se carga con los paquetes y procedimientos (no con INSERT directos),
-- asi tambien se prueban. Ejecutar una sola vez sobre tablas vacias.
-- Usuarios de ejemplo: admin / Admin2026, mrojas y lsolis / Vende2026, jvargas y kmora / Cobra2026.
SET DEFINE OFF
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
