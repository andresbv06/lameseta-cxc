-- Script 00: usuarios y roles.
-- Ejecutar como SYSTEM conectado al PDB (por ejemplo ORCLPDB), NO en CDB$ROOT.
-- Cambie las claves de ejemplo antes de usarlo fuera de pruebas.
SET DEFINE OFF

CREATE ROLE rol_admin;
CREATE ROLE rol_vendedor;
CREATE ROLE rol_cobrador;

CREATE USER lameseta IDENTIFIED BY "Lameseta#2026"
  DEFAULT TABLESPACE users
  QUOTA UNLIMITED ON users;
GRANT CREATE SESSION, CREATE TABLE, CREATE SEQUENCE, CREATE VIEW, CREATE PROCEDURE, CREATE TRIGGER TO lameseta;

CREATE USER lameseta_app IDENTIFIED BY "LamesetaApp#2026";
GRANT CREATE SESSION TO lameseta_app;
GRANT rol_admin, rol_vendedor, rol_cobrador TO lameseta_app;
