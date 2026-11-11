"""Conexion a Oracle con python-oracledb (modo Thin).
Regla del proyecto: aqui NO hay consultas SQL. Todo se hace llamando procedimientos, funciones y paquetes."""
import re
from contextlib import contextmanager
from decimal import Decimal

import oracledb

from .config import Configuracion

oracledb.defaults.fetch_decimals = True  # los NUMBER llegan como Decimal (dinero sin perder precision)


class ErrorNegocio(Exception):
    """Error pensado para el usuario: viene de un RAISE_APPLICATION_ERROR (ORA-20xxx) de la base de datos."""

    def __init__(self, mensaje: str, codigo: int = 0):
        super().__init__(mensaje)
        self.codigo = codigo


class ErrorBD(Exception):
    """Cualquier otro error de Oracle."""

    def __init__(self, mensaje: str, codigo: int = 0):
        super().__init__(mensaje)
        self.codigo = codigo


_PATRON_ORA = re.compile(r"ORA-(\d{5}):\s*(.*)")


def traducir_error(error: Exception) -> Exception:
    """Convierte oracledb.DatabaseError en ErrorNegocio (ORA-20xxx) o ErrorBD."""
    texto = str(error)
    m = _PATRON_ORA.search(texto)
    if not m:
        return ErrorBD(texto.strip() or "Error desconocido de la base de datos.")
    codigo, mensaje = int(m.group(1)), m.group(2).strip()
    if 20000 <= codigo <= 20999:
        return ErrorNegocio(mensaje, codigo)
    return ErrorBD(f"ORA-{codigo:05d}: {mensaje}", codigo)


class Salida:
    """Marca un parametro OUT. Tipos: int, str, float."""

    def __init__(self, tipo=int):
        self.tipo = tipo


class Sesion:
    """Una conexion con una transaccion abierta. Se obtiene con BaseDatos.sesion()."""

    def __init__(self, conexion):
        self._conexion = conexion

    def ejecutar(self, nombre: str, *argumentos):
        """Llama un procedimiento. Devuelve la lista de valores de los parametros Salida (en orden)."""
        cursor = self._conexion.cursor()
        try:
            binds, salidas = [], []
            for a in argumentos:
                if isinstance(a, Salida):
                    var = cursor.var(a.tipo)
                    binds.append(var)
                    salidas.append(var)
                else:
                    binds.append(a)
            cursor.callproc(nombre, binds)
            return [v.getvalue() for v in salidas]
        finally:
            cursor.close()

    def consultar(self, nombre: str, *argumentos):
        """Llama un procedimiento cuyo ultimo parametro es un SYS_REFCURSOR. Devuelve (columnas, filas)."""
        cursor = self._conexion.cursor()
        referencia = self._conexion.cursor()
        try:
            cursor.callproc(nombre, [*argumentos, referencia])
            columnas = [d[0].lower() for d in referencia.description]
            filas = referencia.fetchall()
            return columnas, filas
        finally:
            referencia.close()
            cursor.close()

    def funcion(self, nombre: str, tipo_retorno, *argumentos):
        """Llama una funcion almacenada y devuelve su resultado."""
        cursor = self._conexion.cursor()
        try:
            return cursor.callfunc(nombre, tipo_retorno, list(argumentos))
        finally:
            cursor.close()


class BaseDatos:
    def __init__(self, configuracion: Configuracion):
        self.configuracion = configuracion
        self._pool = None

    def abrir(self):
        c = self.configuracion
        try:
            self._pool = oracledb.create_pool(user=c.usuario, password=c.clave, dsn=c.dsn, min=1, max=4, increment=1)
        except oracledb.DatabaseError as e:
            raise traducir_error(e) from e

    def cerrar(self):
        if self._pool is not None:
            self._pool.close()
            self._pool = None

    @contextmanager
    def sesion(self):
        """Abre una sesion. Si todo sale bien hace COMMIT; si algo falla hace ROLLBACK."""
        if self._pool is None:
            self.abrir()
        conexion = self._pool.acquire()
        try:
            conexion.current_schema = self.configuracion.esquema
            yield Sesion(conexion)
            conexion.commit()
        except oracledb.DatabaseError as e:
            conexion.rollback()
            raise traducir_error(e) from e
        except Exception:
            conexion.rollback()
            raise
        finally:
            self._pool.release(conexion)


def a_decimal(valor) -> Decimal:
    return valor if isinstance(valor, Decimal) else Decimal(str(valor or 0))
