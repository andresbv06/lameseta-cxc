"""Revision estatica: toda llamada a un procedimiento o funcion propia existe y usa la cantidad correcta de parametros.
Uso: python tools/chequear_llamadas.py"""
import glob
import os
import re
import sys

RAIZ = os.environ.get("SQL_DIR") or os.path.join(os.path.dirname(__file__), "..", "sql")
ARCHIVOS = ["02_funciones", "03_procedimientos_base", "05_paquetes_crud", "06_procedimientos_negocio", "07_triggers",
            "09_datos_prueba", "10_verificacion"]


def separar_args(texto):
    """Separa argumentos al nivel superior de un parentesis."""
    args, nivel, actual, comilla = [], 0, "", False
    for ch in texto:
        if ch == "'":
            comilla = not comilla
        if not comilla:
            if ch == "(":
                nivel += 1
            elif ch == ")":
                nivel -= 1
            elif ch == "," and nivel == 0:
                args.append(actual.strip())
                actual = ""
                continue
        actual += ch
    if actual.strip():
        args.append(actual.strip())
    return args


def extraer_parentesis(texto, inicio):
    nivel, i, comilla = 0, inicio, False
    while i < len(texto):
        ch = texto[i]
        if ch == "'":
            comilla = not comilla
        if not comilla:
            if ch == "(":
                nivel += 1
            elif ch == ")":
                nivel -= 1
                if nivel == 0:
                    return texto[inicio + 1:i], i
        i += 1
    return None, inicio


def quitar_comentarios(t):
    t = re.sub(r"--[^\n]*", "", t)
    return t


def main():
    contenido = {}
    for a in ARCHIVOS:
        contenido[a] = quitar_comentarios(open(os.path.join(RAIZ, a + ".sql"), encoding="utf-8").read())
    firmas = {}  # nombre (minusculas) -> cantidad de parametros
    # standalone
    for a in ("02_funciones", "03_procedimientos_base", "06_procedimientos_negocio"):
        for m in re.finditer(r"CREATE OR REPLACE (?:FUNCTION|PROCEDURE)\s+(\w+)\s*(\()?", contenido[a], re.I):
            n = m.group(1).lower()
            if m.group(2):
                cuerpo, _ = extraer_parentesis(contenido[a], m.end() - 1)
                firmas[n] = len(separar_args(cuerpo))
            else:
                firmas[n] = 0
    # paquetes (solo la especificacion)
    for m in re.finditer(r"CREATE OR REPLACE PACKAGE (\w+) AS(.*?)END \1;", contenido["05_paquetes_crud"], re.I | re.S):
        pk = m.group(1).lower()
        for pm in re.finditer(r"PROCEDURE\s+(\w+)\s*(\()?", m.group(2), re.I):
            if pm.group(2):
                cuerpo, _ = extraer_parentesis(m.group(2), pm.end() - 1)
                firmas[f"{pk}.{pm.group(1).lower()}"] = len(separar_args(cuerpo))
            else:
                firmas[f"{pk}.{pm.group(1).lower()}"] = 0
    errores = 0
    patron = re.compile(r"\b((?:pkg_\w+\.)?(?:fn|sp)_\w+)\b(\s*\()?", re.I)
    for a, txt in contenido.items():
        for m in patron.finditer(txt):
            nombre = m.group(1).lower()
            # ignorar la propia definicion
            previo = txt[max(0, m.start() - 40):m.start()].upper()
            if re.search(r"(FUNCTION|PROCEDURE|END)\s*$", previo):
                continue
            if nombre not in firmas:
                if nombre.startswith(("fn_", "sp_")) or nombre.startswith("pkg_"):
                    print(f"[{a}] llamada a algo que no existe: {nombre}")
                    errores += 1
                continue
            esperado = firmas[nombre]
            if m.group(2):
                cuerpo, _ = extraer_parentesis(txt, m.end() - 1)
                dado = len(separar_args(cuerpo))
            else:
                dado = 0
            if dado != esperado:
                linea = txt[:m.start()].count("\n") + 1
                print(f"[{a}:{linea}] {nombre} espera {esperado} parametros y recibe {dado}")
                errores += 1
    print(f"{len(firmas)} subprogramas conocidos; {errores} problemas")
    return 1 if errores else 0


if __name__ == "__main__":
    sys.exit(main())
