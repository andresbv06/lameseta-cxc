"""Modelo unico de la base de datos de Distribuidora La Meseta.
De aqui se generan las tablas, los paquetes CRUD, los metadatos de Python y el diccionario de datos."""


def C(nombre, tipo, req=True, default=None, desc="", check=None, enum=None):
    return dict(nombre=nombre, tipo=tipo, req=req, default=default, desc=desc, check=check, enum=enum)


ID = "NUMBER(10)"
DIN = "NUMBER(12,2)"
EMAIL_CK = "{c} IS NULL OR {c} LIKE '%_@_%._%'"

TABLAS = [
    dict(
        nombre="ZONA", seq="SEQ_ZONA", pk=["id_zona"],
        desc="Zonas de reparto y cobro de la empresa.",
        cols=[
            C("id_zona", ID, desc="Identificador de la zona."),
            C("nombre_zona", "VARCHAR2(60)", desc="Nombre de la zona."),
            C("provincia", "VARCHAR2(40)", desc="Provincia a la que pertenece."),
        ],
        uniques=[("uq_zona_nombre", ["nombre_zona"])],
        ins=["nombre_zona", "provincia"], upd=["nombre_zona", "provincia"],
    ),
    dict(
        nombre="EMPLEADO", seq="SEQ_EMPLEADO", pk=["id_empleado"],
        desc="Vendedores, cobradores y administradores con su usuario del sistema.",
        cols=[
            C("id_empleado", ID, desc="Identificador del empleado."),
            C("id_zona", ID, req=False, desc="Zona asignada (puede ser nula para administradores)."),
            C("nombre", "VARCHAR2(60)", desc="Nombre."),
            C("apellido", "VARCHAR2(60)", desc="Apellidos."),
            C("correo", "VARCHAR2(100)", desc="Correo electronico.", check=EMAIL_CK),
            C("rol", "VARCHAR2(10)", desc="Rol en el sistema.", enum=["ADMIN", "VENDEDOR", "COBRADOR"]),
            C("usuario", "VARCHAR2(30)", desc="Nombre de usuario para iniciar sesion."),
            C("clave_hash", "VARCHAR2(64)", desc="Clave guardada como hash SHA-256 con sal."),
            C("activo", "NUMBER(1)", default="1", desc="1 = activo, 0 = inactivo.", enum=[0, 1]),
        ],
        fks=[("fk_empleado_zona", ["id_zona"], "ZONA", ["id_zona"])],
        uniques=[("uq_empleado_usuario", ["usuario"]), ("uq_empleado_correo", ["correo"])],
        ins=["id_zona", "nombre", "apellido", "correo", "rol", "usuario", "@clave", "activo"],
        ins_cols=["id_zona", "nombre", "apellido", "correo", "rol", "usuario", "clave_hash", "activo"],
        ins_vals={"clave_hash": "fn_hash_clave(p_usuario, p_clave)"},
        upd=["id_zona", "nombre", "apellido", "correo", "rol", "activo"],
        sel=["id_empleado", "id_zona", "nombre", "apellido", "correo", "rol", "usuario", "activo"],
        ins_pre="""IF p_clave IS NULL OR LENGTH(p_clave) < 6 THEN
  RAISE_APPLICATION_ERROR(-20020, 'La clave debe tener al menos 6 caracteres.');
END IF;""",
    ),
    dict(
        nombre="CLIENTE", seq="SEQ_CLIENTE", pk=["id_cliente"],
        desc="Negocios que compran a credito, con su limite y dias de credito.",
        cols=[
            C("id_cliente", ID, desc="Identificador del cliente."),
            C("id_zona", ID, desc="Zona donde esta el cliente."),
            C("id_vendedor", ID, desc="Vendedor que atiende al cliente."),
            C("cedula", "VARCHAR2(20)", desc="Cedula fisica o juridica."),
            C("nombre_comercial", "VARCHAR2(100)", desc="Nombre del negocio."),
            C("correo", "VARCHAR2(100)", req=False, desc="Correo de contacto.", check=EMAIL_CK),
            C("telefono", "VARCHAR2(20)", req=False, desc="Telefono de contacto."),
            C("direccion", "VARCHAR2(200)", req=False, desc="Direccion del negocio."),
            C("limite_credito", DIN, default="0", desc="Monto maximo que puede deber.", check="{c} >= 0"),
            C("dias_credito", "NUMBER(3)", default="15", desc="Dias de plazo para pagar.", check="{c} BETWEEN 0 AND 90"),
            C("estado", "VARCHAR2(10)", default="'ACTIVO'", desc="Estado del cliente.", enum=["ACTIVO", "INACTIVO", "SUSPENDIDO"]),
        ],
        fks=[("fk_cliente_zona", ["id_zona"], "ZONA", ["id_zona"]),
             ("fk_cliente_vendedor", ["id_vendedor"], "EMPLEADO", ["id_empleado"])],
        uniques=[("uq_cliente_cedula", ["cedula"])],
        ins=["id_zona", "id_vendedor", "cedula", "nombre_comercial", "correo", "telefono", "direccion",
             "limite_credito", "dias_credito", "estado"],
        upd=["id_zona", "id_vendedor", "cedula", "nombre_comercial", "correo", "telefono", "direccion",
             "limite_credito", "dias_credito", "estado"],
        ins_pre="""IF NVL(fn_rol_empleado(p_id_vendedor), 'X') <> 'VENDEDOR' THEN
  RAISE_APPLICATION_ERROR(-20030, 'El vendedor no existe o no tiene rol VENDEDOR.');
END IF;""",
        upd_pre="""IF NVL(fn_rol_empleado(p_id_vendedor), 'X') <> 'VENDEDOR' THEN
  RAISE_APPLICATION_ERROR(-20030, 'El vendedor no existe o no tiene rol VENDEDOR.');
END IF;""",
    ),
    dict(
        nombre="CATEGORIA", seq="SEQ_CATEGORIA", pk=["id_categoria"],
        desc="Categorias para agrupar los productos.",
        cols=[
            C("id_categoria", ID, desc="Identificador de la categoria."),
            C("nombre_categoria", "VARCHAR2(60)", desc="Nombre de la categoria."),
        ],
        uniques=[("uq_categoria_nombre", ["nombre_categoria"])],
        ins=["nombre_categoria"], upd=["nombre_categoria"],
    ),
    dict(
        nombre="PRODUCTO", seq="SEQ_PRODUCTO", pk=["id_producto"],
        desc="Catalogo de productos con precio y existencias.",
        cols=[
            C("id_producto", ID, desc="Identificador del producto."),
            C("id_categoria", ID, desc="Categoria del producto."),
            C("codigo", "VARCHAR2(20)", desc="Codigo interno."),
            C("nombre_producto", "VARCHAR2(100)", desc="Nombre del producto."),
            C("precio_unitario", DIN, desc="Precio de venta actual.", check="{c} > 0"),
            C("stock_actual", "NUMBER(10)", default="0", desc="Unidades disponibles.", check="{c} >= 0"),
            C("activo", "NUMBER(1)", default="1", desc="1 = a la venta, 0 = descontinuado.", enum=[0, 1]),
        ],
        fks=[("fk_producto_categoria", ["id_categoria"], "CATEGORIA", ["id_categoria"])],
        uniques=[("uq_producto_codigo", ["codigo"])],
        ins=["id_categoria", "codigo", "nombre_producto", "precio_unitario", "stock_actual", "activo"],
        upd=["id_categoria", "codigo", "nombre_producto", "precio_unitario", "activo"],
    ),
    dict(
        nombre="METODO_PAGO", seq="SEQ_METODO_PAGO", pk=["id_metodo_pago"],
        desc="Formas en que un cliente puede pagar.",
        cols=[
            C("id_metodo_pago", ID, desc="Identificador del metodo de pago."),
            C("nombre_metodo", "VARCHAR2(40)", desc="Efectivo, transferencia, cheque, SINPE Movil."),
        ],
        uniques=[("uq_metodo_pago_nombre", ["nombre_metodo"])],
        ins=["nombre_metodo"], upd=["nombre_metodo"],
    ),
    dict(
        nombre="FACTURA", seq="SEQ_FACTURA", pk=["id_factura"],
        desc="Venta a credito con monto, vencimiento y saldo pendiente.",
        cols=[
            C("id_factura", ID, desc="Identificador de la factura."),
            C("id_cliente", ID, desc="Cliente al que se factura."),
            C("id_empleado", ID, desc="Vendedor que hizo la venta."),
            C("numero_factura", "VARCHAR2(20)", desc="Numero visible de la factura."),
            C("fecha_emision", "DATE", default="SYSDATE", desc="Fecha en que se emitio."),
            C("fecha_vencimiento", "DATE", desc="Fecha limite de pago."),
            C("monto_total", DIN, default="0", desc="Total de la factura (suma del detalle).", check="{c} >= 0"),
            C("saldo_pendiente", DIN, default="0", desc="Lo que falta por pagar (total - notas - pagos).", check="{c} >= 0"),
            C("estado", "VARCHAR2(10)", default="'PENDIENTE'", desc="Estado de la factura.", enum=["PENDIENTE", "PAGADA", "ANULADA"]),
        ],
        fks=[("fk_factura_cliente", ["id_cliente"], "CLIENTE", ["id_cliente"]),
             ("fk_factura_empleado", ["id_empleado"], "EMPLEADO", ["id_empleado"])],
        uniques=[("uq_factura_numero", ["numero_factura"])],
        tchecks=[("ck_factura_fechas", "fecha_vencimiento >= fecha_emision"),
                 ("ck_factura_saldo", "saldo_pendiente <= monto_total")],
        extra_idx=[("idx_factura_vencimiento", ["fecha_vencimiento"]), ("idx_factura_estado", ["estado"])],
        ins=["id_cliente", "id_empleado", "fecha_emision"],
        ins_cols=["id_cliente", "id_empleado", "numero_factura", "fecha_emision", "fecha_vencimiento",
                  "monto_total", "saldo_pendiente", "estado"],
        ins_vals={"numero_factura": "fn_siguiente_numero_factura",
                  "fecha_emision": "NVL(p_fecha_emision, TRUNC(SYSDATE))",
                  "fecha_vencimiento": "fn_fecha_vencimiento(p_id_cliente, NVL(p_fecha_emision, TRUNC(SYSDATE)))",
                  "monto_total": "0", "saldo_pendiente": "0", "estado": "'PENDIENTE'"},
        upd=["id_empleado", "fecha_vencimiento"],
        ins_pre="""IF NVL(fn_estado_cliente(p_id_cliente), 'X') <> 'ACTIVO' THEN
  RAISE_APPLICATION_ERROR(-20040, 'Solo se puede facturar a clientes ACTIVOS.');
END IF;""",
        upd_pre="""IF NVL(fn_estado_factura(p_id_factura), 'X') = 'ANULADA' THEN
  RAISE_APPLICATION_ERROR(-20041, 'Una factura anulada no se puede modificar.');
END IF;""",
    ),
    dict(
        nombre="DETALLE_FACTURA", seq=None, pk=["id_factura", "id_producto"],
        desc="Productos vendidos en cada factura (tabla intermedia FACTURA-PRODUCTO).",
        cols=[
            C("id_factura", ID, desc="Factura a la que pertenece."),
            C("id_producto", ID, desc="Producto vendido."),
            C("cantidad", "NUMBER(10)", desc="Unidades vendidas.", check="{c} > 0"),
            C("precio_unitario", DIN, desc="Precio al momento de la venta.", check="{c} > 0"),
        ],
        fks=[("fk_detalle_factura", ["id_factura"], "FACTURA", ["id_factura"], "CASCADE"),
             ("fk_detalle_producto", ["id_producto"], "PRODUCTO", ["id_producto"])],
        ins=["id_factura", "id_producto", "cantidad", "precio_unitario"],
        ins_vals={"precio_unitario": "NVL(p_precio_unitario, fn_precio_producto(p_id_producto))"},
        upd=["cantidad", "precio_unitario"],
        ins_pre="""IF NVL(fn_estado_factura(p_id_factura), 'X') <> 'PENDIENTE' THEN
  RAISE_APPLICATION_ERROR(-20050, 'Solo se puede agregar detalle a facturas PENDIENTES.');
END IF;
IF fn_stock_producto(p_id_producto) < p_cantidad THEN
  RAISE_APPLICATION_ERROR(-20051, 'No hay existencias suficientes del producto.');
END IF;""",
        ins_post="sp_recalcular_factura(p_id_factura);",
        upd_decl="v_cantidad_actual detalle_factura.cantidad%TYPE;",
        upd_pre="""IF NVL(fn_estado_factura(p_id_factura), 'X') <> 'PENDIENTE' THEN
  RAISE_APPLICATION_ERROR(-20050, 'Solo se puede modificar el detalle de facturas PENDIENTES.');
END IF;
SELECT cantidad INTO v_cantidad_actual
  FROM detalle_factura
 WHERE id_factura = p_id_factura AND id_producto = p_id_producto;
IF p_cantidad > v_cantidad_actual
   AND fn_stock_producto(p_id_producto) < p_cantidad - v_cantidad_actual THEN
  RAISE_APPLICATION_ERROR(-20051, 'No hay existencias suficientes del producto.');
END IF;""",
        upd_post="sp_recalcular_factura(p_id_factura);",
        del_pre="""IF NVL(fn_estado_factura(p_id_factura), 'X') <> 'PENDIENTE' THEN
  RAISE_APPLICATION_ERROR(-20050, 'Solo se puede quitar detalle de facturas PENDIENTES.');
END IF;""",
        del_post="sp_recalcular_factura(p_id_factura);",
    ),
    dict(
        nombre="NOTA_CREDITO", seq="SEQ_NOTA_CREDITO", pk=["id_nota"],
        desc="Descuentos o devoluciones que reducen el saldo de una factura.",
        cols=[
            C("id_nota", ID, desc="Identificador de la nota."),
            C("id_factura", ID, desc="Factura afectada."),
            C("fecha_nota", "DATE", default="SYSDATE", desc="Fecha de la nota."),
            C("monto", DIN, desc="Monto que se descuenta.", check="{c} > 0"),
            C("motivo", "VARCHAR2(200)", desc="Razon de la nota de credito."),
        ],
        fks=[("fk_nota_factura", ["id_factura"], "FACTURA", ["id_factura"])],
        ins=["id_factura", "fecha_nota", "monto", "motivo"],
        upd=["monto", "motivo"],
        ins_pre="""IF NVL(fn_estado_factura(p_id_factura), 'X') = 'ANULADA' THEN
  RAISE_APPLICATION_ERROR(-20060, 'No se puede crear una nota para una factura anulada.');
END IF;
IF p_monto > fn_saldo_factura(p_id_factura) THEN
  RAISE_APPLICATION_ERROR(-20061, 'La nota de credito supera el saldo pendiente de la factura.');
END IF;""",
        ins_post="sp_recalcular_factura(p_id_factura);",
        upd_decl="v_id_factura nota_credito.id_factura%TYPE;\n  v_monto_actual nota_credito.monto%TYPE;",
        upd_pre="""SELECT id_factura, monto INTO v_id_factura, v_monto_actual
  FROM nota_credito WHERE id_nota = p_id_nota;
IF p_monto - v_monto_actual > fn_saldo_factura(v_id_factura) THEN
  RAISE_APPLICATION_ERROR(-20061, 'La nota de credito supera el saldo pendiente de la factura.');
END IF;""",
        upd_post="sp_recalcular_factura(v_id_factura);",
        del_decl="v_id_factura nota_credito.id_factura%TYPE;",
        del_pre="SELECT id_factura INTO v_id_factura FROM nota_credito WHERE id_nota = p_id_nota;",
        del_post="sp_recalcular_factura(v_id_factura);",
    ),
    dict(
        nombre="PAGO", seq="SEQ_PAGO", pk=["id_pago"],
        desc="Dinero recibido de un cliente.",
        cols=[
            C("id_pago", ID, desc="Identificador del pago."),
            C("id_cliente", ID, desc="Cliente que pago."),
            C("id_metodo_pago", ID, desc="Forma de pago usada."),
            C("fecha_pago", "DATE", default="SYSDATE", desc="Fecha en que se recibio el pago."),
            C("monto", DIN, desc="Monto recibido.", check="{c} > 0"),
            C("referencia", "VARCHAR2(50)", req=False, desc="Numero de transferencia, cheque o comprobante."),
            C("monto_sin_aplicar", DIN, default="0", desc="Parte del pago que aun no se reparte entre facturas.", check="{c} >= 0"),
        ],
        fks=[("fk_pago_cliente", ["id_cliente"], "CLIENTE", ["id_cliente"]),
             ("fk_pago_metodo", ["id_metodo_pago"], "METODO_PAGO", ["id_metodo_pago"])],
        tchecks=[("ck_pago_sin_aplicar", "monto_sin_aplicar <= monto")],
        extra_idx=[("idx_pago_fecha", ["fecha_pago"])],
        ins=["id_cliente", "id_metodo_pago", "fecha_pago", "monto", "referencia"],
        ins_cols=["id_cliente", "id_metodo_pago", "fecha_pago", "monto", "referencia", "monto_sin_aplicar"],
        ins_vals={"monto_sin_aplicar": "p_monto"},
        upd=["id_metodo_pago", "fecha_pago", "monto", "referencia"],
        upd_sets={"monto_sin_aplicar": "p_monto - v_aplicado"},
        upd_decl="v_aplicado pago.monto%TYPE;",
        upd_pre="""v_aplicado := fn_monto_aplicado_pago(p_id_pago);
IF p_monto < v_aplicado THEN
  RAISE_APPLICATION_ERROR(-20080, 'El monto no puede ser menor a lo que ya se aplico a facturas.');
END IF;""",
    ),
    dict(
        nombre="APLICACION_PAGO", seq="SEQ_APLICACION_PAGO", pk=["id_aplicacion"],
        desc="Reparto de un pago entre una o mas facturas (tabla intermedia PAGO-FACTURA).",
        cols=[
            C("id_aplicacion", ID, desc="Identificador de la aplicacion."),
            C("id_pago", ID, desc="Pago que se reparte."),
            C("id_factura", ID, desc="Factura que recibe el monto."),
            C("monto_aplicado", DIN, desc="Monto aplicado a la factura.", check="{c} > 0"),
            C("fecha_aplicacion", "DATE", default="SYSDATE", desc="Fecha en que se aplico."),
        ],
        fks=[("fk_aplicacion_pago", ["id_pago"], "PAGO", ["id_pago"]),
             ("fk_aplicacion_factura", ["id_factura"], "FACTURA", ["id_factura"])],
        ins=["id_pago", "id_factura", "monto_aplicado", "fecha_aplicacion"],
        upd=["monto_aplicado"],
        ins_decl="""v_cliente_pago pago.id_cliente%TYPE;
  v_cliente_factura factura.id_cliente%TYPE;
  v_sin_aplicar pago.monto_sin_aplicar%TYPE;
  v_saldo factura.saldo_pendiente%TYPE;
  v_estado factura.estado%TYPE;""",
        ins_pre="""SELECT id_cliente, monto_sin_aplicar INTO v_cliente_pago, v_sin_aplicar
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
END IF;""",
        ins_post="""UPDATE pago SET monto_sin_aplicar = monto_sin_aplicar - p_monto_aplicado
 WHERE id_pago = p_id_pago;
sp_recalcular_factura(p_id_factura);""",
        upd_decl="""v_id_pago aplicacion_pago.id_pago%TYPE;
  v_id_factura aplicacion_pago.id_factura%TYPE;
  v_actual aplicacion_pago.monto_aplicado%TYPE;
  v_sin_aplicar pago.monto_sin_aplicar%TYPE;
  v_saldo factura.saldo_pendiente%TYPE;""",
        upd_pre="""SELECT id_pago, id_factura, monto_aplicado INTO v_id_pago, v_id_factura, v_actual
  FROM aplicacion_pago WHERE id_aplicacion = p_id_aplicacion FOR UPDATE;
SELECT monto_sin_aplicar INTO v_sin_aplicar FROM pago WHERE id_pago = v_id_pago FOR UPDATE;
SELECT saldo_pendiente INTO v_saldo FROM factura WHERE id_factura = v_id_factura FOR UPDATE;
IF p_monto_aplicado - v_actual > v_sin_aplicar THEN
  RAISE_APPLICATION_ERROR(-20092, 'El monto supera lo que queda sin aplicar del pago.');
END IF;
IF p_monto_aplicado - v_actual > v_saldo THEN
  RAISE_APPLICATION_ERROR(-20093, 'El monto supera el saldo pendiente de la factura.');
END IF;""",
        upd_post="""UPDATE pago SET monto_sin_aplicar = monto_sin_aplicar - (p_monto_aplicado - v_actual)
 WHERE id_pago = v_id_pago;
sp_recalcular_factura(v_id_factura);""",
        del_decl="""v_id_pago aplicacion_pago.id_pago%TYPE;
  v_id_factura aplicacion_pago.id_factura%TYPE;
  v_actual aplicacion_pago.monto_aplicado%TYPE;""",
        del_pre="""SELECT id_pago, id_factura, monto_aplicado INTO v_id_pago, v_id_factura, v_actual
  FROM aplicacion_pago WHERE id_aplicacion = p_id_aplicacion FOR UPDATE;""",
        del_post="""UPDATE pago SET monto_sin_aplicar = monto_sin_aplicar + v_actual
 WHERE id_pago = v_id_pago;
sp_recalcular_factura(v_id_factura);""",
    ),
    dict(
        nombre="GESTION_COBRO", seq="SEQ_GESTION_COBRO", pk=["id_gestion"],
        desc="Historial de llamadas, visitas y promesas de pago a los clientes.",
        cols=[
            C("id_gestion", ID, desc="Identificador de la gestion."),
            C("id_cliente", ID, desc="Cliente contactado."),
            C("id_factura", ID, req=False, desc="Factura de la que se habla (opcional)."),
            C("id_empleado", ID, desc="Cobrador que hizo la gestion."),
            C("fecha_hora", "DATE", default="SYSDATE", desc="Fecha y hora del contacto."),
            C("tipo_gestion", "VARCHAR2(15)", desc="Medio usado.", enum=["LLAMADA", "CORREO", "VISITA", "WHATSAPP"]),
            C("resultado", "VARCHAR2(20)", desc="Resultado del contacto.",
              enum=["PROMESA_PAGO", "SIN_RESPUESTA", "PAGO_REALIZADO", "DISPUTA", "OTRO"]),
            C("fecha_promesa", "DATE", req=False, desc="Fecha prometida de pago."),
            C("observacion", "VARCHAR2(300)", req=False, desc="Notas de la gestion."),
        ],
        fks=[("fk_gestion_cliente", ["id_cliente"], "CLIENTE", ["id_cliente"]),
             ("fk_gestion_factura", ["id_factura"], "FACTURA", ["id_factura"]),
             ("fk_gestion_empleado", ["id_empleado"], "EMPLEADO", ["id_empleado"])],
        ins=["id_cliente", "id_factura", "id_empleado", "fecha_hora", "tipo_gestion", "resultado",
             "fecha_promesa", "observacion"],
        upd=["tipo_gestion", "resultado", "fecha_promesa", "observacion"],
        ins_pre="""IF p_resultado = 'PROMESA_PAGO' AND p_fecha_promesa IS NULL THEN
  RAISE_APPLICATION_ERROR(-20100, 'Una promesa de pago necesita la fecha prometida.');
END IF;""",
        upd_pre="""IF p_resultado = 'PROMESA_PAGO' AND p_fecha_promesa IS NULL THEN
  RAISE_APPLICATION_ERROR(-20100, 'Una promesa de pago necesita la fecha prometida.');
END IF;""",
    ),
    dict(
        nombre="BITACORA", seq="SEQ_BITACORA", pk=["id_bitacora"],
        desc="Registro de cambios hecho por los disparadores (sin llaves foraneas a proposito).",
        cols=[
            C("id_bitacora", ID, desc="Identificador del registro."),
            C("tabla_afectada", "VARCHAR2(30)", desc="Tabla que cambio."),
            C("operacion", "VARCHAR2(10)", desc="Tipo de cambio.", enum=["INSERT", "UPDATE", "DELETE"]),
            C("usuario_bd", "VARCHAR2(30)", desc="Usuario de la base de datos que hizo el cambio."),
            C("fecha_hora", "DATE", default="SYSDATE", desc="Momento del cambio."),
            C("detalle", "VARCHAR2(400)", req=False, desc="Resumen del cambio."),
        ],
        extra_idx=[("idx_bitacora_fecha", ["fecha_hora"])],
        ins=["tabla_afectada", "operacion", "detalle"],
        ins_cols=["tabla_afectada", "operacion", "usuario_bd", "fecha_hora", "detalle"],
        ins_vals={"usuario_bd": "SYS_CONTEXT('USERENV', 'SESSION_USER')", "fecha_hora": "SYSDATE"},
        upd=["detalle"],
        del_decl="v_fecha bitacora.fecha_hora%TYPE;",
        del_pre="""SELECT fecha_hora INTO v_fecha FROM bitacora WHERE id_bitacora = p_id_bitacora;
IF v_fecha > SYSDATE - 365 THEN
  RAISE_APPLICATION_ERROR(-20110, 'Solo se pueden borrar registros de bitacora con mas de 365 dias.');
END IF;""",
    ),
]

TABLAS_POR_NOMBRE = {t["nombre"]: t for t in TABLAS}


def col(t, nombre):
    for c in t["cols"]:
        if c["nombre"] == nombre:
            return c
    raise KeyError(nombre)
