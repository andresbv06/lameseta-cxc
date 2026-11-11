from datetime import datetime
from decimal import Decimal

import pytest

import lameseta.db as db
from lameseta import crud, servicios
from lameseta.config import ErrorConfiguracion, leer_configuracion
from lameseta.entidades import ENTIDADES
from tests.falsos import ConexionFalsa, PoolFalso


def _sesion(conn=None):
    conn = conn or ConexionFalsa()
    return db.Sesion(conn), conn


def test_ejecutar_devuelve_salidas():
    s, c = _sesion()
    c.salidas["PKG_ZONA.SP_INSERTAR"] = [42]
    r = s.ejecutar("PKG_ZONA.SP_INSERTAR", "Norte", "Heredia", db.Salida(int))
    assert r == [42]
    assert c.llamadas[0][1] == "PKG_ZONA.SP_INSERTAR"


def test_consultar_devuelve_columnas_y_filas():
    s, c = _sesion()
    columnas, filas = s.consultar("PKG_ZONA.SP_LISTAR")
    assert columnas == ["id", "nombre"] and filas == [(1, "Uno")]


def test_funcion():
    s, c = _sesion()
    c.retorno_funcion = 12.5
    assert s.funcion("FN_SALDO_CLIENTE", float, 3) == 12.5


def test_traducir_error_negocio_y_bd():
    class E(Exception):
        pass
    e1 = db.traducir_error(E("ORA-20051: No hay existencias suficientes del producto.\nORA-06512: en linea 3"))
    assert isinstance(e1, db.ErrorNegocio) and e1.codigo == 20051 and "existencias" in str(e1)
    e2 = db.traducir_error(E("ORA-00942: table or view does not exist"))
    assert isinstance(e2, db.ErrorBD) and e2.codigo == 942


def test_sesion_hace_commit_o_rollback(monkeypatch):
    conn = ConexionFalsa()
    bd = db.BaseDatos(leer_configuracion({"LAMESETA_DB_USER": "u", "LAMESETA_DB_PASSWORD": "p"}))
    bd._pool = PoolFalso(conn)
    with bd.sesion():
        pass
    assert conn.commits == 1 and conn.rollbacks == 0 and conn.current_schema == "LAMESETA"
    with pytest.raises(ValueError):
        with bd.sesion():
            raise ValueError("x")
    assert conn.rollbacks == 1


def test_sesion_traduce_errores_oracle():
    conn = ConexionFalsa()
    bd = db.BaseDatos(leer_configuracion({"LAMESETA_DB_USER": "u", "LAMESETA_DB_PASSWORD": "p"}))
    bd._pool = PoolFalso(conn)
    with pytest.raises(db.ErrorNegocio):
        with bd.sesion():
            raise db.oracledb.DatabaseError("ORA-20132: La factura supera el limite de credito del cliente.")
    assert conn.rollbacks == 1


def test_config_exige_usuario_y_clave_y_oculta_la_clave():
    with pytest.raises(ErrorConfiguracion):
        leer_configuracion({})
    cfg = leer_configuracion({"LAMESETA_DB_USER": "u", "LAMESETA_DB_PASSWORD": "secreta"})
    assert "secreta" not in repr(cfg) and cfg.dsn == "localhost:1521/ORCLPDB"


def test_crud_insertar_usa_el_paquete_y_el_id_de_salida():
    s, c = _sesion()
    c.salidas["PKG_ZONA.SP_INSERTAR"] = [9]
    nuevo = crud.insertar(s, ENTIDADES["zona"], {"nombre_zona": "Sur", "provincia": "Cartago"})
    assert nuevo == 9
    _, nombre, params = c.llamadas[0]
    assert nombre == "PKG_ZONA.SP_INSERTAR" and params[:2] == ["Sur", "Cartago"]


def test_crud_actualizar_eliminar_obtener_listar():
    s, c = _sesion()
    ent = ENTIDADES["cliente"]
    crud.actualizar(s, ent, {"id_cliente": "5"}, {k.nombre: None for k in ent.actualizar})
    crud.eliminar(s, ent, {"id_cliente": 5})
    crud.obtener(s, ent, {"id_cliente": 5})
    crud.listar(s, ent)
    nombres = [x[1] for x in c.llamadas]
    assert nombres == ["PKG_CLIENTE.SP_ACTUALIZAR", "PKG_CLIENTE.SP_ELIMINAR", "PKG_CLIENTE.SP_OBTENER", "PKG_CLIENTE.SP_LISTAR"]
    assert c.llamadas[0][2][0] == 5


def test_crud_detalle_factura_con_llave_compuesta():
    s, c = _sesion()
    ent = ENTIDADES["detalle_factura"]
    assert crud.insertar(s, ent, {"id_factura": 1, "id_producto": 2, "cantidad": 3, "precio_unitario": None}) is None
    crud.eliminar(s, ent, {"id_factura": 1, "id_producto": 2})
    assert c.llamadas[1][2] == [1, 2]


def test_convertir_tipos():
    from lameseta.tipos import Campo
    assert crud.convertir(Campo("a", "A", "dec"), "12,5") == Decimal("12.5")
    assert crud.convertir(Campo("a", "A", "bool"), "s") == 1
    assert crud.convertir(Campo("a", "A", "date"), "2026-11-10") == datetime(2026, 11, 10)
    assert crud.convertir(Campo("a", "A", "str"), "") is None


def test_facturar_llama_en_orden_y_finaliza():
    s, c = _sesion()
    c.salidas["PKG_FACTURA.SP_INSERTAR"] = [77]
    assert servicios.facturar(s, 1, 2, [(10, 3), (11, 1)]) == 77
    nombres = [x[1] for x in c.llamadas]
    assert nombres == ["PKG_FACTURA.SP_INSERTAR", "PKG_DETALLE_FACTURA.SP_INSERTAR", "PKG_DETALLE_FACTURA.SP_INSERTAR",
                       "SP_FINALIZAR_FACTURA"]
    assert c.llamadas[1][2] == [77, 10, 3, None]


def test_facturar_sin_productos_falla():
    s, _ = _sesion()
    with pytest.raises(ValueError):
        servicios.facturar(s, 1, 2, [])


def test_registrar_pago_devuelve_montos_decimales():
    s, c = _sesion()
    c.salidas["SP_REGISTRAR_PAGO_Y_APLICAR"] = [5, 100.5, 49.5]
    r = servicios.registrar_pago(s, 1, 2, Decimal("150"))
    assert r == {"id_pago": 5, "aplicado": Decimal("100.5"), "sobrante": Decimal("49.5")}


def test_iniciar_sesion():
    s, c = _sesion()
    c.salidas["SP_INICIAR_SESION"] = [3, "COBRADOR", "Jorge Vargas"]
    assert servicios.iniciar_sesion(s, "jvargas", "x")["rol"] == "COBRADOR"


def test_reporte_con_fechas():
    s, c = _sesion()
    servicios.ejecutar_reporte(s, "ventas_zona", {"desde": "2026-01-01", "hasta": "2026-12-31"})
    assert c.llamadas[0][1] == "SP_REP_VENTAS_POR_ZONA"
    assert c.llamadas[0][2][0] == datetime(2026, 1, 1)
