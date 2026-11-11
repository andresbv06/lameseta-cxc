"""Junta los scripts 01 a 10 en sql/lameseta_completo.sql para ejecutarlo de una vez (F5 en SQL Developer)."""
import os
raiz = os.path.join(os.path.dirname(__file__), "..", "sql")
partes = ["01_tablas", "02_funciones", "03_procedimientos_base", "04_vistas", "05_paquetes_crud",
          "06_procedimientos_negocio", "07_triggers", "08_permisos", "09_datos_prueba", "10_verificacion"]
out = ["-- Instalacion completa (scripts 01 a 10). Ejecutar como LAMESETA despues del script 00.", "SET DEFINE OFF", ""]
for p in partes:
    out.append(f"PROMPT >>> {p}")
    txt = open(os.path.join(raiz, p + ".sql"), encoding="utf-8").read()
    txt = "\n".join(l for l in txt.split("\n") if l.strip().upper() != "SET DEFINE OFF")
    out.append(txt)
    out.append("")
open(os.path.join(raiz, "lameseta_completo.sql"), "w", encoding="utf-8", newline="\n").write("\n".join(out))
print("ok")
