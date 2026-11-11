-- Script 00: usuarios y roles.
-- Ejecutar como SYSTEM, conectado a la base orclpdb (no a la conexion SYS_CDB).
-- Estas claves son de prueba.
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
