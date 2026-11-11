"""Revision estatica de nombres: tablas, vistas y columnas usadas en los scripts existen en el modelo.
Uso: python tools/chequear_nombres.py"""
import os
import re
import sys

sys.path.insert(0, os.path.dirname(__file__))
from modelo import TABLAS  # noqa: E402

RAIZ = os.environ.get("SQL_DIR") or os.path.join(os.path.dirname(__file__), "..", "sql")
ARCHIVOS = ["02_funciones", "03_procedimientos_base", "04_vistas", "05_paquetes_crud", "06_procedimientos_negocio",
            "07_triggers", "09_datos_prueba", "10_verificacion"]

TABLAS_COLS = {t["nombre"].lower(): [c["nombre"] for c in t["cols"]] for t in TABLAS}

PALABRAS = set("""select from where and or not null is in between like as on join left right inner outer group by order having
asc desc case when then else end insert into values update set delete returning for exists distinct count sum min max nvl lower
upper trunc sysdate least greatest to_char to_date substr length lpad rawtohex standard_hash sys_context fn_ decode user
rownum dual union all if elsif loop exit return begin declare exception raise_application_error dbms_output put_line
number varchar2 date boolean true false sqlerrm sqlcode escape nvl2 coalesce row_number over partition regexp_like
""".split())


def limpiar(t):
    t = re.sub(r"--[^\n]*", "", t)
    t = re.sub(r"'(?:[^']|'')*'", "''", t)
    return t


def columnas_vista(sql_select):
    """Devuelve los nombres de salida de una lista SELECT (alias AS o ultimo identificador)."""
    m = re.search(r"SELECT(.*?)\bFROM\b", sql_select, re.I | re.S)
    if not m:
        return []
    lista, nivel, actual, items = m.group(1), 0, "", []
    for ch in lista:
        if ch == "(":
            nivel += 1
        elif ch == ")":
            nivel -= 1
        if ch == "," and nivel == 0:
            items.append(actual)
            actual = ""
        else:
            actual += ch
    items.append(actual)
    cols = []
    for it in items:
        it = it.strip()
        a = re.search(r"\bAS\s+(\w+)\s*$", it, re.I)
        if a:
            cols.append(a.group(1).lower())
        else:
            ult = re.findall(r"(\w+)\s*$", it)
            if ult:
                cols.append(ult[0].lower())
    return cols


def main():
    textos = {a: limpiar(open(os.path.join(RAIZ, a + ".sql"), encoding="utf-8").read()) for a in ARCHIVOS}
    vistas = {}
    for m in re.finditer(r"CREATE OR REPLACE VIEW (\w+) AS(.*?);", textos["04_vistas"], re.I | re.S):
        vistas[m.group(1).lower()] = columnas_vista(m.group(2))
    objetos = dict(TABLAS_COLS)
    objetos.update(vistas)
    problemas = 0

    for a, t in textos.items():
        # tabla.col%TYPE
        for m in re.finditer(r"\b(\w+)\.(\w+)%TYPE", t, re.I):
            tb, cl = m.group(1).lower(), m.group(2).lower()
            if tb not in TABLAS_COLS or cl not in TABLAS_COLS[tb]:
                print(f"[{a}] %TYPE invalido: {tb}.{cl}")
                problemas += 1
        # INSERT INTO t (cols)
        for m in re.finditer(r"INSERT INTO (\w+)\s*\(([^)]*)\)", t, re.I):
            tb = m.group(1).lower()
            if tb not in TABLAS_COLS:
                print(f"[{a}] INSERT en tabla inexistente: {tb}")
                problemas += 1
                continue
            for c in [x.strip().lower() for x in m.group(2).split(",")]:
                if c not in TABLAS_COLS[tb]:
                    print(f"[{a}] INSERT {tb}: columna inexistente {c}")
                    problemas += 1
        # UPDATE t SET c = ...
        for m in re.finditer(r"UPDATE (\w+)\s+SET(.*?)(?:\bWHERE\b|;)", t, re.I | re.S):
            tb = m.group(1).lower()
            if tb not in TABLAS_COLS:
                print(f"[{a}] UPDATE en tabla inexistente: {tb}")
                problemas += 1
                continue
            for c in re.findall(r"(?:^|,)\s*(\w+)\s*=", m.group(2)):
                if c.lower() not in TABLAS_COLS[tb]:
                    print(f"[{a}] UPDATE {tb}: columna inexistente {c}")
                    problemas += 1
        # DELETE FROM t
        for m in re.finditer(r"DELETE FROM (\w+)", t, re.I):
            if m.group(1).lower() not in TABLAS_COLS:
                print(f"[{a}] DELETE de tabla inexistente: {m.group(1)}")
                problemas += 1
        # sentencias SELECT: alias -> objeto
        for sent in re.split(r";", t):
            if not re.search(r"\bSELECT\b", sent, re.I):
                continue
            alias = {}
            for m in re.finditer(r"\b(?:FROM|JOIN)\s+(\w+)(?:\s+(?:AS\s+)?(\w+))?", sent, re.I):
                nombre = m.group(1).lower()
                al = m.group(2)
                if nombre not in objetos:
                    if nombre not in ("dual", "user_objects", "user_errors", "user_procedures", "user_source",
                                      "user_tab_columns", "user_tables", "user_col_comments", "user_constraints",
                                      "user_indexes", "user_sequences"):
                        print(f"[{a}] FROM/JOIN objeto inexistente: {nombre}")
                        problemas += 1
                    continue
                alias[nombre] = nombre
                if al and al.lower() not in PALABRAS and al.lower() not in ("where", "group", "order", "on"):
                    alias[al.lower()] = nombre
            for m in re.finditer(r"\b(\w+)\.(\w+)\b", sent):
                al, cl = m.group(1).lower(), m.group(2).lower()
                if al in alias and cl not in objetos[alias[al]]:
                    print(f"[{a}] {al}.{cl}: la columna no existe en {alias[al]}")
                    problemas += 1
    print(f"{len(TABLAS_COLS)} tablas, {len(vistas)} vistas; {problemas} problemas")
    return 1 if problemas else 0


if __name__ == "__main__":
    sys.exit(main())
