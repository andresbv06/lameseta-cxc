"""CRUD generico de las 13 tablas. Cada operacion llama al paquete PKG_<TABLA> de la base de datos."""
from datetime import date, datetime
from decimal import Decimal

from .db import Salida, Sesion
from .tipos import Campo, Entidad


def convertir(campo: Campo, valor):
    """Prepara un valor de Python para enviarlo a Oracle."""
    if valor is None or valor == "":
        return None
    if campo.tipo == "bool":
        return 1 if valor in (1, True, "1", "s", "S", "si", "SI", "Si") else 0
    if campo.tipo == "int":
        return int(valor)
    if campo.tipo == "dec":
        return Decimal(str(valor).replace(",", "."))
    if campo.tipo == "date":
        if isinstance(valor, datetime):
            return valor
        if isinstance(valor, date):
            return datetime(valor.year, valor.month, valor.day)
        return datetime.strptime(str(valor), "%Y-%m-%d")
    return str(valor)


def _valores(campos, datos: dict):
    return [convertir(c, datos.get(c.nombre)) for c in campos]


def insertar(sesion: Sesion, ent: Entidad, datos: dict):
    """Inserta una fila. Devuelve el id nuevo (o None si la llave es compuesta)."""
    argumentos = _valores(ent.insertar, datos)
    if ent.pk_auto:
        argumentos.append(Salida(int))
    salidas = sesion.ejecutar(f"{ent.paquete}.SP_INSERTAR", *argumentos)
    return int(salidas[0]) if salidas else None


def actualizar(sesion: Sesion, ent: Entidad, llave: dict, datos: dict):
    argumentos = _valores(ent.pk, llave) + _valores(ent.actualizar, datos)
    sesion.ejecutar(f"{ent.paquete}.SP_ACTUALIZAR", *argumentos)


def eliminar(sesion: Sesion, ent: Entidad, llave: dict):
    sesion.ejecutar(f"{ent.paquete}.SP_ELIMINAR", *_valores(ent.pk, llave))


def obtener(sesion: Sesion, ent: Entidad, llave: dict):
    return sesion.consultar(f"{ent.paquete}.SP_OBTENER", *_valores(ent.pk, llave))


def listar(sesion: Sesion, ent: Entidad):
    return sesion.consultar(f"{ent.paquete}.SP_LISTAR")
