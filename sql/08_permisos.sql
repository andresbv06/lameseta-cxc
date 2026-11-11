-- Script 08: permisos por rol. Ejecutar como LAMESETA, despues de crear los roles (script 00).
-- El usuario de la aplicacion no toca las tablas: solo ejecuta procedimientos y paquetes.
SET DEFINE OFF

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
