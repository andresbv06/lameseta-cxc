"""Tipos de datos que describen cada entidad (tabla) y cada campo."""
from dataclasses import dataclass, field
from typing import Any, List, Optional


@dataclass(frozen=True)
class Campo:
    nombre: str
    etiqueta: str
    tipo: str  # int, dec, str, date, bool, clave
    requerido: bool = True
    opciones: Optional[list] = None
    defecto: Any = None


@dataclass(frozen=True)
class Entidad:
    clave: str
    titulo: str
    paquete: str
    pk: List[Campo] = field(default_factory=list)
    pk_auto: bool = True
    insertar: List[Campo] = field(default_factory=list)
    actualizar: List[Campo] = field(default_factory=list)
    columnas: List[str] = field(default_factory=list)
