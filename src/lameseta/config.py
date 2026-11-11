"""Datos de conexion. Las claves se leen del archivo .env, que no se sube a GitHub."""
import os
from dataclasses import dataclass


class ErrorConfiguracion(Exception):
    pass


@dataclass(frozen=True)
class Configuracion:
    usuario: str
    clave: str
    host: str
    puerto: int
    servicio: str
    esquema: str

    @property
    def dsn(self) -> str:
        return f"{self.host}:{self.puerto}/{self.servicio}"

    def __repr__(self) -> str:  # nunca mostrar la clave
        return f"Configuracion(usuario={self.usuario!r}, dsn={self.dsn!r}, esquema={self.esquema!r})"


def cargar_archivo_env(ruta: str = ".env") -> None:
    """Lee el archivo .env (lineas CLAVE=valor)."""
    if not os.path.exists(ruta):
        return
    with open(ruta, encoding="utf-8") as f:
        for linea in f:
            linea = linea.strip()
            if not linea or linea.startswith("#") or "=" not in linea:
                continue
            nombre, valor = linea.split("=", 1)
            os.environ.setdefault(nombre.strip(), valor.strip().strip('"').strip("'"))


def leer_configuracion(entorno=None) -> Configuracion:
    env = os.environ if entorno is None else entorno
    faltan = [n for n in ("LAMESETA_DB_USER", "LAMESETA_DB_PASSWORD") if not env.get(n)]
    if faltan:
        raise ErrorConfiguracion(
            "Faltan variables de entorno: " + ", ".join(faltan) + ". Copie .env.example a .env y complete los datos.")
    try:
        puerto = int(env.get("LAMESETA_DB_PORT", "1521"))
    except ValueError as e:
        raise ErrorConfiguracion("LAMESETA_DB_PORT debe ser un numero.") from e
    return Configuracion(
        usuario=env["LAMESETA_DB_USER"],
        clave=env["LAMESETA_DB_PASSWORD"],
        host=env.get("LAMESETA_DB_HOST", "localhost"),
        puerto=puerto,
        servicio=env.get("LAMESETA_DB_SERVICE", "ORCLPDB"),
        esquema=env.get("LAMESETA_DB_SCHEMA", "LAMESETA"),
    )
