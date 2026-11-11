"""Los parametros que Python envia a cada paquete deben coincidir con los que declara el script SQL."""
import os
import re

from lameseta.entidades import ENTIDADES

SQL = os.path.join(os.path.dirname(__file__), "..", "sql", "05_paquetes_crud.sql")


def _cantidad_params(spec, procedimiento):
    m = re.search(rf"PROCEDURE {procedimiento}(?:\((.*?)\))?;", spec, re.S)
    assert m, procedimiento
    cuerpo = m.group(1) or ""
    return len([x for x in cuerpo.split(",") if x.strip()])


def _spec(paquete):
    texto = open(SQL, encoding="utf-8").read()
    m = re.search(rf"CREATE OR REPLACE PACKAGE {paquete.lower()} AS(.*?)END {paquete.lower()};", texto, re.S)
    assert m, paquete
    return m.group(1)


def test_parametros_coinciden():
    for ent in ENTIDADES.values():
        spec = _spec(ent.paquete)
        out_id = 1 if ent.pk_auto else 0
        assert _cantidad_params(spec, "sp_insertar") == len(ent.insertar) + out_id, ent.clave
        assert _cantidad_params(spec, "sp_actualizar") == len(ent.pk) + len(ent.actualizar), ent.clave
        assert _cantidad_params(spec, "sp_eliminar") == len(ent.pk), ent.clave
        assert _cantidad_params(spec, "sp_obtener") == len(ent.pk) + 1, ent.clave
        assert _cantidad_params(spec, "sp_listar") == 1, ent.clave


def test_los_procedimientos_de_servicios_existen_en_sql():
    from lameseta import servicios
    texto = open(os.path.join(os.path.dirname(SQL), "06_procedimientos_negocio.sql"), encoding="utf-8").read().lower()
    for proc, _, _ in servicios.REPORTES.values():
        assert f"procedure {proc.lower()}(" in texto, proc
