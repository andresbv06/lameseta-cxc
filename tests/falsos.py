"""Objetos falsos que imitan la conexion de python-oracledb, para probar sin una base Oracle."""


class VarFalsa:
    def __init__(self, tipo):
        self.tipo = tipo
        self.valor = None

    def getvalue(self):
        return self.valor


class CursorFalso:
    def __init__(self, conexion):
        self.conexion = conexion
        self.description = None
        self._filas = []
        self.cerrado = False

    def var(self, tipo):
        v = VarFalsa(tipo)
        self.conexion.vars_creadas.append(v)
        return v

    def callproc(self, nombre, params):
        self.conexion.llamadas.append(("proc", nombre, list(params)))
        if self.conexion.error_en and nombre == self.conexion.error_en:
            raise self.conexion.error
        salidas = self.conexion.salidas.get(nombre, [])
        i = 0
        for p in params:
            if isinstance(p, VarFalsa):
                p.valor = salidas[i] if i < len(salidas) else 1
                i += 1
            elif isinstance(p, CursorFalso):
                p.description = [(c.upper(),) for c in self.conexion.columnas]
                p._filas = list(self.conexion.filas)

    def callfunc(self, nombre, tipo, params):
        self.conexion.llamadas.append(("func", nombre, list(params)))
        return self.conexion.retorno_funcion

    def fetchall(self):
        return self._filas

    def close(self):
        self.cerrado = True


class ConexionFalsa:
    def __init__(self):
        self.llamadas = []
        self.vars_creadas = []
        self.salidas = {}
        self.columnas = ["id", "nombre"]
        self.filas = [(1, "Uno")]
        self.retorno_funcion = 0
        self.error_en = None
        self.error = None
        self.commits = 0
        self.rollbacks = 0
        self.current_schema = None

    def cursor(self):
        return CursorFalso(self)

    def commit(self):
        self.commits += 1

    def rollback(self):
        self.rollbacks += 1


class PoolFalso:
    def __init__(self, conexion):
        self.conexion = conexion
        self.liberadas = 0

    def acquire(self):
        return self.conexion

    def release(self, c):
        self.liberadas += 1

    def close(self):
        pass
