# Sistema de Cuentas por Cobrar - Distribuidora La Meseta S.A.

Proyecto del curso **Lenguaje de Bases de Datos** (Fidélitas Virtual). Autor: Andrés Barrantes.
Oracle SQL/PL/SQL + aplicación de consola en Python 3.12 (python-oracledb, modo Thin).

## Regla principal
El código Python **no contiene consultas SQL**: todo acceso a datos se hace llamando procedimientos,
funciones y paquetes almacenados (`callproc`/`callfunc`). `tests/test_sin_sql_directo.py` lo verifica.

## Estructura
- `sql/` scripts de Oracle, en orden numérico (00 a 11); `lameseta_completo.sql` junta 01-10.
- `src/lameseta/` aplicación Python (conexión, CRUD genérico, servicios, menús por rol).
- `tools/` generador del modelo (tablas, paquetes CRUD, diccionario) y verificadores estáticos.
- `tests/` pruebas con objetos falsos de `oracledb` (no requieren base de datos).
- `docs/` diccionario de datos y guía de GitHub.

## Instalación
1. Ejecutar `sql/00_usuarios_roles.sql` como SYSTEM en la PDB (crea LAMESETA y LAMESETA_APP).
2. Conectarse como LAMESETA y ejecutar `sql/01` a `sql/10` en orden (o `lameseta_completo.sql`).
3. `python -m venv .venv && source .venv/bin/activate && pip install -r requirements-dev.txt`
4. `cp .env.example .env` y ajustar host/servicio.
5. `python -m pytest` y luego `PYTHONPATH=src python -m lameseta`.

## Usuarios de prueba
admin/Admin2026 (administrador), mrojas y lsolis/Vende2026 (vendedores), jvargas y kmora/Cobra2026 (cobradores).

## Objetos (rúbrica)
| Requisito | Mínimo | Entregado |
|---|---|---|
| Procedimientos | 25 | 30 sueltos + 65 en paquetes |
| Vistas | 10 | 12 |
| Funciones | 15 | 24 |
| Paquetes | 10 | 13 |
| Triggers | 5 | 7 |
| Cursores | 15 | 12 REF CURSOR de reportes + 26 en CRUD + 4 explícitos |

## Estado de la validación
Los scripts SQL fueron revisados con un analizador de gramática PL/SQL y verificadores de nombres y
aridad, y la parte Python con pruebas automáticas. **Aún deben ejecutarse en una instancia Oracle real**
(`sql/10_verificacion.sql` muestra objetos inválidos y errores de compilación).
