"""Operaciones de negocio. Todas llaman procedimientos o funciones de Oracle; ninguna escribe SQL."""
from datetime import datetime
from decimal import Decimal

from .db import Salida, Sesion, a_decimal


def iniciar_sesion(sesion: Sesion, usuario: str, clave: str) -> dict:
    id_empleado, rol, nombre = sesion.ejecutar("SP_INICIAR_SESION", usuario, clave, Salida(int), Salida(str), Salida(str))
    return {"id": int(id_empleado), "rol": rol, "nombre": nombre, "usuario": usuario}


def cambiar_clave(sesion: Sesion, id_empleado: int, clave_actual: str, clave_nueva: str):
    sesion.ejecutar("SP_CAMBIAR_CLAVE_EMPLEADO", id_empleado, clave_actual, clave_nueva)


def facturar(sesion: Sesion, id_cliente: int, id_empleado: int, items, fecha_emision=None) -> int:
    """Crea la factura, agrega cada producto del detalle y la finaliza (valida limite de credito).
    items: lista de (id_producto, cantidad). Todo ocurre en una sola transaccion."""
    if not items:
        raise ValueError("La factura necesita al menos un producto.")
    (id_factura,) = sesion.ejecutar("PKG_FACTURA.SP_INSERTAR", id_cliente, id_empleado, fecha_emision, Salida(int))
    for id_producto, cantidad in items:
        sesion.ejecutar("PKG_DETALLE_FACTURA.SP_INSERTAR", id_factura, id_producto, cantidad, None)
    sesion.ejecutar("SP_FINALIZAR_FACTURA", id_factura)
    return int(id_factura)


def anular_factura(sesion: Sesion, id_factura: int, motivo: str):
    sesion.ejecutar("SP_ANULAR_FACTURA", id_factura, motivo)


def registrar_nota_credito(sesion: Sesion, id_factura: int, monto, motivo: str, id_empleado: int) -> int:
    (id_nota,) = sesion.ejecutar("SP_REGISTRAR_NOTA_CREDITO", id_factura, monto, motivo, id_empleado, Salida(int))
    return int(id_nota)


def registrar_pago(sesion: Sesion, id_cliente: int, id_metodo_pago: int, monto, referencia=None, fecha_pago=None) -> dict:
    """Registra el pago y lo aplica a las facturas mas antiguas."""
    id_pago, aplicado, sobrante = sesion.ejecutar(
        "SP_REGISTRAR_PAGO_Y_APLICAR", id_cliente, id_metodo_pago, fecha_pago, monto, referencia,
        Salida(int), Salida(float), Salida(float))
    return {"id_pago": int(id_pago), "aplicado": a_decimal(aplicado), "sobrante": a_decimal(sobrante)}


def aplicar_pago_pendiente(sesion: Sesion, id_pago: int) -> Decimal:
    (aplicado,) = sesion.ejecutar("SP_APLICAR_PAGO_AUTOMATICO", id_pago, Salida(float))
    return a_decimal(aplicado)


def registrar_gestion(sesion: Sesion, id_cliente: int, id_factura, id_empleado: int, tipo: str, resultado: str,
                      fecha_promesa=None, observacion=None) -> int:
    (id_gestion,) = sesion.ejecutar("SP_REGISTRAR_GESTION_COBRO", id_cliente, id_factura, id_empleado, tipo,
                                    resultado, fecha_promesa, observacion, Salida(int))
    return int(id_gestion)


def suspender_cliente(sesion: Sesion, id_cliente: int, motivo: str):
    sesion.ejecutar("SP_SUSPENDER_CLIENTE", id_cliente, motivo)


def activar_cliente(sesion: Sesion, id_cliente: int):
    sesion.ejecutar("SP_ACTIVAR_CLIENTE", id_cliente)


def cambiar_limite(sesion: Sesion, id_cliente: int, nuevo_limite, id_empleado: int):
    sesion.ejecutar("SP_CAMBIAR_LIMITE_CREDITO", id_cliente, nuevo_limite, id_empleado)


def reasignar_cartera(sesion: Sesion, origen: int, destino: int) -> int:
    (movidos,) = sesion.ejecutar("SP_REASIGNAR_CARTERA", origen, destino, Salida(int))
    return int(movidos)


def ajustar_stock(sesion: Sesion, id_producto: int, cantidad: int, motivo: str):
    sesion.ejecutar("SP_AJUSTAR_STOCK", id_producto, cantidad, motivo)


def actualizar_precio(sesion: Sesion, id_producto: int, nuevo_precio):
    sesion.ejecutar("SP_ACTUALIZAR_PRECIO_PRODUCTO", id_producto, nuevo_precio)


def inactivar_empleado(sesion: Sesion, id_empleado: int):
    sesion.ejecutar("SP_INACTIVAR_EMPLEADO", id_empleado)


def purgar_bitacora(sesion: Sesion, dias: int) -> int:
    (borrados,) = sesion.ejecutar("SP_PURGAR_BITACORA", dias, Salida(int))
    return int(borrados)


def saldo_cliente(sesion: Sesion, id_cliente: int) -> Decimal:
    return a_decimal(sesion.funcion("FN_SALDO_CLIENTE", float, id_cliente))


def credito_disponible(sesion: Sesion, id_cliente: int) -> Decimal:
    return a_decimal(sesion.funcion("FN_CREDITO_DISPONIBLE", float, id_cliente))


def es_moroso(sesion: Sesion, id_cliente: int) -> bool:
    return bool(sesion.funcion("FN_CLIENTE_ES_MOROSO", int, id_cliente))


# Reportes: clave -> (procedimiento, [(parametro, tipo, etiqueta)], titulo)
REPORTES = {
    "estado_cuenta": ("SP_REP_ESTADO_CUENTA", [("id_cliente", "int", "ID del cliente")], "Estado de cuenta"),
    "antiguedad": ("SP_REP_ANTIGUEDAD_SALDOS", [], "Antigüedad de saldos"),
    "morosos": ("SP_REP_CLIENTES_MOROSOS", [], "Clientes morosos"),
    "vencidas": ("SP_REP_FACTURAS_VENCIDAS", [], "Facturas vencidas"),
    "ventas_zona": ("SP_REP_VENTAS_POR_ZONA", [("desde", "date", "Desde (AAAA-MM-DD)"), ("hasta", "date", "Hasta (AAAA-MM-DD)")],
                    "Ventas por zona"),
    "ventas_vendedor": ("SP_REP_VENTAS_POR_VENDEDOR", [("desde", "date", "Desde (AAAA-MM-DD)"), ("hasta", "date", "Hasta (AAAA-MM-DD)")],
                        "Ventas por vendedor"),
    "inventario_bajo": ("SP_REP_INVENTARIO_BAJO", [("minimo", "int", "Existencias máximas a listar")], "Inventario bajo"),
    "pagos_sin_aplicar": ("SP_REP_PAGOS_SIN_APLICAR", [], "Pagos sin aplicar"),
    "gestiones": ("SP_REP_GESTIONES_CLIENTE", [("id_cliente", "int", "ID del cliente")], "Gestiones de cobro de un cliente"),
    "resumen": ("SP_REP_RESUMEN_CARTERA", [], "Resumen de cartera"),
    "credito": ("SP_REP_CREDITO_CLIENTES", [], "Crédito de clientes"),
    "detalle_factura": ("SP_REP_DETALLE_FACTURA", [("id_factura", "int", "ID de la factura")], "Detalle de una factura"),
}


def ejecutar_reporte(sesion: Sesion, clave: str, parametros: dict):
    procedimiento, params, _ = REPORTES[clave]
    args = []
    for nombre, tipo, _etiqueta in params:
        valor = parametros[nombre]
        if tipo == "date" and not isinstance(valor, datetime):
            valor = datetime.strptime(str(valor), "%Y-%m-%d")
        args.append(valor)
    return sesion.consultar(procedimiento, *args)
