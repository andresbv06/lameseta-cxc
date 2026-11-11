-- Script 11: diccionario de datos directo desde Oracle (alternativa al reporte de SQL Developer).
SET DEFINE OFF
SET LINESIZE 200
SET PAGESIZE 200

PROMPT === Columnas ===
SELECT c.table_name,
       c.column_id AS orden,
       c.column_name,
       c.data_type || CASE
         WHEN c.data_type = 'NUMBER' AND c.data_precision IS NOT NULL
           THEN '(' || c.data_precision || NVL2(c.data_scale, ',' || c.data_scale, '') || ')'
         WHEN c.data_type = 'VARCHAR2' THEN '(' || c.char_length || ')'
         ELSE ''
       END AS tipo,
       CASE c.nullable WHEN 'Y' THEN 'Si' ELSE 'No' END AS acepta_nulo,
       m.comments AS descripcion
  FROM user_tab_columns c
  JOIN user_tables t ON t.table_name = c.table_name
  LEFT JOIN user_col_comments m ON m.table_name = c.table_name AND m.column_name = c.column_name
 ORDER BY c.table_name, c.column_id;

PROMPT === Restricciones (PK, UQ, FK, CK) ===
SELECT table_name, constraint_name,
       DECODE(constraint_type, 'P', 'PK', 'U', 'UQ', 'R', 'FK', 'C', 'CK') AS tipo,
       r_constraint_name AS referencia
  FROM user_constraints
 WHERE constraint_type IN ('P', 'U', 'R', 'C')
   AND constraint_name NOT LIKE 'SYS\_C%' ESCAPE '\'
 ORDER BY table_name, constraint_type, constraint_name;

PROMPT === Indices ===
SELECT table_name, index_name, uniqueness FROM user_indexes ORDER BY table_name, index_name;
