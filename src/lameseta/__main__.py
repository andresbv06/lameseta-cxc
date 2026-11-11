"""Punto de entrada: python -m lameseta"""
import getpass
import sys

from . import servicios
from .config import ErrorConfiguracion, cargar_archivo_env, leer_configuracion
from .db import BaseDatos, ErrorBD, ErrorNegocio
from .menu import menu_principal


def main() -> int:
    cargar_archivo_env()
    try:
        configuracion = leer_configuracion()
    except ErrorConfiguracion as e:
        print(f"Configuración incompleta: {e}")
        return 2
    bd = BaseDatos(configuracion)
    print("Distribuidora La Meseta - Cobros y facturación a crédito")
    try:
        for intento in range(3):
            usuario = input("Usuario: ").strip()
            clave = getpass.getpass("Clave: ")
            try:
                with bd.sesion() as s:
                    sesion_usuario = servicios.iniciar_sesion(s, usuario, clave)
                break
            except ErrorNegocio as e:
                print(f"  {e}")
        else:
            print("Demasiados intentos fallidos.")
            return 1
        menu_principal(bd, sesion_usuario)
    except ErrorBD as e:
        print(f"No se pudo conectar o trabajar con la base de datos: {e}")
        return 1
    except (KeyboardInterrupt, EOFError):
        print("\nHasta luego.")
    finally:
        bd.cerrar()
    return 0


if __name__ == "__main__":
    sys.exit(main())
