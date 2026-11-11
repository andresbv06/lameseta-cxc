"""Entrada y salida por consola: leer campos, mostrar tablas y exportar a CSV."""
import csv
import getpass
from datetime import date, datetime
from decimal import Decimal, InvalidOperation

from .tipos import Campo


def pedir(texto: str) -> str:
    return input(texto).strip()


def pedir_si_no(texto: str) -> bool:
    return pedir(texto + " (s/n): ").lower() in ("s", "si", "sí")


def pedir_entero(texto: str, minimo=None) -> int:
    while True:
        try:
            valor = int(pedir(texto + ": "))
            if minimo is not None and valor < minimo:
                print(f"  Debe ser {minimo} o más.")
                continue
            return valor
        except ValueError:
            print("  Escriba un número entero.")


def pedir_decimal(texto: str) -> Decimal:
    while True:
        try:
            return Decimal(pedir(texto + ": ").replace(",", "."))
        except InvalidOperation:
            print("  Escriba un número, por ejemplo 1500.50")


def pedir_fecha(texto: str, opcional=False):
    while True:
        bruto = pedir(f"{texto} (AAAA-MM-DD){' [Enter = hoy]' if opcional else ''}: ")
        if not bruto and opcional:
            return None
        try:
            return datetime.strptime(bruto, "%Y-%m-%d")
        except ValueError:
            print("  Formato inválido. Ejemplo: 2026-11-30")


def pedir_campo(campo: Campo, actual=None):
    """Pide un valor segun el tipo del campo. Enter en un campo opcional devuelve None."""
    sufijo = ""
    if campo.opciones:
        sufijo = " [" + "/".join(str(o) for o in campo.opciones) + "]"
    if campo.tipo == "bool":
        sufijo = " [s/n]"
    if not campo.requerido:
        sufijo += " (opcional)"
    if actual not in (None, ""):
        sufijo += f" [actual: {actual}]"
    while True:
        if campo.tipo == "clave":
            valor = getpass.getpass(f"{campo.etiqueta}: ")
        else:
            valor = pedir(f"{campo.etiqueta}{sufijo}: ")
        if valor == "" and actual not in (None, ""):
            return actual
        if valor == "":
            if campo.requerido:
                print("  Este dato es obligatorio.")
                continue
            return None
        try:
            if campo.tipo == "int":
                valor = int(valor)
            elif campo.tipo == "dec":
                valor = Decimal(valor.replace(",", "."))
            elif campo.tipo == "date":
                valor = datetime.strptime(valor, "%Y-%m-%d")
            elif campo.tipo == "bool":
                valor = 1 if valor.lower() in ("s", "si", "sí", "1") else 0
        except (ValueError, InvalidOperation):
            print("  Valor inválido, intente de nuevo.")
            continue
        if campo.opciones and campo.tipo not in ("bool",):
            if str(valor).upper() not in [str(o).upper() for o in campo.opciones]:
                print("  Opción no válida.")
                continue
            valor = str(valor).upper()
        return valor


def formatear(valor) -> str:
    if valor is None:
        return ""
    if isinstance(valor, datetime):
        return valor.strftime("%Y-%m-%d %H:%M") if (valor.hour or valor.minute) else valor.strftime("%Y-%m-%d")
    if isinstance(valor, date):
        return valor.strftime("%Y-%m-%d")
    if isinstance(valor, Decimal):
        return f"{valor:,.2f}"
    return str(valor)


def mostrar_tabla(columnas, filas, titulo=None):
    if titulo:
        print(f"\n=== {titulo} ===")
    if not filas:
        print("(sin resultados)")
        return
    texto = [[formatear(v) for v in fila] for fila in filas]
    anchos = [max(len(str(c)), *(len(f[i]) for f in texto)) for i, c in enumerate(columnas)]
    anchos = [min(a, 40) for a in anchos]
    print("  ".join(str(c).upper().ljust(a)[:a] for c, a in zip(columnas, anchos)))
    print("  ".join("-" * a for a in anchos))
    for f in texto:
        print("  ".join(v.ljust(a)[:a] for v, a in zip(f, anchos)))
    print(f"({len(filas)} fila{'s' if len(filas) != 1 else ''})")


def exportar_csv(columnas, filas, ruta: str):
    with open(ruta, "w", newline="", encoding="utf-8-sig") as f:
        w = csv.writer(f)
        w.writerow(columnas)
        for fila in filas:
            w.writerow([formatear(v) for v in fila])
