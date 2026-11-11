"""Menus de la aplicacion. Cada rol ve solo lo que le corresponde."""
import os
from datetime import datetime

from . import crud, servicios
from .consola import (exportar_csv, mostrar_tabla, pedir, pedir_campo, pedir_decimal, pedir_entero, pedir_fecha,
                      pedir_si_no)
from .db import BaseDatos, ErrorBD, ErrorNegocio
from .entidades import ENTIDADES

# Que entidades puede administrar cada rol (CRUD completo) y cuales solo consultar.
CRUD_COMPLETO = {
    "ADMIN": list(ENTIDADES.keys()),
    "VENDEDOR": [],
    "COBRADOR": ["gestion_cobro"],
}
SOLO_LECTURA = {
    "ADMIN": [],
    "VENDEDOR": ["cliente", "producto", "categoria", "zona"],
    "COBRADOR": ["cliente", "factura", "pago", "aplicacion_pago", "metodo_pago"],
}
REPORTES_ROL = {
    "ADMIN": list(servicios.REPORTES.keys()),
    "VENDEDOR": ["estado_cuenta", "detalle_factura", "inventario_bajo", "ventas_vendedor", "credito"],
    "COBRADOR": ["estado_cuenta", "antiguedad", "morosos", "vencidas", "pagos_sin_aplicar", "gestiones", "resumen",
                 "credito", "detalle_factura"],
}


def elegir(titulo: str, opciones: list):
    """Muestra una lista numerada y devuelve el indice elegido (o None para volver)."""
    print(f"\n--- {titulo} ---")
    for i, (texto, _) in enumerate(opciones, 1):
        print(f"  {i}. {texto}")
    print("  0. Volver / Salir")
    while True:
        bruto = pedir("Opción: ")
        if bruto == "0":
            return None
        if bruto.isdigit() and 1 <= int(bruto) <= len(opciones):
            return int(bruto) - 1
        print("  Opción no válida.")


def con_manejo_errores(funcion):
    def envoltura(*args, **kwargs):
        try:
            return funcion(*args, **kwargs)
        except ErrorNegocio as e:
            print(f"\n  No se pudo completar: {e}")
        except ErrorBD as e:
            print(f"\n  Error de base de datos: {e}")
        except ValueError as e:
            print(f"\n  Dato inválido: {e}")
    return envoltura


# ---------------------------------------------------------------- CRUD generico
def pedir_llave(ent):
    return {c.nombre: pedir_campo(c) for c in ent.pk}


@con_manejo_errores
def accion_listar(bd: BaseDatos, ent):
    with bd.sesion() as s:
        columnas, filas = crud.listar(s, ent)
    mostrar_tabla(columnas, filas, ent.titulo)


@con_manejo_errores
def accion_obtener(bd: BaseDatos, ent):
    llave = pedir_llave(ent)
    with bd.sesion() as s:
        columnas, filas = crud.obtener(s, ent, llave)
    mostrar_tabla(columnas, filas, ent.titulo)


@con_manejo_errores
def accion_insertar(bd: BaseDatos, ent):
    datos = {c.nombre: pedir_campo(c) for c in ent.insertar}
    with bd.sesion() as s:
        nuevo = crud.insertar(s, ent, datos)
    print(f"\n  Registro creado{f' con ID {nuevo}' if nuevo else ''}.")


@con_manejo_errores
def accion_actualizar(bd: BaseDatos, ent):
    llave = pedir_llave(ent)
    with bd.sesion() as s:
        columnas, filas = crud.obtener(s, ent, llave)
        if not filas:
            print("  No existe ese registro.")
            return
        actuales = dict(zip(columnas, filas[0]))
        datos = {c.nombre: pedir_campo(c, actuales.get(c.nombre)) for c in ent.actualizar}
        crud.actualizar(s, ent, llave, datos)
    print("\n  Registro actualizado.")


@con_manejo_errores
def accion_eliminar(bd: BaseDatos, ent):
    llave = pedir_llave(ent)
    if not pedir_si_no("¿Seguro que desea eliminarlo?"):
        return
    with bd.sesion() as s:
        crud.eliminar(s, ent, llave)
    print("\n  Registro eliminado.")


def menu_entidad(bd: BaseDatos, ent, solo_lectura: bool):
    opciones = [("Listar", accion_listar), ("Buscar por ID", accion_obtener)]
    if not solo_lectura:
        opciones += [("Agregar", accion_insertar), ("Modificar", accion_actualizar), ("Eliminar", accion_eliminar)]
    while True:
        i = elegir(ent.titulo, opciones)
        if i is None:
            return
        opciones[i][1](bd, ent)


def menu_catalogos(bd: BaseDatos, usuario: dict):
    completos = CRUD_COMPLETO[usuario["rol"]]
    lectura = SOLO_LECTURA[usuario["rol"]]
    claves = [k for k in ENTIDADES if k in completos or k in lectura]
    opciones = [(ENTIDADES[k].titulo + ("" if k in completos else " (consulta)"), k) for k in claves]
    while True:
        i = elegir("Datos del sistema", opciones)
        if i is None:
            return
        clave = opciones[i][1]
        menu_entidad(bd, ENTIDADES[clave], solo_lectura=clave not in completos)


# ---------------------------------------------------------------- operaciones de negocio
@con_manejo_errores
def accion_facturar(bd: BaseDatos, usuario: dict):
    id_cliente = pedir_entero("ID del cliente", 1)
    items = []
    while True:
        id_producto = pedir_entero("ID del producto", 1)
        cantidad = pedir_entero("Cantidad", 1)
        items.append((id_producto, cantidad))
        if not pedir_si_no("¿Agregar otro producto?"):
            break
    with bd.sesion() as s:
        id_factura = servicios.facturar(s, id_cliente, usuario["id"], items)
        columnas, filas = s.consultar("SP_REP_DETALLE_FACTURA", id_factura)
    print(f"\n  Factura creada con ID {id_factura}.")
    mostrar_tabla(columnas, filas, "Detalle")


@con_manejo_errores
def accion_pago(bd: BaseDatos, usuario: dict):
    id_cliente = pedir_entero("ID del cliente", 1)
    id_metodo = pedir_entero("ID del método de pago", 1)
    monto = pedir_decimal("Monto recibido")
    referencia = pedir("Referencia (opcional): ") or None
    with bd.sesion() as s:
        r = servicios.registrar_pago(s, id_cliente, id_metodo, monto, referencia)
    print(f"\n  Pago {r['id_pago']} registrado. Aplicado a facturas: {r['aplicado']:,.2f}. Sin aplicar: {r['sobrante']:,.2f}.")


@con_manejo_errores
def accion_gestion(bd: BaseDatos, usuario: dict):
    id_cliente = pedir_entero("ID del cliente", 1)
    factura = pedir("ID de la factura (opcional): ")
    tipo = pedir("Tipo [LLAMADA/CORREO/VISITA/WHATSAPP]: ").upper()
    resultado = pedir("Resultado [PROMESA_PAGO/SIN_RESPUESTA/PAGO_REALIZADO/DISPUTA/OTRO]: ").upper()
    promesa = pedir_fecha("Fecha de promesa", opcional=True) if resultado == "PROMESA_PAGO" else None
    obs = pedir("Observación (opcional): ") or None
    with bd.sesion() as s:
        nuevo = servicios.registrar_gestion(s, id_cliente, int(factura) if factura else None, usuario["id"],
                                            tipo, resultado, promesa, obs)
    print(f"\n  Gestión {nuevo} registrada.")


@con_manejo_errores
def accion_saldo(bd: BaseDatos, usuario: dict):
    id_cliente = pedir_entero("ID del cliente", 1)
    with bd.sesion() as s:
        saldo = servicios.saldo_cliente(s, id_cliente)
        disponible = servicios.credito_disponible(s, id_cliente)
        moroso = servicios.es_moroso(s, id_cliente)
    print(f"\n  Saldo: {saldo:,.2f} | Crédito disponible: {disponible:,.2f} | Moroso: {'sí' if moroso else 'no'}")


@con_manejo_errores
def accion_anular(bd, usuario):
    id_factura = pedir_entero("ID de la factura", 1)
    motivo = pedir("Motivo: ")
    with bd.sesion() as s:
        servicios.anular_factura(s, id_factura, motivo)
    print("\n  Factura anulada.")


@con_manejo_errores
def accion_nota(bd, usuario):
    id_factura = pedir_entero("ID de la factura", 1)
    monto = pedir_decimal("Monto de la nota")
    motivo = pedir("Motivo: ")
    with bd.sesion() as s:
        n = servicios.registrar_nota_credito(s, id_factura, monto, motivo, usuario["id"])
    print(f"\n  Nota de crédito {n} registrada.")


@con_manejo_errores
def accion_suspender(bd, usuario):
    id_cliente = pedir_entero("ID del cliente", 1)
    if pedir_si_no("¿Suspender? (n = activar de nuevo)"):
        with bd.sesion() as s:
            servicios.suspender_cliente(s, id_cliente, pedir("Motivo: "))
        print("\n  Cliente suspendido.")
    else:
        with bd.sesion() as s:
            servicios.activar_cliente(s, id_cliente)
        print("\n  Cliente activado.")


@con_manejo_errores
def accion_limite(bd, usuario):
    id_cliente = pedir_entero("ID del cliente", 1)
    limite = pedir_decimal("Nuevo límite de crédito")
    with bd.sesion() as s:
        servicios.cambiar_limite(s, id_cliente, limite, usuario["id"])
    print("\n  Límite actualizado.")


@con_manejo_errores
def accion_stock(bd, usuario):
    id_producto = pedir_entero("ID del producto", 1)
    cantidad = pedir_entero("Cantidad a sumar (negativa para restar)")
    with bd.sesion() as s:
        servicios.ajustar_stock(s, id_producto, cantidad, pedir("Motivo: "))
    print("\n  Existencias ajustadas.")


@con_manejo_errores
def accion_precio(bd, usuario):
    id_producto = pedir_entero("ID del producto", 1)
    precio = pedir_decimal("Nuevo precio")
    with bd.sesion() as s:
        servicios.actualizar_precio(s, id_producto, precio)
    print("\n  Precio actualizado.")


@con_manejo_errores
def accion_reasignar(bd, usuario):
    origen = pedir_entero("ID del vendedor actual", 1)
    destino = pedir_entero("ID del vendedor nuevo", 1)
    with bd.sesion() as s:
        n = servicios.reasignar_cartera(s, origen, destino)
    print(f"\n  Clientes reasignados: {n}.")


@con_manejo_errores
def accion_purgar(bd, usuario):
    dias = pedir_entero("Borrar registros de bitácora con más de cuántos días (mínimo 365)", 365)
    with bd.sesion() as s:
        n = servicios.purgar_bitacora(s, dias)
    print(f"\n  Registros borrados: {n}.")


@con_manejo_errores
def accion_cambiar_clave(bd, usuario):
    import getpass
    actual = getpass.getpass("Clave actual: ")
    nueva = getpass.getpass("Clave nueva: ")
    with bd.sesion() as s:
        servicios.cambiar_clave(s, usuario["id"], actual, nueva)
    print("\n  Clave cambiada.")


@con_manejo_errores
def accion_reporte(bd: BaseDatos, clave: str):
    _proc, params, titulo = servicios.REPORTES[clave]
    valores = {}
    for nombre, tipo, etiqueta in params:
        valores[nombre] = pedir_fecha(etiqueta.split(" (")[0]) if tipo == "date" else pedir_entero(etiqueta)
    with bd.sesion() as s:
        columnas, filas = servicios.ejecutar_reporte(s, clave, valores)
    mostrar_tabla(columnas, filas, titulo)
    if filas and pedir_si_no("¿Exportar a CSV?"):
        ruta = f"reporte_{clave}_{datetime.now():%Y%m%d_%H%M%S}.csv"
        exportar_csv(columnas, filas, os.path.abspath(ruta))
        print(f"  Archivo guardado: {os.path.abspath(ruta)}")


def menu_reportes(bd: BaseDatos, usuario: dict):
    claves = REPORTES_ROL[usuario["rol"]]
    opciones = [(servicios.REPORTES[k][2], k) for k in claves]
    while True:
        i = elegir("Reportes", opciones)
        if i is None:
            return
        accion_reporte(bd, opciones[i][1])


def operaciones_por_rol(rol: str):
    comunes = [("Consultar saldo y crédito de un cliente", accion_saldo), ("Cambiar mi clave", accion_cambiar_clave)]
    if rol == "VENDEDOR":
        return [("Crear factura de crédito", accion_facturar)] + comunes
    if rol == "COBRADOR":
        return [("Registrar pago y aplicarlo", accion_pago), ("Registrar gestión de cobro", accion_gestion)] + comunes
    return [("Crear factura de crédito", accion_facturar), ("Registrar pago y aplicarlo", accion_pago),
            ("Registrar gestión de cobro", accion_gestion), ("Anular factura", accion_anular),
            ("Registrar nota de crédito", accion_nota), ("Suspender o activar cliente", accion_suspender),
            ("Cambiar límite de crédito", accion_limite), ("Ajustar existencias", accion_stock),
            ("Cambiar precio de un producto", accion_precio), ("Reasignar cartera de vendedor", accion_reasignar),
            ("Purgar bitácora antigua", accion_purgar)] + comunes


def menu_principal(bd: BaseDatos, usuario: dict):
    print(f"\nBienvenido/a {usuario['nombre']} ({usuario['rol']})")
    operaciones = operaciones_por_rol(usuario["rol"])
    principal = [("Operaciones", "op"), ("Datos del sistema", "datos"), ("Reportes", "rep")]
    while True:
        i = elegir("Menú principal", principal)
        if i is None:
            return
        destino = principal[i][1]
        if destino == "datos":
            menu_catalogos(bd, usuario)
        elif destino == "rep":
            menu_reportes(bd, usuario)
        else:
            while True:
                j = elegir("Operaciones", operaciones)
                if j is None:
                    break
                operaciones[j][1](bd, usuario)
