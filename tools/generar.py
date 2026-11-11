"""Genera, a partir de tools/modelo.py:
 - sql/01_tablas.sql
 - sql/05_paquetes_crud.sql
 - src/lameseta/entidades.py
 - docs/diccionario_datos.md y docs/diccionario_datos.json
Uso: python tools/generar.py"""
import json
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
from modelo import TABLAS, TABLAS_POR_NOMBRE, col  # noqa: E402

RAIZ = os.path.join(os.path.dirname(__file__), "..")


def escribir(ruta, texto):
    ruta = os.path.join(RAIZ, ruta)
    os.makedirs(os.path.dirname(ruta), exist_ok=True)
    with open(ruta, "w", encoding="utf-8", newline="\n") as f:
        f.write(texto)


def sql_lit(v):
    return "'" + str(v).replace("'", "''") + "'"


def ind(texto, n):
    pad = " " * n
    return "\n".join((pad + l) if l.strip() else l for l in texto.split("\n"))


# ------------------------------------------------------------------ tablas
def ddl_tabla(t):
    n = t["nombre"].lower()
    lineas = []
    for c in t["cols"]:
        s = f"{c['nombre']} {c['tipo']}"
        if c["default"] is not None:
            s += f" DEFAULT {c['default']}"
        if c["req"]:
            s += " NOT NULL"
        lineas.append(s)
    lineas.append(f"CONSTRAINT pk_{n} PRIMARY KEY ({', '.join(t['pk'])})")
    for nombre, cols in t.get("uniques", []):
        lineas.append(f"CONSTRAINT {nombre} UNIQUE ({', '.join(cols)})")
    for fk in t.get("fks", []):
        nombre, cols, ref, refcols = fk[:4]
        s = f"CONSTRAINT {nombre} FOREIGN KEY ({', '.join(cols)}) REFERENCES {ref.lower()} ({', '.join(refcols)})"
        if len(fk) > 4:
            s += f" ON DELETE {fk[4]}"
        lineas.append(s)
    for c in t["cols"]:
        if c["enum"]:
            vals = ", ".join(sql_lit(v) if isinstance(v, str) else str(v) for v in c["enum"])
            lineas.append(f"CONSTRAINT ck_{n}_{c['nombre']} CHECK ({c['nombre']} IN ({vals}))")
        if c["check"]:
            lineas.append(f"CONSTRAINT ck_{n}_{c['nombre']} CHECK ({c['check'].format(c=c['nombre'])})")
    for nombre, expr in t.get("tchecks", []):
        lineas.append(f"CONSTRAINT {nombre} CHECK ({expr})")
    cuerpo = ",\n    ".join(lineas)
    return f"CREATE TABLE {n} (\n    {cuerpo}\n);\n"


def sql_tablas():
    out = ["-- Script 01: tablas, secuencias, indices y comentarios.",
           "-- Ejecutar conectado como el usuario LAMESETA.", "SET DEFINE OFF", ""]
    for t in TABLAS:
        if t["seq"]:
            out.append(f"CREATE SEQUENCE {t['seq'].lower()} START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;")
    out.append("CREATE SEQUENCE seq_numero_factura START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;\n")
    for t in TABLAS:
        out.append(ddl_tabla(t))
    for t in TABLAS:
        n = t["nombre"].lower()
        for fk in t.get("fks", []):
            nombre, cols = fk[0], fk[1]
            if cols == t["pk"][: len(cols)]:
                continue
            out.append(f"CREATE INDEX {nombre.replace('fk_', 'idx_', 1)} ON {n} ({', '.join(cols)});")
        for nombre, cols in t.get("extra_idx", []):
            out.append(f"CREATE INDEX {nombre} ON {n} ({', '.join(cols)});")
    out.append("")
    for t in TABLAS:
        n = t["nombre"].lower()
        out.append(f"COMMENT ON TABLE {n} IS {sql_lit(t['desc'])};")
        for c in t["cols"]:
            out.append(f"COMMENT ON COLUMN {n}.{c['nombre']} IS {sql_lit(c['desc'])};")
    out.append("")
    return "\n".join(out)


# ------------------------------------------------------------------ paquetes CRUD
HANDLERS = """EXCEPTION
  WHEN DUP_VAL_ON_INDEX THEN
    RAISE_APPLICATION_ERROR(-20001, 'Ya existe un registro con ese valor unico en {T}.');
  WHEN NO_DATA_FOUND THEN
    RAISE_APPLICATION_ERROR(-20002, 'No existe el registro buscado en {T}.');
  WHEN e_hijos THEN
    RAISE_APPLICATION_ERROR(-20003, 'No se puede borrar: {T} tiene registros relacionados.');
  WHEN e_padre THEN
    RAISE_APPLICATION_ERROR(-20005, 'Una referencia no existe: revise las llaves de {T}.');
  WHEN e_check THEN
    RAISE_APPLICATION_ERROR(-20006, 'Un valor no cumple las reglas de validacion de {T}.');
  WHEN e_nulo THEN
    RAISE_APPLICATION_ERROR(-20007, 'Falta un dato obligatorio en {T}.');"""


def tipo_param(t, c):
    return f"{t['nombre'].lower()}.{c}%TYPE"


def params_insert(t):
    ps = []
    for c in t["ins"]:
        if c == "@clave":
            ps.append(("p_clave", "IN", "VARCHAR2"))
        else:
            ps.append((f"p_{c}", "IN", tipo_param(t, c)))
    if t["seq"]:
        ps.append((f"p_{t['pk'][0]}", "OUT", tipo_param(t, t["pk"][0])))
    return ps


def params_update(t):
    ps = [(f"p_{c}", "IN", tipo_param(t, c)) for c in t["pk"]]
    ps += [(f"p_{c}", "IN", tipo_param(t, c)) for c in t["upd"]]
    return ps


def params_pk(t):
    return [(f"p_{c}", "IN", tipo_param(t, c)) for c in t["pk"]]


def firma(nombre, ps, extra=None):
    lista = [f"{n} {d} {ty}" for n, d, ty in ps]
    if extra:
        lista.append(extra)
    if not lista:
        return f"PROCEDURE {nombre}"
    return f"PROCEDURE {nombre}(\n    " + ",\n    ".join(lista) + ")"


def paquete(t):
    T = t["nombre"]
    n = T.lower()
    pk = t["pk"]
    pkw = " AND ".join(f"{c} = p_{c}" for c in pk)
    sel = ", ".join(t.get("sel") or [c["nombre"] for c in t["cols"]])
    orden = ", ".join(pk)
    sins = firma("sp_insertar", params_insert(t))
    supd = firma("sp_actualizar", params_update(t))
    sdel = firma("sp_eliminar", params_pk(t))
    sobt = firma("sp_obtener", params_pk(t), "p_cursor OUT SYS_REFCURSOR")
    slis = firma("sp_listar", [], "p_cursor OUT SYS_REFCURSOR")
    spec = f"CREATE OR REPLACE PACKAGE pkg_{n} AS\n"
    for s in (sins, supd, sdel, sobt, slis):
        spec += f"  {s.replace(chr(10), chr(10) + '  ')};\n"
    spec += f"END pkg_{n};\n/\n"

    body = f"CREATE OR REPLACE PACKAGE BODY pkg_{n} AS\n"
    body += """  e_hijos EXCEPTION;
  PRAGMA EXCEPTION_INIT(e_hijos, -2292);
  e_padre EXCEPTION;
  PRAGMA EXCEPTION_INIT(e_padre, -2291);
  e_check EXCEPTION;
  PRAGMA EXCEPTION_INIT(e_check, -2290);
  e_nulo EXCEPTION;
  PRAGMA EXCEPTION_INIT(e_nulo, -1400);

"""
    h = HANDLERS.replace("{T}", T)

    def proc(sig, decl, pre, sql, post, con_handlers=True):
        s = "  " + sig.replace("\n", "\n  ") + " IS\n"
        if decl:
            s += ind("\n".join(x.strip() for x in decl.split("\n")), 4) + "\n"
        s += "  BEGIN\n"
        for bloque in (pre, sql, post):
            if bloque:
                s += ind(bloque, 4) + "\n"
        if con_handlers:
            s += ind(h, 2) + "\n"
        return s

    # insertar
    ins_cols = t.get("ins_cols") or [c for c in t["ins"] if c != "@clave"]
    vals_map = t.get("ins_vals", {})
    cols_sql, vals_sql = [], []
    if t["seq"]:
        cols_sql.append(pk[0])
        vals_sql.append(f"{t['seq'].lower()}.NEXTVAL")
    for c in ins_cols:
        cols_sql.append(c)
        meta = col(t, c)
        if c in vals_map:
            vals_sql.append(vals_map[c])
        elif meta["default"] is not None and meta["req"]:
            vals_sql.append(f"NVL(p_{c}, {meta['default']})")
        else:
            vals_sql.append(f"p_{c}")
    sql = f"INSERT INTO {n} ({', '.join(cols_sql)})\nVALUES ({', '.join(vals_sql)})"
    if t["seq"]:
        sql += f"\nRETURNING {pk[0]} INTO p_{pk[0]}"
    sql += ";"
    body += proc(sins, t.get("ins_decl"), t.get("ins_pre"), sql, t.get("ins_post")) + "  END sp_insertar;\n\n"

    # actualizar
    sets = [f"{c} = p_{c}" for c in t["upd"]]
    for c, expr in t.get("upd_sets", {}).items():
        sets.append(f"{c} = {expr}")
    sql = f"UPDATE {n}\n   SET " + ",\n       ".join(sets) + f"\n WHERE {pkw};\n"
    sql += "IF SQL%ROWCOUNT = 0 THEN\n  RAISE_APPLICATION_ERROR(-20002, 'No existe el registro buscado en " + T + ".');\nEND IF;"
    body += proc(supd, t.get("upd_decl"), t.get("upd_pre"), sql, t.get("upd_post")) + "  END sp_actualizar;\n\n"

    # eliminar
    sql = f"DELETE FROM {n} WHERE {pkw};\n"
    sql += "IF SQL%ROWCOUNT = 0 THEN\n  RAISE_APPLICATION_ERROR(-20002, 'No existe el registro buscado en " + T + ".');\nEND IF;"
    body += proc(sdel, t.get("del_decl"), t.get("del_pre"), sql, t.get("del_post")) + "  END sp_eliminar;\n\n"

    # obtener y listar (cursores REF)
    sql = f"OPEN p_cursor FOR\n  SELECT {sel}\n    FROM {n}\n   WHERE {pkw};"
    body += "  " + sobt.replace("\n", "\n  ") + " IS\n  BEGIN\n" + ind(sql, 4) + "\n  END sp_obtener;\n\n"
    sql = f"OPEN p_cursor FOR\n  SELECT {sel}\n    FROM {n}\n   ORDER BY {orden};"
    body += "  " + slis.replace("\n", "\n  ") + " IS\n  BEGIN\n" + ind(sql, 4) + "\n  END sp_listar;\n"
    body += f"END pkg_{n};\n/\n"
    return spec + "\n" + body


def corregir_handlers(texto):
    # El bloque EXCEPTION termina con el ultimo WHEN; se cierra con "END nombre;" aparte.
    return texto


def sql_paquetes():
    out = ["-- Script 05: paquetes con el CRUD de las 13 tablas (insertar, actualizar, eliminar, obtener, listar).",
           "-- Ninguna operacion guarda los cambios por si sola: lo hace el programa Python al terminar bien.",
           "SET DEFINE OFF", ""]
    for t in TABLAS:
        out.append(paquete(t))
    return "\n".join(out)


# ------------------------------------------------------------------ Python
LABELS = {
    "id_zona": "Zona (ID)", "id_empleado": "Empleado (ID)", "id_cliente": "Cliente (ID)",
    "id_vendedor": "Vendedor (ID)", "id_categoria": "Categoría (ID)", "id_producto": "Producto (ID)",
    "id_factura": "Factura (ID)", "id_nota": "Nota (ID)", "id_metodo_pago": "Método de pago (ID)",
    "id_pago": "Pago (ID)", "id_aplicacion": "Aplicación (ID)", "id_gestion": "Gestión (ID)",
    "id_bitacora": "Bitácora (ID)", "nombre_zona": "Nombre de la zona", "provincia": "Provincia",
    "nombre": "Nombre", "apellido": "Apellidos", "correo": "Correo", "rol": "Rol", "usuario": "Usuario",
    "clave": "Clave", "activo": "Activo", "cedula": "Cédula", "nombre_comercial": "Nombre comercial",
    "telefono": "Teléfono", "direccion": "Dirección", "limite_credito": "Límite de crédito",
    "dias_credito": "Días de crédito", "estado": "Estado", "nombre_categoria": "Nombre de la categoría",
    "codigo": "Código", "nombre_producto": "Nombre del producto", "precio_unitario": "Precio unitario",
    "stock_actual": "Existencias", "nombre_metodo": "Nombre del método", "fecha_emision": "Fecha de emisión",
    "fecha_vencimiento": "Fecha de vencimiento", "cantidad": "Cantidad", "fecha_nota": "Fecha de la nota",
    "monto": "Monto", "motivo": "Motivo", "fecha_pago": "Fecha del pago", "referencia": "Referencia",
    "monto_aplicado": "Monto aplicado", "fecha_aplicacion": "Fecha de aplicación", "fecha_hora": "Fecha y hora",
    "tipo_gestion": "Tipo de gestión", "resultado": "Resultado", "fecha_promesa": "Fecha de promesa",
    "observacion": "Observación", "tabla_afectada": "Tabla afectada", "operacion": "Operación", "detalle": "Detalle",
    "numero_factura": "Número de factura", "monto_total": "Monto total", "saldo_pendiente": "Saldo pendiente",
    "monto_sin_aplicar": "Monto sin aplicar", "usuario_bd": "Usuario de BD", "clave_hash": "Clave (hash)",
}
TITULOS = {
    "ZONA": "Zonas", "EMPLEADO": "Empleados", "CLIENTE": "Clientes", "CATEGORIA": "Categorías",
    "PRODUCTO": "Productos", "METODO_PAGO": "Métodos de pago", "FACTURA": "Facturas",
    "DETALLE_FACTURA": "Detalle de factura", "NOTA_CREDITO": "Notas de crédito", "PAGO": "Pagos",
    "APLICACION_PAGO": "Aplicaciones de pago", "GESTION_COBRO": "Gestiones de cobro", "BITACORA": "Bitácora",
}


def tipo_py(c):
    if c["tipo"].startswith("DATE"):
        return "date"
    if c["tipo"] == "NUMBER(1)":
        return "bool"
    if c["tipo"] == DIN_T:
        return "dec"
    if c["tipo"].startswith("NUMBER"):
        return "int"
    return "str"


DIN_T = "NUMBER(12,2)"


def campo_py(t, nombre):
    if nombre == "@clave":
        return 'Campo("clave", "Clave", "clave", True)'
    c = col(t, nombre)
    req = c["req"] and c["default"] is None
    opciones = repr(list(c["enum"])) if c["enum"] else "None"
    default = "None"
    if c["default"] is not None:
        d = c["default"].strip("'")
        default = repr(d) if tipo_py(c) == "str" else ("None" if d == "SYSDATE" else d)
    return f'Campo("{nombre}", "{LABELS.get(nombre, nombre)}", "{tipo_py(c)}", {req}, {opciones}, {default})'


def py_entidades():
    out = ['"""GENERADO por tools/generar.py a partir de tools/modelo.py. No editar a mano."""',
           "from .tipos import Campo, Entidad", "", "ENTIDADES = {"]
    for t in TABLAS:
        n = t["nombre"].lower()
        pk = ", ".join(campo_py(t, c) for c in t["pk"])
        ins = ", ".join(campo_py(t, c) for c in t["ins"])
        upd = ", ".join(campo_py(t, c) for c in t["upd"])
        cols = t.get("sel") or [c["nombre"] for c in t["cols"]]
        out.append(f'    "{n}": Entidad(')
        out.append(f'        clave="{n}", titulo="{TITULOS[t["nombre"]]}", paquete="PKG_{t["nombre"]}",')
        out.append(f"        pk=[{pk}],")
        out.append(f"        pk_auto={bool(t['seq'])},")
        out.append(f"        insertar=[{ins}],")
        out.append(f"        actualizar=[{upd}],")
        out.append(f"        columnas={cols!r},")
        out.append("    ),")
    out.append("}")
    return "\n".join(out) + "\n"


# ------------------------------------------------------------------ diccionario
def diccionario():
    datos = []
    for t in TABLAS:
        fkmap = {}
        for fk in t.get("fks", []):
            for c, rc in zip(fk[1], fk[3]):
                fkmap[c] = f"{fk[2]}.{rc}"
        uqs = {c for _, cols in t.get("uniques", []) for c in cols}
        filas = []
        for c in t["cols"]:
            llave = []
            if c["nombre"] in t["pk"]:
                llave.append("PK")
            if c["nombre"] in fkmap:
                llave.append("FK -> " + fkmap[c["nombre"]])
            if c["nombre"] in uqs:
                llave.append("UQ")
            reglas = []
            if c["enum"]:
                reglas.append("Valores: " + ", ".join(str(v) for v in c["enum"]))
            if c["check"]:
                reglas.append(c["check"].format(c=c["nombre"]).replace("{c}", c["nombre"]))
            filas.append(dict(columna=c["nombre"], tipo=c["tipo"], nulo="Sí" if not c["req"] else "No",
                              defecto=c["default"] or "", llave=", ".join(llave), reglas="; ".join(reglas),
                              descripcion=c["desc"]))
        datos.append(dict(tabla=t["nombre"], descripcion=t["desc"], columnas=filas,
                          secuencia=t["seq"] or "", pk=t["pk"]))
    return datos


def md_diccionario(datos):
    out = ["# Diccionario de datos — Distribuidora La Meseta", "",
           "Generado desde `tools/modelo.py`. Para obtenerlo directo de Oracle, ejecute `sql/10_diccionario_datos.sql`.", ""]
    for d in datos:
        out += [f"## {d['tabla']}", "", d["descripcion"], "",
                "| Columna | Tipo | Nulo | Defecto | Llave | Reglas | Descripción |", "|---|---|---|---|---|---|---|"]
        for f in d["columnas"]:
            out.append(f"| {f['columna']} | {f['tipo']} | {f['nulo']} | {f['defecto']} | {f['llave']} | {f['reglas']} | {f['descripcion']} |")
        out.append("")
    return "\n".join(out)


if __name__ == "__main__":
    escribir("sql/01_tablas.sql", sql_tablas())
    escribir("sql/05_paquetes_crud.sql", sql_paquetes())
    escribir("src/lameseta/entidades.py", py_entidades())
    d = diccionario()
    escribir("docs/diccionario_datos.json", json.dumps(d, ensure_ascii=False, indent=1))
    escribir("docs/diccionario_datos.md", md_diccionario(d))
    print("generado")
