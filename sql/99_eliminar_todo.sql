-- Script 99: borra todos los objetos del esquema LAMESETA para volver a empezar.
-- Ejecutar como LAMESETA. No borra usuarios ni roles.
SET DEFINE OFF

BEGIN
  FOR o IN (SELECT object_name, object_type
              FROM user_objects
             WHERE object_type IN ('VIEW', 'PACKAGE', 'PROCEDURE', 'FUNCTION')) LOOP
    EXECUTE IMMEDIATE 'DROP ' || o.object_type || ' ' || o.object_name;
  END LOOP;
  FOR t IN (SELECT table_name FROM user_tables) LOOP
    EXECUTE IMMEDIATE 'DROP TABLE ' || t.table_name || ' CASCADE CONSTRAINTS PURGE';
  END LOOP;
  FOR s IN (SELECT sequence_name FROM user_sequences) LOOP
    EXECUTE IMMEDIATE 'DROP SEQUENCE ' || s.sequence_name;
  END LOOP;
END;
/
