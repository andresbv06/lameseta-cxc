"""Regla del profesor: no se permiten consultas directas (por ejemplo "select ... from ...") dentro del codigo."""
import ast
import glob
import os
import re

SRC = os.path.join(os.path.dirname(__file__), "..", "src")
PATRON_SQL = re.compile(
    r"^\s*(select\b.+\bfrom\b|insert\s+into\b|update\s+\w+\s+set\b|delete\s+from\b|merge\s+into\b|"
    r"(create|drop|alter|truncate)\s+(table|view|index|sequence|procedure|function|package|trigger)\b)",
    re.I | re.S)


def _archivos():
    return glob.glob(os.path.join(SRC, "**", "*.py"), recursive=True)


def test_no_hay_cadenas_sql():
    problemas = []
    for ruta in _archivos():
        arbol = ast.parse(open(ruta, encoding="utf-8").read())
        for nodo in ast.walk(arbol):
            if isinstance(nodo, ast.Constant) and isinstance(nodo.value, str) and PATRON_SQL.match(nodo.value):
                problemas.append(f"{os.path.basename(ruta)}:{nodo.lineno}: {nodo.value[:40]!r}")
    assert not problemas, problemas


def test_no_se_usa_execute():
    for ruta in _archivos():
        texto = open(ruta, encoding="utf-8").read()
        assert ".execute(" not in texto and ".executemany(" not in texto, ruta
