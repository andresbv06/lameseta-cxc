-- Script 05: paquetes con el CRUD de las 13 tablas (insertar, actualizar, eliminar, obtener, listar).
-- Ninguna operacion guarda los cambios por si sola: lo hace el programa Python al terminar bien.
SET DEFINE OFF

CREATE OR REPLACE PACKAGE pkg_zona AS
  PROCEDURE sp_insertar(
      p_nombre_zona IN zona.nombre_zona%TYPE,
      p_provincia IN zona.provincia%TYPE,
      p_id_zona OUT zona.id_zona%TYPE);
  PROCEDURE sp_actualizar(
      p_id_zona IN zona.id_zona%TYPE,
      p_nombre_zona IN zona.nombre_zona%TYPE,
      p_provincia IN zona.provincia%TYPE);
  PROCEDURE sp_eliminar(
      p_id_zona IN zona.id_zona%TYPE);
  PROCEDURE sp_obtener(
      p_id_zona IN zona.id_zona%TYPE,
      p_cursor OUT SYS_REFCURSOR);
  PROCEDURE sp_listar(
      p_cursor OUT SYS_REFCURSOR);
END pkg_zona;
/

CREATE OR REPLACE PACKAGE BODY pkg_zona AS
  e_hijos EXCEPTION;
  PRAGMA EXCEPTION_INIT(e_hijos, -2292);
  e_padre EXCEPTION;
  PRAGMA EXCEPTION_INIT(e_padre, -2291);
  e_check EXCEPTION;
  PRAGMA EXCEPTION_INIT(e_check, -2290);
  e_nulo EXCEPTION;
  PRAGMA EXCEPTION_INIT(e_nulo, -1400);

  PROCEDURE sp_insertar(
      p_nombre_zona IN zona.nombre_zona%TYPE,
      p_provincia IN zona.provincia%TYPE,
      p_id_zona OUT zona.id_zona%TYPE) IS
  BEGIN
    INSERT INTO zona (id_zona, nombre_zona, provincia)
    VALUES (seq_zona.NEXTVAL, p_nombre_zona, p_provincia)
    RETURNING id_zona INTO p_id_zona;
  EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
      RAISE_APPLICATION_ERROR(-20001, 'Ya existe un registro con ese valor unico en ZONA.');
    WHEN NO_DATA_FOUND THEN
      RAISE_APPLICATION_ERROR(-20002, 'No existe el registro buscado en ZONA.');
    WHEN e_hijos THEN
      RAISE_APPLICATION_ERROR(-20003, 'No se puede borrar: ZONA tiene registros relacionados.');
    WHEN e_padre THEN
      RAISE_APPLICATION_ERROR(-20005, 'Una referencia no existe: revise las llaves de ZONA.');
    WHEN e_check THEN
      RAISE_APPLICATION_ERROR(-20006, 'Un valor no cumple las reglas de validacion de ZONA.');
    WHEN e_nulo THEN
      RAISE_APPLICATION_ERROR(-20007, 'Falta un dato obligatorio en ZONA.');
  END sp_insertar;

  PROCEDURE sp_actualizar(
      p_id_zona IN zona.id_zona%TYPE,
      p_nombre_zona IN zona.nombre_zona%TYPE,
      p_provincia IN zona.provincia%TYPE) IS
  BEGIN
    UPDATE zona
       SET nombre_zona = p_nombre_zona,
           provincia = p_provincia
     WHERE id_zona = p_id_zona;
    IF SQL%ROWCOUNT = 0 THEN
      RAISE_APPLICATION_ERROR(-20002, 'No existe el registro buscado en ZONA.');
    END IF;
  EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
      RAISE_APPLICATION_ERROR(-20001, 'Ya existe un registro con ese valor unico en ZONA.');
    WHEN NO_DATA_FOUND THEN
      RAISE_APPLICATION_ERROR(-20002, 'No existe el registro buscado en ZONA.');
    WHEN e_hijos THEN
      RAISE_APPLICATION_ERROR(-20003, 'No se puede borrar: ZONA tiene registros relacionados.');
    WHEN e_padre THEN
      RAISE_APPLICATION_ERROR(-20005, 'Una referencia no existe: revise las llaves de ZONA.');
    WHEN e_check THEN
      RAISE_APPLICATION_ERROR(-20006, 'Un valor no cumple las reglas de validacion de ZONA.');
    WHEN e_nulo THEN
      RAISE_APPLICATION_ERROR(-20007, 'Falta un dato obligatorio en ZONA.');
  END sp_actualizar;

  PROCEDURE sp_eliminar(
      p_id_zona IN zona.id_zona%TYPE) IS
  BEGIN
    DELETE FROM zona WHERE id_zona = p_id_zona;
    IF SQL%ROWCOUNT = 0 THEN
      RAISE_APPLICATION_ERROR(-20002, 'No existe el registro buscado en ZONA.');
    END IF;
  EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
      RAISE_APPLICATION_ERROR(-20001, 'Ya existe un registro con ese valor unico en ZONA.');
    WHEN NO_DATA_FOUND THEN
      RAISE_APPLICATION_ERROR(-20002, 'No existe el registro buscado en ZONA.');
    WHEN e_hijos THEN
      RAISE_APPLICATION_ERROR(-20003, 'No se puede borrar: ZONA tiene registros relacionados.');
    WHEN e_padre THEN
      RAISE_APPLICATION_ERROR(-20005, 'Una referencia no existe: revise las llaves de ZONA.');
    WHEN e_check THEN
      RAISE_APPLICATION_ERROR(-20006, 'Un valor no cumple las reglas de validacion de ZONA.');
    WHEN e_nulo THEN
      RAISE_APPLICATION_ERROR(-20007, 'Falta un dato obligatorio en ZONA.');
  END sp_eliminar;

  PROCEDURE sp_obtener(
      p_id_zona IN zona.id_zona%TYPE,
      p_cursor OUT SYS_REFCURSOR) IS
  BEGIN
    OPEN p_cursor FOR
      SELECT id_zona, nombre_zona, provincia
        FROM zona
       WHERE id_zona = p_id_zona;
  END sp_obtener;

  PROCEDURE sp_listar(
      p_cursor OUT SYS_REFCURSOR) IS
  BEGIN
    OPEN p_cursor FOR
      SELECT id_zona, nombre_zona, provincia
        FROM zona
       ORDER BY id_zona;
  END sp_listar;
END pkg_zona;
/

CREATE OR REPLACE PACKAGE pkg_empleado AS
  PROCEDURE sp_insertar(
      p_id_zona IN empleado.id_zona%TYPE,
      p_nombre IN empleado.nombre%TYPE,
      p_apellido IN empleado.apellido%TYPE,
      p_correo IN empleado.correo%TYPE,
      p_rol IN empleado.rol%TYPE,
      p_usuario IN empleado.usuario%TYPE,
      p_clave IN VARCHAR2,
      p_activo IN empleado.activo%TYPE,
      p_id_empleado OUT empleado.id_empleado%TYPE);
  PROCEDURE sp_actualizar(
      p_id_empleado IN empleado.id_empleado%TYPE,
      p_id_zona IN empleado.id_zona%TYPE,
      p_nombre IN empleado.nombre%TYPE,
      p_apellido IN empleado.apellido%TYPE,
      p_correo IN empleado.correo%TYPE,
      p_rol IN empleado.rol%TYPE,
      p_activo IN empleado.activo%TYPE);
  PROCEDURE sp_eliminar(
      p_id_empleado IN empleado.id_empleado%TYPE);
  PROCEDURE sp_obtener(
      p_id_empleado IN empleado.id_empleado%TYPE,
      p_cursor OUT SYS_REFCURSOR);
  PROCEDURE sp_listar(
      p_cursor OUT SYS_REFCURSOR);
END pkg_empleado;
/

CREATE OR REPLACE PACKAGE BODY pkg_empleado AS
  e_hijos EXCEPTION;
  PRAGMA EXCEPTION_INIT(e_hijos, -2292);
  e_padre EXCEPTION;
  PRAGMA EXCEPTION_INIT(e_padre, -2291);
  e_check EXCEPTION;
  PRAGMA EXCEPTION_INIT(e_check, -2290);
  e_nulo EXCEPTION;
  PRAGMA EXCEPTION_INIT(e_nulo, -1400);

  PROCEDURE sp_insertar(
      p_id_zona IN empleado.id_zona%TYPE,
      p_nombre IN empleado.nombre%TYPE,
      p_apellido IN empleado.apellido%TYPE,
      p_correo IN empleado.correo%TYPE,
      p_rol IN empleado.rol%TYPE,
      p_usuario IN empleado.usuario%TYPE,
      p_clave IN VARCHAR2,
      p_activo IN empleado.activo%TYPE,
      p_id_empleado OUT empleado.id_empleado%TYPE) IS
  BEGIN
    IF p_clave IS NULL OR LENGTH(p_clave) < 6 THEN
      RAISE_APPLICATION_ERROR(-20020, 'La clave debe tener al menos 6 caracteres.');
    END IF;
    INSERT INTO empleado (id_empleado, id_zona, nombre, apellido, correo, rol, usuario, clave_hash, activo)
    VALUES (seq_empleado.NEXTVAL, p_id_zona, p_nombre, p_apellido, p_correo, p_rol, p_usuario, fn_hash_clave(p_usuario, p_clave), NVL(p_activo, 1))
    RETURNING id_empleado INTO p_id_empleado;
  EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
      RAISE_APPLICATION_ERROR(-20001, 'Ya existe un registro con ese valor unico en EMPLEADO.');
    WHEN NO_DATA_FOUND THEN
      RAISE_APPLICATION_ERROR(-20002, 'No existe el registro buscado en EMPLEADO.');
    WHEN e_hijos THEN
      RAISE_APPLICATION_ERROR(-20003, 'No se puede borrar: EMPLEADO tiene registros relacionados.');
    WHEN e_padre THEN
      RAISE_APPLICATION_ERROR(-20005, 'Una referencia no existe: revise las llaves de EMPLEADO.');
    WHEN e_check THEN
      RAISE_APPLICATION_ERROR(-20006, 'Un valor no cumple las reglas de validacion de EMPLEADO.');
    WHEN e_nulo THEN
      RAISE_APPLICATION_ERROR(-20007, 'Falta un dato obligatorio en EMPLEADO.');
  END sp_insertar;

  PROCEDURE sp_actualizar(
      p_id_empleado IN empleado.id_empleado%TYPE,
      p_id_zona IN empleado.id_zona%TYPE,
      p_nombre IN empleado.nombre%TYPE,
      p_apellido IN empleado.apellido%TYPE,
      p_correo IN empleado.correo%TYPE,
      p_rol IN empleado.rol%TYPE,
      p_activo IN empleado.activo%TYPE) IS
  BEGIN
    UPDATE empleado
       SET id_zona = p_id_zona,
           nombre = p_nombre,
           apellido = p_apellido,
           correo = p_correo,
           rol = p_rol,
           activo = p_activo
     WHERE id_empleado = p_id_empleado;
    IF SQL%ROWCOUNT = 0 THEN
      RAISE_APPLICATION_ERROR(-20002, 'No existe el registro buscado en EMPLEADO.');
    END IF;
  EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
      RAISE_APPLICATION_ERROR(-20001, 'Ya existe un registro con ese valor unico en EMPLEADO.');
    WHEN NO_DATA_FOUND THEN
      RAISE_APPLICATION_ERROR(-20002, 'No existe el registro buscado en EMPLEADO.');
    WHEN e_hijos THEN
      RAISE_APPLICATION_ERROR(-20003, 'No se puede borrar: EMPLEADO tiene registros relacionados.');
    WHEN e_padre THEN
      RAISE_APPLICATION_ERROR(-20005, 'Una referencia no existe: revise las llaves de EMPLEADO.');
    WHEN e_check THEN
      RAISE_APPLICATION_ERROR(-20006, 'Un valor no cumple las reglas de validacion de EMPLEADO.');
    WHEN e_nulo THEN
      RAISE_APPLICATION_ERROR(-20007, 'Falta un dato obligatorio en EMPLEADO.');
  END sp_actualizar;

  PROCEDURE sp_eliminar(
      p_id_empleado IN empleado.id_empleado%TYPE) IS
  BEGIN
    DELETE FROM empleado WHERE id_empleado = p_id_empleado;
    IF SQL%ROWCOUNT = 0 THEN
      RAISE_APPLICATION_ERROR(-20002, 'No existe el registro buscado en EMPLEADO.');
    END IF;
  EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
      RAISE_APPLICATION_ERROR(-20001, 'Ya existe un registro con ese valor unico en EMPLEADO.');
    WHEN NO_DATA_FOUND THEN
      RAISE_APPLICATION_ERROR(-20002, 'No existe el registro buscado en EMPLEADO.');
    WHEN e_hijos THEN
      RAISE_APPLICATION_ERROR(-20003, 'No se puede borrar: EMPLEADO tiene registros relacionados.');
    WHEN e_padre THEN
      RAISE_APPLICATION_ERROR(-20005, 'Una referencia no existe: revise las llaves de EMPLEADO.');
    WHEN e_check THEN
      RAISE_APPLICATION_ERROR(-20006, 'Un valor no cumple las reglas de validacion de EMPLEADO.');
    WHEN e_nulo THEN
      RAISE_APPLICATION_ERROR(-20007, 'Falta un dato obligatorio en EMPLEADO.');
  END sp_eliminar;

  PROCEDURE sp_obtener(
      p_id_empleado IN empleado.id_empleado%TYPE,
      p_cursor OUT SYS_REFCURSOR) IS
  BEGIN
    OPEN p_cursor FOR
      SELECT id_empleado, id_zona, nombre, apellido, correo, rol, usuario, activo
        FROM empleado
       WHERE id_empleado = p_id_empleado;
  END sp_obtener;

  PROCEDURE sp_listar(
      p_cursor OUT SYS_REFCURSOR) IS
  BEGIN
    OPEN p_cursor FOR
      SELECT id_empleado, id_zona, nombre, apellido, correo, rol, usuario, activo
        FROM empleado
       ORDER BY id_empleado;
  END sp_listar;
END pkg_empleado;
/

CREATE OR REPLACE PACKAGE pkg_cliente AS
  PROCEDURE sp_insertar(
      p_id_zona IN cliente.id_zona%TYPE,
      p_id_vendedor IN cliente.id_vendedor%TYPE,
      p_cedula IN cliente.cedula%TYPE,
      p_nombre_comercial IN cliente.nombre_comercial%TYPE,
      p_correo IN cliente.correo%TYPE,
      p_telefono IN cliente.telefono%TYPE,
      p_direccion IN cliente.direccion%TYPE,
      p_limite_credito IN cliente.limite_credito%TYPE,
      p_dias_credito IN cliente.dias_credito%TYPE,
      p_estado IN cliente.estado%TYPE,
      p_id_cliente OUT cliente.id_cliente%TYPE);
  PROCEDURE sp_actualizar(
      p_id_cliente IN cliente.id_cliente%TYPE,
      p_id_zona IN cliente.id_zona%TYPE,
      p_id_vendedor IN cliente.id_vendedor%TYPE,
      p_cedula IN cliente.cedula%TYPE,
      p_nombre_comercial IN cliente.nombre_comercial%TYPE,
      p_correo IN cliente.correo%TYPE,
      p_telefono IN cliente.telefono%TYPE,
      p_direccion IN cliente.direccion%TYPE,
      p_limite_credito IN cliente.limite_credito%TYPE,
      p_dias_credito IN cliente.dias_credito%TYPE,
      p_estado IN cliente.estado%TYPE);
  PROCEDURE sp_eliminar(
      p_id_cliente IN cliente.id_cliente%TYPE);
  PROCEDURE sp_obtener(
      p_id_cliente IN cliente.id_cliente%TYPE,
      p_cursor OUT SYS_REFCURSOR);
  PROCEDURE sp_listar(
      p_cursor OUT SYS_REFCURSOR);
END pkg_cliente;
/

CREATE OR REPLACE PACKAGE BODY pkg_cliente AS
  e_hijos EXCEPTION;
  PRAGMA EXCEPTION_INIT(e_hijos, -2292);
  e_padre EXCEPTION;
  PRAGMA EXCEPTION_INIT(e_padre, -2291);
  e_check EXCEPTION;
  PRAGMA EXCEPTION_INIT(e_check, -2290);
  e_nulo EXCEPTION;
  PRAGMA EXCEPTION_INIT(e_nulo, -1400);

  PROCEDURE sp_insertar(
      p_id_zona IN cliente.id_zona%TYPE,
      p_id_vendedor IN cliente.id_vendedor%TYPE,
      p_cedula IN cliente.cedula%TYPE,
      p_nombre_comercial IN cliente.nombre_comercial%TYPE,
      p_correo IN cliente.correo%TYPE,
      p_telefono IN cliente.telefono%TYPE,
      p_direccion IN cliente.direccion%TYPE,
      p_limite_credito IN cliente.limite_credito%TYPE,
      p_dias_credito IN cliente.dias_credito%TYPE,
      p_estado IN cliente.estado%TYPE,
      p_id_cliente OUT cliente.id_cliente%TYPE) IS
  BEGIN
    IF NVL(fn_rol_empleado(p_id_vendedor), 'X') <> 'VENDEDOR' THEN
      RAISE_APPLICATION_ERROR(-20030, 'El vendedor no existe o no tiene rol VENDEDOR.');
    END IF;
    INSERT INTO cliente (id_cliente, id_zona, id_vendedor, cedula, nombre_comercial, correo, telefono, direccion, limite_credito, dias_credito, estado)
    VALUES (seq_cliente.NEXTVAL, p_id_zona, p_id_vendedor, p_cedula, p_nombre_comercial, p_correo, p_telefono, p_direccion, NVL(p_limite_credito, 0), NVL(p_dias_credito, 15), NVL(p_estado, 'ACTIVO'))
    RETURNING id_cliente INTO p_id_cliente;
  EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
      RAISE_APPLICATION_ERROR(-20001, 'Ya existe un registro con ese valor unico en CLIENTE.');
    WHEN NO_DATA_FOUND THEN
      RAISE_APPLICATION_ERROR(-20002, 'No existe el registro buscado en CLIENTE.');
    WHEN e_hijos THEN
      RAISE_APPLICATION_ERROR(-20003, 'No se puede borrar: CLIENTE tiene registros relacionados.');
    WHEN e_padre THEN
      RAISE_APPLICATION_ERROR(-20005, 'Una referencia no existe: revise las llaves de CLIENTE.');
    WHEN e_check THEN
      RAISE_APPLICATION_ERROR(-20006, 'Un valor no cumple las reglas de validacion de CLIENTE.');
    WHEN e_nulo THEN
      RAISE_APPLICATION_ERROR(-20007, 'Falta un dato obligatorio en CLIENTE.');
  END sp_insertar;

  PROCEDURE sp_actualizar(
      p_id_cliente IN cliente.id_cliente%TYPE,
      p_id_zona IN cliente.id_zona%TYPE,
      p_id_vendedor IN cliente.id_vendedor%TYPE,
      p_cedula IN cliente.cedula%TYPE,
      p_nombre_comercial IN cliente.nombre_comercial%TYPE,
      p_correo IN cliente.correo%TYPE,
      p_telefono IN cliente.telefono%TYPE,
      p_direccion IN cliente.direccion%TYPE,
      p_limite_credito IN cliente.limite_credito%TYPE,
      p_dias_credito IN cliente.dias_credito%TYPE,
      p_estado IN cliente.estado%TYPE) IS
  BEGIN
    IF NVL(fn_rol_empleado(p_id_vendedor), 'X') <> 'VENDEDOR' THEN
      RAISE_APPLICATION_ERROR(-20030, 'El vendedor no existe o no tiene rol VENDEDOR.');
    END IF;
    UPDATE cliente
       SET id_zona = p_id_zona,
           id_vendedor = p_id_vendedor,
           cedula = p_cedula,
           nombre_comercial = p_nombre_comercial,
           correo = p_correo,
           telefono = p_telefono,
           direccion = p_direccion,
           limite_credito = p_limite_credito,
           dias_credito = p_dias_credito,
           estado = p_estado
     WHERE id_cliente = p_id_cliente;
    IF SQL%ROWCOUNT = 0 THEN
      RAISE_APPLICATION_ERROR(-20002, 'No existe el registro buscado en CLIENTE.');
    END IF;
  EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
      RAISE_APPLICATION_ERROR(-20001, 'Ya existe un registro con ese valor unico en CLIENTE.');
    WHEN NO_DATA_FOUND THEN
      RAISE_APPLICATION_ERROR(-20002, 'No existe el registro buscado en CLIENTE.');
    WHEN e_hijos THEN
      RAISE_APPLICATION_ERROR(-20003, 'No se puede borrar: CLIENTE tiene registros relacionados.');
    WHEN e_padre THEN
      RAISE_APPLICATION_ERROR(-20005, 'Una referencia no existe: revise las llaves de CLIENTE.');
    WHEN e_check THEN
      RAISE_APPLICATION_ERROR(-20006, 'Un valor no cumple las reglas de validacion de CLIENTE.');
    WHEN e_nulo THEN
      RAISE_APPLICATION_ERROR(-20007, 'Falta un dato obligatorio en CLIENTE.');
  END sp_actualizar;

  PROCEDURE sp_eliminar(
      p_id_cliente IN cliente.id_cliente%TYPE) IS
  BEGIN
    DELETE FROM cliente WHERE id_cliente = p_id_cliente;
    IF SQL%ROWCOUNT = 0 THEN
      RAISE_APPLICATION_ERROR(-20002, 'No existe el registro buscado en CLIENTE.');
    END IF;
  EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
      RAISE_APPLICATION_ERROR(-20001, 'Ya existe un registro con ese valor unico en CLIENTE.');
    WHEN NO_DATA_FOUND THEN
      RAISE_APPLICATION_ERROR(-20002, 'No existe el registro buscado en CLIENTE.');
    WHEN e_hijos THEN
      RAISE_APPLICATION_ERROR(-20003, 'No se puede borrar: CLIENTE tiene registros relacionados.');
    WHEN e_padre THEN
      RAISE_APPLICATION_ERROR(-20005, 'Una referencia no existe: revise las llaves de CLIENTE.');
    WHEN e_check THEN
      RAISE_APPLICATION_ERROR(-20006, 'Un valor no cumple las reglas de validacion de CLIENTE.');
    WHEN e_nulo THEN
      RAISE_APPLICATION_ERROR(-20007, 'Falta un dato obligatorio en CLIENTE.');
  END sp_eliminar;

  PROCEDURE sp_obtener(
      p_id_cliente IN cliente.id_cliente%TYPE,
      p_cursor OUT SYS_REFCURSOR) IS
  BEGIN
    OPEN p_cursor FOR
      SELECT id_cliente, id_zona, id_vendedor, cedula, nombre_comercial, correo, telefono, direccion, limite_credito, dias_credito, estado
        FROM cliente
       WHERE id_cliente = p_id_cliente;
  END sp_obtener;

  PROCEDURE sp_listar(
      p_cursor OUT SYS_REFCURSOR) IS
  BEGIN
    OPEN p_cursor FOR
      SELECT id_cliente, id_zona, id_vendedor, cedula, nombre_comercial, correo, telefono, direccion, limite_credito, dias_credito, estado
        FROM cliente
       ORDER BY id_cliente;
  END sp_listar;
END pkg_cliente;
/

CREATE OR REPLACE PACKAGE pkg_categoria AS
  PROCEDURE sp_insertar(
      p_nombre_categoria IN categoria.nombre_categoria%TYPE,
      p_id_categoria OUT categoria.id_categoria%TYPE);
  PROCEDURE sp_actualizar(
      p_id_categoria IN categoria.id_categoria%TYPE,
      p_nombre_categoria IN categoria.nombre_categoria%TYPE);
  PROCEDURE sp_eliminar(
      p_id_categoria IN categoria.id_categoria%TYPE);
  PROCEDURE sp_obtener(
      p_id_categoria IN categoria.id_categoria%TYPE,
      p_cursor OUT SYS_REFCURSOR);
  PROCEDURE sp_listar(
      p_cursor OUT SYS_REFCURSOR);
END pkg_categoria;
/

CREATE OR REPLACE PACKAGE BODY pkg_categoria AS
  e_hijos EXCEPTION;
  PRAGMA EXCEPTION_INIT(e_hijos, -2292);
  e_padre EXCEPTION;
  PRAGMA EXCEPTION_INIT(e_padre, -2291);
  e_check EXCEPTION;
  PRAGMA EXCEPTION_INIT(e_check, -2290);
  e_nulo EXCEPTION;
  PRAGMA EXCEPTION_INIT(e_nulo, -1400);

  PROCEDURE sp_insertar(
      p_nombre_categoria IN categoria.nombre_categoria%TYPE,
      p_id_categoria OUT categoria.id_categoria%TYPE) IS
  BEGIN
    INSERT INTO categoria (id_categoria, nombre_categoria)
    VALUES (seq_categoria.NEXTVAL, p_nombre_categoria)
    RETURNING id_categoria INTO p_id_categoria;
  EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
      RAISE_APPLICATION_ERROR(-20001, 'Ya existe un registro con ese valor unico en CATEGORIA.');
    WHEN NO_DATA_FOUND THEN
      RAISE_APPLICATION_ERROR(-20002, 'No existe el registro buscado en CATEGORIA.');
    WHEN e_hijos THEN
      RAISE_APPLICATION_ERROR(-20003, 'No se puede borrar: CATEGORIA tiene registros relacionados.');
    WHEN e_padre THEN
      RAISE_APPLICATION_ERROR(-20005, 'Una referencia no existe: revise las llaves de CATEGORIA.');
    WHEN e_check THEN
      RAISE_APPLICATION_ERROR(-20006, 'Un valor no cumple las reglas de validacion de CATEGORIA.');
    WHEN e_nulo THEN
      RAISE_APPLICATION_ERROR(-20007, 'Falta un dato obligatorio en CATEGORIA.');
  END sp_insertar;

  PROCEDURE sp_actualizar(
      p_id_categoria IN categoria.id_categoria%TYPE,
      p_nombre_categoria IN categoria.nombre_categoria%TYPE) IS
  BEGIN
    UPDATE categoria
       SET nombre_categoria = p_nombre_categoria
     WHERE id_categoria = p_id_categoria;
    IF SQL%ROWCOUNT = 0 THEN
      RAISE_APPLICATION_ERROR(-20002, 'No existe el registro buscado en CATEGORIA.');
    END IF;
  EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
      RAISE_APPLICATION_ERROR(-20001, 'Ya existe un registro con ese valor unico en CATEGORIA.');
    WHEN NO_DATA_FOUND THEN
      RAISE_APPLICATION_ERROR(-20002, 'No existe el registro buscado en CATEGORIA.');
    WHEN e_hijos THEN
      RAISE_APPLICATION_ERROR(-20003, 'No se puede borrar: CATEGORIA tiene registros relacionados.');
    WHEN e_padre THEN
      RAISE_APPLICATION_ERROR(-20005, 'Una referencia no existe: revise las llaves de CATEGORIA.');
    WHEN e_check THEN
      RAISE_APPLICATION_ERROR(-20006, 'Un valor no cumple las reglas de validacion de CATEGORIA.');
    WHEN e_nulo THEN
      RAISE_APPLICATION_ERROR(-20007, 'Falta un dato obligatorio en CATEGORIA.');
  END sp_actualizar;

  PROCEDURE sp_eliminar(
      p_id_categoria IN categoria.id_categoria%TYPE) IS
  BEGIN
    DELETE FROM categoria WHERE id_categoria = p_id_categoria;
    IF SQL%ROWCOUNT = 0 THEN
      RAISE_APPLICATION_ERROR(-20002, 'No existe el registro buscado en CATEGORIA.');
    END IF;
  EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
      RAISE_APPLICATION_ERROR(-20001, 'Ya existe un registro con ese valor unico en CATEGORIA.');
    WHEN NO_DATA_FOUND THEN
      RAISE_APPLICATION_ERROR(-20002, 'No existe el registro buscado en CATEGORIA.');
    WHEN e_hijos THEN
      RAISE_APPLICATION_ERROR(-20003, 'No se puede borrar: CATEGORIA tiene registros relacionados.');
    WHEN e_padre THEN
      RAISE_APPLICATION_ERROR(-20005, 'Una referencia no existe: revise las llaves de CATEGORIA.');
    WHEN e_check THEN
      RAISE_APPLICATION_ERROR(-20006, 'Un valor no cumple las reglas de validacion de CATEGORIA.');
    WHEN e_nulo THEN
      RAISE_APPLICATION_ERROR(-20007, 'Falta un dato obligatorio en CATEGORIA.');
  END sp_eliminar;

  PROCEDURE sp_obtener(
      p_id_categoria IN categoria.id_categoria%TYPE,
      p_cursor OUT SYS_REFCURSOR) IS
  BEGIN
    OPEN p_cursor FOR
      SELECT id_categoria, nombre_categoria
        FROM categoria
       WHERE id_categoria = p_id_categoria;
  END sp_obtener;

  PROCEDURE sp_listar(
      p_cursor OUT SYS_REFCURSOR) IS
  BEGIN
    OPEN p_cursor FOR
      SELECT id_categoria, nombre_categoria
        FROM categoria
       ORDER BY id_categoria;
  END sp_listar;
END pkg_categoria;
/

CREATE OR REPLACE PACKAGE pkg_producto AS
  PROCEDURE sp_insertar(
      p_id_categoria IN producto.id_categoria%TYPE,
      p_codigo IN producto.codigo%TYPE,
      p_nombre_producto IN producto.nombre_producto%TYPE,
      p_precio_unitario IN producto.precio_unitario%TYPE,
      p_stock_actual IN producto.stock_actual%TYPE,
      p_activo IN producto.activo%TYPE,
      p_id_producto OUT producto.id_producto%TYPE);
  PROCEDURE sp_actualizar(
      p_id_producto IN producto.id_producto%TYPE,
      p_id_categoria IN producto.id_categoria%TYPE,
      p_codigo IN producto.codigo%TYPE,
      p_nombre_producto IN producto.nombre_producto%TYPE,
      p_precio_unitario IN producto.precio_unitario%TYPE,
      p_activo IN producto.activo%TYPE);
  PROCEDURE sp_eliminar(
      p_id_producto IN producto.id_producto%TYPE);
  PROCEDURE sp_obtener(
      p_id_producto IN producto.id_producto%TYPE,
      p_cursor OUT SYS_REFCURSOR);
  PROCEDURE sp_listar(
      p_cursor OUT SYS_REFCURSOR);
END pkg_producto;
/

CREATE OR REPLACE PACKAGE BODY pkg_producto AS
  e_hijos EXCEPTION;
  PRAGMA EXCEPTION_INIT(e_hijos, -2292);
  e_padre EXCEPTION;
  PRAGMA EXCEPTION_INIT(e_padre, -2291);
  e_check EXCEPTION;
  PRAGMA EXCEPTION_INIT(e_check, -2290);
  e_nulo EXCEPTION;
  PRAGMA EXCEPTION_INIT(e_nulo, -1400);

  PROCEDURE sp_insertar(
      p_id_categoria IN producto.id_categoria%TYPE,
      p_codigo IN producto.codigo%TYPE,
      p_nombre_producto IN producto.nombre_producto%TYPE,
      p_precio_unitario IN producto.precio_unitario%TYPE,
      p_stock_actual IN producto.stock_actual%TYPE,
      p_activo IN producto.activo%TYPE,
      p_id_producto OUT producto.id_producto%TYPE) IS
  BEGIN
    INSERT INTO producto (id_producto, id_categoria, codigo, nombre_producto, precio_unitario, stock_actual, activo)
    VALUES (seq_producto.NEXTVAL, p_id_categoria, p_codigo, p_nombre_producto, p_precio_unitario, NVL(p_stock_actual, 0), NVL(p_activo, 1))
    RETURNING id_producto INTO p_id_producto;
  EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
      RAISE_APPLICATION_ERROR(-20001, 'Ya existe un registro con ese valor unico en PRODUCTO.');
    WHEN NO_DATA_FOUND THEN
      RAISE_APPLICATION_ERROR(-20002, 'No existe el registro buscado en PRODUCTO.');
    WHEN e_hijos THEN
      RAISE_APPLICATION_ERROR(-20003, 'No se puede borrar: PRODUCTO tiene registros relacionados.');
    WHEN e_padre THEN
      RAISE_APPLICATION_ERROR(-20005, 'Una referencia no existe: revise las llaves de PRODUCTO.');
    WHEN e_check THEN
      RAISE_APPLICATION_ERROR(-20006, 'Un valor no cumple las reglas de validacion de PRODUCTO.');
    WHEN e_nulo THEN
      RAISE_APPLICATION_ERROR(-20007, 'Falta un dato obligatorio en PRODUCTO.');
  END sp_insertar;

  PROCEDURE sp_actualizar(
      p_id_producto IN producto.id_producto%TYPE,
      p_id_categoria IN producto.id_categoria%TYPE,
      p_codigo IN producto.codigo%TYPE,
      p_nombre_producto IN producto.nombre_producto%TYPE,
      p_precio_unitario IN producto.precio_unitario%TYPE,
      p_activo IN producto.activo%TYPE) IS
  BEGIN
    UPDATE producto
       SET id_categoria = p_id_categoria,
           codigo = p_codigo,
           nombre_producto = p_nombre_producto,
           precio_unitario = p_precio_unitario,
           activo = p_activo
     WHERE id_producto = p_id_producto;
    IF SQL%ROWCOUNT = 0 THEN
      RAISE_APPLICATION_ERROR(-20002, 'No existe el registro buscado en PRODUCTO.');
    END IF;
  EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
      RAISE_APPLICATION_ERROR(-20001, 'Ya existe un registro con ese valor unico en PRODUCTO.');
    WHEN NO_DATA_FOUND THEN
      RAISE_APPLICATION_ERROR(-20002, 'No existe el registro buscado en PRODUCTO.');
    WHEN e_hijos THEN
      RAISE_APPLICATION_ERROR(-20003, 'No se puede borrar: PRODUCTO tiene registros relacionados.');
    WHEN e_padre THEN
      RAISE_APPLICATION_ERROR(-20005, 'Una referencia no existe: revise las llaves de PRODUCTO.');
    WHEN e_check THEN
      RAISE_APPLICATION_ERROR(-20006, 'Un valor no cumple las reglas de validacion de PRODUCTO.');
    WHEN e_nulo THEN
      RAISE_APPLICATION_ERROR(-20007, 'Falta un dato obligatorio en PRODUCTO.');
  END sp_actualizar;

  PROCEDURE sp_eliminar(
      p_id_producto IN producto.id_producto%TYPE) IS
  BEGIN
    DELETE FROM producto WHERE id_producto = p_id_producto;
    IF SQL%ROWCOUNT = 0 THEN
      RAISE_APPLICATION_ERROR(-20002, 'No existe el registro buscado en PRODUCTO.');
    END IF;
  EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
      RAISE_APPLICATION_ERROR(-20001, 'Ya existe un registro con ese valor unico en PRODUCTO.');
    WHEN NO_DATA_FOUND THEN
      RAISE_APPLICATION_ERROR(-20002, 'No existe el registro buscado en PRODUCTO.');
    WHEN e_hijos THEN
      RAISE_APPLICATION_ERROR(-20003, 'No se puede borrar: PRODUCTO tiene registros relacionados.');
    WHEN e_padre THEN
      RAISE_APPLICATION_ERROR(-20005, 'Una referencia no existe: revise las llaves de PRODUCTO.');
    WHEN e_check THEN
      RAISE_APPLICATION_ERROR(-20006, 'Un valor no cumple las reglas de validacion de PRODUCTO.');
    WHEN e_nulo THEN
      RAISE_APPLICATION_ERROR(-20007, 'Falta un dato obligatorio en PRODUCTO.');
  END sp_eliminar;

  PROCEDURE sp_obtener(
      p_id_producto IN producto.id_producto%TYPE,
      p_cursor OUT SYS_REFCURSOR) IS
  BEGIN
    OPEN p_cursor FOR
      SELECT id_producto, id_categoria, codigo, nombre_producto, precio_unitario, stock_actual, activo
        FROM producto
       WHERE id_producto = p_id_producto;
  END sp_obtener;

  PROCEDURE sp_listar(
      p_cursor OUT SYS_REFCURSOR) IS
  BEGIN
    OPEN p_cursor FOR
      SELECT id_producto, id_categoria, codigo, nombre_producto, precio_unitario, stock_actual, activo
        FROM producto
       ORDER BY id_producto;
  END sp_listar;
END pkg_producto;
/

CREATE OR REPLACE PACKAGE pkg_metodo_pago AS
  PROCEDURE sp_insertar(
      p_nombre_metodo IN metodo_pago.nombre_metodo%TYPE,
      p_id_metodo_pago OUT metodo_pago.id_metodo_pago%TYPE);
  PROCEDURE sp_actualizar(
      p_id_metodo_pago IN metodo_pago.id_metodo_pago%TYPE,
      p_nombre_metodo IN metodo_pago.nombre_metodo%TYPE);
  PROCEDURE sp_eliminar(
      p_id_metodo_pago IN metodo_pago.id_metodo_pago%TYPE);
  PROCEDURE sp_obtener(
      p_id_metodo_pago IN metodo_pago.id_metodo_pago%TYPE,
      p_cursor OUT SYS_REFCURSOR);
  PROCEDURE sp_listar(
      p_cursor OUT SYS_REFCURSOR);
END pkg_metodo_pago;
/

CREATE OR REPLACE PACKAGE BODY pkg_metodo_pago AS
  e_hijos EXCEPTION;
  PRAGMA EXCEPTION_INIT(e_hijos, -2292);
  e_padre EXCEPTION;
  PRAGMA EXCEPTION_INIT(e_padre, -2291);
  e_check EXCEPTION;
  PRAGMA EXCEPTION_INIT(e_check, -2290);
  e_nulo EXCEPTION;
  PRAGMA EXCEPTION_INIT(e_nulo, -1400);

  PROCEDURE sp_insertar(
      p_nombre_metodo IN metodo_pago.nombre_metodo%TYPE,
      p_id_metodo_pago OUT metodo_pago.id_metodo_pago%TYPE) IS
  BEGIN
    INSERT INTO metodo_pago (id_metodo_pago, nombre_metodo)
    VALUES (seq_metodo_pago.NEXTVAL, p_nombre_metodo)
    RETURNING id_metodo_pago INTO p_id_metodo_pago;
  EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
      RAISE_APPLICATION_ERROR(-20001, 'Ya existe un registro con ese valor unico en METODO_PAGO.');
    WHEN NO_DATA_FOUND THEN
      RAISE_APPLICATION_ERROR(-20002, 'No existe el registro buscado en METODO_PAGO.');
    WHEN e_hijos THEN
      RAISE_APPLICATION_ERROR(-20003, 'No se puede borrar: METODO_PAGO tiene registros relacionados.');
    WHEN e_padre THEN
      RAISE_APPLICATION_ERROR(-20005, 'Una referencia no existe: revise las llaves de METODO_PAGO.');
    WHEN e_check THEN
      RAISE_APPLICATION_ERROR(-20006, 'Un valor no cumple las reglas de validacion de METODO_PAGO.');
    WHEN e_nulo THEN
      RAISE_APPLICATION_ERROR(-20007, 'Falta un dato obligatorio en METODO_PAGO.');
  END sp_insertar;

  PROCEDURE sp_actualizar(
      p_id_metodo_pago IN metodo_pago.id_metodo_pago%TYPE,
      p_nombre_metodo IN metodo_pago.nombre_metodo%TYPE) IS
  BEGIN
    UPDATE metodo_pago
       SET nombre_metodo = p_nombre_metodo
     WHERE id_metodo_pago = p_id_metodo_pago;
    IF SQL%ROWCOUNT = 0 THEN
      RAISE_APPLICATION_ERROR(-20002, 'No existe el registro buscado en METODO_PAGO.');
    END IF;
  EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
      RAISE_APPLICATION_ERROR(-20001, 'Ya existe un registro con ese valor unico en METODO_PAGO.');
    WHEN NO_DATA_FOUND THEN
      RAISE_APPLICATION_ERROR(-20002, 'No existe el registro buscado en METODO_PAGO.');
    WHEN e_hijos THEN
      RAISE_APPLICATION_ERROR(-20003, 'No se puede borrar: METODO_PAGO tiene registros relacionados.');
    WHEN e_padre THEN
      RAISE_APPLICATION_ERROR(-20005, 'Una referencia no existe: revise las llaves de METODO_PAGO.');
    WHEN e_check THEN
      RAISE_APPLICATION_ERROR(-20006, 'Un valor no cumple las reglas de validacion de METODO_PAGO.');
    WHEN e_nulo THEN
      RAISE_APPLICATION_ERROR(-20007, 'Falta un dato obligatorio en METODO_PAGO.');
  END sp_actualizar;

  PROCEDURE sp_eliminar(
      p_id_metodo_pago IN metodo_pago.id_metodo_pago%TYPE) IS
  BEGIN
    DELETE FROM metodo_pago WHERE id_metodo_pago = p_id_metodo_pago;
    IF SQL%ROWCOUNT = 0 THEN
      RAISE_APPLICATION_ERROR(-20002, 'No existe el registro buscado en METODO_PAGO.');
    END IF;
  EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
      RAISE_APPLICATION_ERROR(-20001, 'Ya existe un registro con ese valor unico en METODO_PAGO.');
    WHEN NO_DATA_FOUND THEN
      RAISE_APPLICATION_ERROR(-20002, 'No existe el registro buscado en METODO_PAGO.');
    WHEN e_hijos THEN
      RAISE_APPLICATION_ERROR(-20003, 'No se puede borrar: METODO_PAGO tiene registros relacionados.');
    WHEN e_padre THEN
      RAISE_APPLICATION_ERROR(-20005, 'Una referencia no existe: revise las llaves de METODO_PAGO.');
    WHEN e_check THEN
      RAISE_APPLICATION_ERROR(-20006, 'Un valor no cumple las reglas de validacion de METODO_PAGO.');
    WHEN e_nulo THEN
      RAISE_APPLICATION_ERROR(-20007, 'Falta un dato obligatorio en METODO_PAGO.');
  END sp_eliminar;

  PROCEDURE sp_obtener(
      p_id_metodo_pago IN metodo_pago.id_metodo_pago%TYPE,
      p_cursor OUT SYS_REFCURSOR) IS
  BEGIN
    OPEN p_cursor FOR
      SELECT id_metodo_pago, nombre_metodo
        FROM metodo_pago
       WHERE id_metodo_pago = p_id_metodo_pago;
  END sp_obtener;

  PROCEDURE sp_listar(
      p_cursor OUT SYS_REFCURSOR) IS
  BEGIN
    OPEN p_cursor FOR
      SELECT id_metodo_pago, nombre_metodo
        FROM metodo_pago
       ORDER BY id_metodo_pago;
  END sp_listar;
END pkg_metodo_pago;
/

CREATE OR REPLACE PACKAGE pkg_factura AS
  PROCEDURE sp_insertar(
      p_id_cliente IN factura.id_cliente%TYPE,
      p_id_empleado IN factura.id_empleado%TYPE,
      p_fecha_emision IN factura.fecha_emision%TYPE,
      p_id_factura OUT factura.id_factura%TYPE);
  PROCEDURE sp_actualizar(
      p_id_factura IN factura.id_factura%TYPE,
      p_id_empleado IN factura.id_empleado%TYPE,
      p_fecha_vencimiento IN factura.fecha_vencimiento%TYPE);
  PROCEDURE sp_eliminar(
      p_id_factura IN factura.id_factura%TYPE);
  PROCEDURE sp_obtener(
      p_id_factura IN factura.id_factura%TYPE,
      p_cursor OUT SYS_REFCURSOR);
  PROCEDURE sp_listar(
      p_cursor OUT SYS_REFCURSOR);
END pkg_factura;
/

CREATE OR REPLACE PACKAGE BODY pkg_factura AS
  e_hijos EXCEPTION;
  PRAGMA EXCEPTION_INIT(e_hijos, -2292);
  e_padre EXCEPTION;
  PRAGMA EXCEPTION_INIT(e_padre, -2291);
  e_check EXCEPTION;
  PRAGMA EXCEPTION_INIT(e_check, -2290);
  e_nulo EXCEPTION;
  PRAGMA EXCEPTION_INIT(e_nulo, -1400);

  PROCEDURE sp_insertar(
      p_id_cliente IN factura.id_cliente%TYPE,
      p_id_empleado IN factura.id_empleado%TYPE,
      p_fecha_emision IN factura.fecha_emision%TYPE,
      p_id_factura OUT factura.id_factura%TYPE) IS
  BEGIN
    IF NVL(fn_estado_cliente(p_id_cliente), 'X') <> 'ACTIVO' THEN
      RAISE_APPLICATION_ERROR(-20040, 'Solo se puede facturar a clientes ACTIVOS.');
    END IF;
    INSERT INTO factura (id_factura, id_cliente, id_empleado, numero_factura, fecha_emision, fecha_vencimiento, monto_total, saldo_pendiente, estado)
    VALUES (seq_factura.NEXTVAL, p_id_cliente, p_id_empleado, fn_siguiente_numero_factura, NVL(p_fecha_emision, TRUNC(SYSDATE)), fn_fecha_vencimiento(p_id_cliente, NVL(p_fecha_emision, TRUNC(SYSDATE))), 0, 0, 'PENDIENTE')
    RETURNING id_factura INTO p_id_factura;
  EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
      RAISE_APPLICATION_ERROR(-20001, 'Ya existe un registro con ese valor unico en FACTURA.');
    WHEN NO_DATA_FOUND THEN
      RAISE_APPLICATION_ERROR(-20002, 'No existe el registro buscado en FACTURA.');
    WHEN e_hijos THEN
      RAISE_APPLICATION_ERROR(-20003, 'No se puede borrar: FACTURA tiene registros relacionados.');
    WHEN e_padre THEN
      RAISE_APPLICATION_ERROR(-20005, 'Una referencia no existe: revise las llaves de FACTURA.');
    WHEN e_check THEN
      RAISE_APPLICATION_ERROR(-20006, 'Un valor no cumple las reglas de validacion de FACTURA.');
    WHEN e_nulo THEN
      RAISE_APPLICATION_ERROR(-20007, 'Falta un dato obligatorio en FACTURA.');
  END sp_insertar;

  PROCEDURE sp_actualizar(
      p_id_factura IN factura.id_factura%TYPE,
      p_id_empleado IN factura.id_empleado%TYPE,
      p_fecha_vencimiento IN factura.fecha_vencimiento%TYPE) IS
  BEGIN
    IF NVL(fn_estado_factura(p_id_factura), 'X') = 'ANULADA' THEN
      RAISE_APPLICATION_ERROR(-20041, 'Una factura anulada no se puede modificar.');
    END IF;
    UPDATE factura
       SET id_empleado = p_id_empleado,
           fecha_vencimiento = p_fecha_vencimiento
     WHERE id_factura = p_id_factura;
    IF SQL%ROWCOUNT = 0 THEN
      RAISE_APPLICATION_ERROR(-20002, 'No existe el registro buscado en FACTURA.');
    END IF;
  EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
      RAISE_APPLICATION_ERROR(-20001, 'Ya existe un registro con ese valor unico en FACTURA.');
    WHEN NO_DATA_FOUND THEN
      RAISE_APPLICATION_ERROR(-20002, 'No existe el registro buscado en FACTURA.');
    WHEN e_hijos THEN
      RAISE_APPLICATION_ERROR(-20003, 'No se puede borrar: FACTURA tiene registros relacionados.');
    WHEN e_padre THEN
      RAISE_APPLICATION_ERROR(-20005, 'Una referencia no existe: revise las llaves de FACTURA.');
    WHEN e_check THEN
      RAISE_APPLICATION_ERROR(-20006, 'Un valor no cumple las reglas de validacion de FACTURA.');
    WHEN e_nulo THEN
      RAISE_APPLICATION_ERROR(-20007, 'Falta un dato obligatorio en FACTURA.');
  END sp_actualizar;

  PROCEDURE sp_eliminar(
      p_id_factura IN factura.id_factura%TYPE) IS
  BEGIN
    DELETE FROM factura WHERE id_factura = p_id_factura;
    IF SQL%ROWCOUNT = 0 THEN
      RAISE_APPLICATION_ERROR(-20002, 'No existe el registro buscado en FACTURA.');
    END IF;
  EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
      RAISE_APPLICATION_ERROR(-20001, 'Ya existe un registro con ese valor unico en FACTURA.');
    WHEN NO_DATA_FOUND THEN
      RAISE_APPLICATION_ERROR(-20002, 'No existe el registro buscado en FACTURA.');
    WHEN e_hijos THEN
      RAISE_APPLICATION_ERROR(-20003, 'No se puede borrar: FACTURA tiene registros relacionados.');
    WHEN e_padre THEN
      RAISE_APPLICATION_ERROR(-20005, 'Una referencia no existe: revise las llaves de FACTURA.');
    WHEN e_check THEN
      RAISE_APPLICATION_ERROR(-20006, 'Un valor no cumple las reglas de validacion de FACTURA.');
    WHEN e_nulo THEN
      RAISE_APPLICATION_ERROR(-20007, 'Falta un dato obligatorio en FACTURA.');
  END sp_eliminar;

  PROCEDURE sp_obtener(
      p_id_factura IN factura.id_factura%TYPE,
      p_cursor OUT SYS_REFCURSOR) IS
  BEGIN
    OPEN p_cursor FOR
      SELECT id_factura, id_cliente, id_empleado, numero_factura, fecha_emision, fecha_vencimiento, monto_total, saldo_pendiente, estado
        FROM factura
       WHERE id_factura = p_id_factura;
  END sp_obtener;

  PROCEDURE sp_listar(
      p_cursor OUT SYS_REFCURSOR) IS
  BEGIN
    OPEN p_cursor FOR
      SELECT id_factura, id_cliente, id_empleado, numero_factura, fecha_emision, fecha_vencimiento, monto_total, saldo_pendiente, estado
        FROM factura
       ORDER BY id_factura;
  END sp_listar;
END pkg_factura;
/

CREATE OR REPLACE PACKAGE pkg_detalle_factura AS
  PROCEDURE sp_insertar(
      p_id_factura IN detalle_factura.id_factura%TYPE,
      p_id_producto IN detalle_factura.id_producto%TYPE,
      p_cantidad IN detalle_factura.cantidad%TYPE,
      p_precio_unitario IN detalle_factura.precio_unitario%TYPE);
  PROCEDURE sp_actualizar(
      p_id_factura IN detalle_factura.id_factura%TYPE,
      p_id_producto IN detalle_factura.id_producto%TYPE,
      p_cantidad IN detalle_factura.cantidad%TYPE,
      p_precio_unitario IN detalle_factura.precio_unitario%TYPE);
  PROCEDURE sp_eliminar(
      p_id_factura IN detalle_factura.id_factura%TYPE,
      p_id_producto IN detalle_factura.id_producto%TYPE);
  PROCEDURE sp_obtener(
      p_id_factura IN detalle_factura.id_factura%TYPE,
      p_id_producto IN detalle_factura.id_producto%TYPE,
      p_cursor OUT SYS_REFCURSOR);
  PROCEDURE sp_listar(
      p_cursor OUT SYS_REFCURSOR);
END pkg_detalle_factura;
/

CREATE OR REPLACE PACKAGE BODY pkg_detalle_factura AS
  e_hijos EXCEPTION;
  PRAGMA EXCEPTION_INIT(e_hijos, -2292);
  e_padre EXCEPTION;
  PRAGMA EXCEPTION_INIT(e_padre, -2291);
  e_check EXCEPTION;
  PRAGMA EXCEPTION_INIT(e_check, -2290);
  e_nulo EXCEPTION;
  PRAGMA EXCEPTION_INIT(e_nulo, -1400);

  PROCEDURE sp_insertar(
      p_id_factura IN detalle_factura.id_factura%TYPE,
      p_id_producto IN detalle_factura.id_producto%TYPE,
      p_cantidad IN detalle_factura.cantidad%TYPE,
      p_precio_unitario IN detalle_factura.precio_unitario%TYPE) IS
  BEGIN
    IF NVL(fn_estado_factura(p_id_factura), 'X') <> 'PENDIENTE' THEN
      RAISE_APPLICATION_ERROR(-20050, 'Solo se puede agregar detalle a facturas PENDIENTES.');
    END IF;
    IF fn_stock_producto(p_id_producto) < p_cantidad THEN
      RAISE_APPLICATION_ERROR(-20051, 'No hay existencias suficientes del producto.');
    END IF;
    INSERT INTO detalle_factura (id_factura, id_producto, cantidad, precio_unitario)
    VALUES (p_id_factura, p_id_producto, p_cantidad, NVL(p_precio_unitario, fn_precio_producto(p_id_producto)));
    sp_recalcular_factura(p_id_factura);
  EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
      RAISE_APPLICATION_ERROR(-20001, 'Ya existe un registro con ese valor unico en DETALLE_FACTURA.');
    WHEN NO_DATA_FOUND THEN
      RAISE_APPLICATION_ERROR(-20002, 'No existe el registro buscado en DETALLE_FACTURA.');
    WHEN e_hijos THEN
      RAISE_APPLICATION_ERROR(-20003, 'No se puede borrar: DETALLE_FACTURA tiene registros relacionados.');
    WHEN e_padre THEN
      RAISE_APPLICATION_ERROR(-20005, 'Una referencia no existe: revise las llaves de DETALLE_FACTURA.');
    WHEN e_check THEN
      RAISE_APPLICATION_ERROR(-20006, 'Un valor no cumple las reglas de validacion de DETALLE_FACTURA.');
    WHEN e_nulo THEN
      RAISE_APPLICATION_ERROR(-20007, 'Falta un dato obligatorio en DETALLE_FACTURA.');
  END sp_insertar;

  PROCEDURE sp_actualizar(
      p_id_factura IN detalle_factura.id_factura%TYPE,
      p_id_producto IN detalle_factura.id_producto%TYPE,
      p_cantidad IN detalle_factura.cantidad%TYPE,
      p_precio_unitario IN detalle_factura.precio_unitario%TYPE) IS
    v_cantidad_actual detalle_factura.cantidad%TYPE;
  BEGIN
    IF NVL(fn_estado_factura(p_id_factura), 'X') <> 'PENDIENTE' THEN
      RAISE_APPLICATION_ERROR(-20050, 'Solo se puede modificar el detalle de facturas PENDIENTES.');
    END IF;
    SELECT cantidad INTO v_cantidad_actual
      FROM detalle_factura
     WHERE id_factura = p_id_factura AND id_producto = p_id_producto;
    IF p_cantidad > v_cantidad_actual
       AND fn_stock_producto(p_id_producto) < p_cantidad - v_cantidad_actual THEN
      RAISE_APPLICATION_ERROR(-20051, 'No hay existencias suficientes del producto.');
    END IF;
    UPDATE detalle_factura
       SET cantidad = p_cantidad,
           precio_unitario = p_precio_unitario
     WHERE id_factura = p_id_factura AND id_producto = p_id_producto;
    IF SQL%ROWCOUNT = 0 THEN
      RAISE_APPLICATION_ERROR(-20002, 'No existe el registro buscado en DETALLE_FACTURA.');
    END IF;
    sp_recalcular_factura(p_id_factura);
  EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
      RAISE_APPLICATION_ERROR(-20001, 'Ya existe un registro con ese valor unico en DETALLE_FACTURA.');
    WHEN NO_DATA_FOUND THEN
      RAISE_APPLICATION_ERROR(-20002, 'No existe el registro buscado en DETALLE_FACTURA.');
    WHEN e_hijos THEN
      RAISE_APPLICATION_ERROR(-20003, 'No se puede borrar: DETALLE_FACTURA tiene registros relacionados.');
    WHEN e_padre THEN
      RAISE_APPLICATION_ERROR(-20005, 'Una referencia no existe: revise las llaves de DETALLE_FACTURA.');
    WHEN e_check THEN
      RAISE_APPLICATION_ERROR(-20006, 'Un valor no cumple las reglas de validacion de DETALLE_FACTURA.');
    WHEN e_nulo THEN
      RAISE_APPLICATION_ERROR(-20007, 'Falta un dato obligatorio en DETALLE_FACTURA.');
  END sp_actualizar;

  PROCEDURE sp_eliminar(
      p_id_factura IN detalle_factura.id_factura%TYPE,
      p_id_producto IN detalle_factura.id_producto%TYPE) IS
  BEGIN
    IF NVL(fn_estado_factura(p_id_factura), 'X') <> 'PENDIENTE' THEN
      RAISE_APPLICATION_ERROR(-20050, 'Solo se puede quitar detalle de facturas PENDIENTES.');
    END IF;
    DELETE FROM detalle_factura WHERE id_factura = p_id_factura AND id_producto = p_id_producto;
    IF SQL%ROWCOUNT = 0 THEN
      RAISE_APPLICATION_ERROR(-20002, 'No existe el registro buscado en DETALLE_FACTURA.');
    END IF;
    sp_recalcular_factura(p_id_factura);
  EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
      RAISE_APPLICATION_ERROR(-20001, 'Ya existe un registro con ese valor unico en DETALLE_FACTURA.');
    WHEN NO_DATA_FOUND THEN
      RAISE_APPLICATION_ERROR(-20002, 'No existe el registro buscado en DETALLE_FACTURA.');
    WHEN e_hijos THEN
      RAISE_APPLICATION_ERROR(-20003, 'No se puede borrar: DETALLE_FACTURA tiene registros relacionados.');
    WHEN e_padre THEN
      RAISE_APPLICATION_ERROR(-20005, 'Una referencia no existe: revise las llaves de DETALLE_FACTURA.');
    WHEN e_check THEN
      RAISE_APPLICATION_ERROR(-20006, 'Un valor no cumple las reglas de validacion de DETALLE_FACTURA.');
    WHEN e_nulo THEN
      RAISE_APPLICATION_ERROR(-20007, 'Falta un dato obligatorio en DETALLE_FACTURA.');
  END sp_eliminar;

  PROCEDURE sp_obtener(
      p_id_factura IN detalle_factura.id_factura%TYPE,
      p_id_producto IN detalle_factura.id_producto%TYPE,
      p_cursor OUT SYS_REFCURSOR) IS
  BEGIN
    OPEN p_cursor FOR
      SELECT id_factura, id_producto, cantidad, precio_unitario
        FROM detalle_factura
       WHERE id_factura = p_id_factura AND id_producto = p_id_producto;
  END sp_obtener;

  PROCEDURE sp_listar(
      p_cursor OUT SYS_REFCURSOR) IS
  BEGIN
    OPEN p_cursor FOR
      SELECT id_factura, id_producto, cantidad, precio_unitario
        FROM detalle_factura
       ORDER BY id_factura, id_producto;
  END sp_listar;
END pkg_detalle_factura;
/

CREATE OR REPLACE PACKAGE pkg_nota_credito AS
  PROCEDURE sp_insertar(
      p_id_factura IN nota_credito.id_factura%TYPE,
      p_fecha_nota IN nota_credito.fecha_nota%TYPE,
      p_monto IN nota_credito.monto%TYPE,
      p_motivo IN nota_credito.motivo%TYPE,
      p_id_nota OUT nota_credito.id_nota%TYPE);
  PROCEDURE sp_actualizar(
      p_id_nota IN nota_credito.id_nota%TYPE,
      p_monto IN nota_credito.monto%TYPE,
      p_motivo IN nota_credito.motivo%TYPE);
  PROCEDURE sp_eliminar(
      p_id_nota IN nota_credito.id_nota%TYPE);
  PROCEDURE sp_obtener(
      p_id_nota IN nota_credito.id_nota%TYPE,
      p_cursor OUT SYS_REFCURSOR);
  PROCEDURE sp_listar(
      p_cursor OUT SYS_REFCURSOR);
END pkg_nota_credito;
/

CREATE OR REPLACE PACKAGE BODY pkg_nota_credito AS
  e_hijos EXCEPTION;
  PRAGMA EXCEPTION_INIT(e_hijos, -2292);
  e_padre EXCEPTION;
  PRAGMA EXCEPTION_INIT(e_padre, -2291);
  e_check EXCEPTION;
  PRAGMA EXCEPTION_INIT(e_check, -2290);
  e_nulo EXCEPTION;
  PRAGMA EXCEPTION_INIT(e_nulo, -1400);

  PROCEDURE sp_insertar(
      p_id_factura IN nota_credito.id_factura%TYPE,
      p_fecha_nota IN nota_credito.fecha_nota%TYPE,
      p_monto IN nota_credito.monto%TYPE,
      p_motivo IN nota_credito.motivo%TYPE,
      p_id_nota OUT nota_credito.id_nota%TYPE) IS
  BEGIN
    IF NVL(fn_estado_factura(p_id_factura), 'X') = 'ANULADA' THEN
      RAISE_APPLICATION_ERROR(-20060, 'No se puede crear una nota para una factura anulada.');
    END IF;
    IF p_monto > fn_saldo_factura(p_id_factura) THEN
      RAISE_APPLICATION_ERROR(-20061, 'La nota de credito supera el saldo pendiente de la factura.');
    END IF;
    INSERT INTO nota_credito (id_nota, id_factura, fecha_nota, monto, motivo)
    VALUES (seq_nota_credito.NEXTVAL, p_id_factura, NVL(p_fecha_nota, SYSDATE), p_monto, p_motivo)
    RETURNING id_nota INTO p_id_nota;
    sp_recalcular_factura(p_id_factura);
  EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
      RAISE_APPLICATION_ERROR(-20001, 'Ya existe un registro con ese valor unico en NOTA_CREDITO.');
    WHEN NO_DATA_FOUND THEN
      RAISE_APPLICATION_ERROR(-20002, 'No existe el registro buscado en NOTA_CREDITO.');
    WHEN e_hijos THEN
      RAISE_APPLICATION_ERROR(-20003, 'No se puede borrar: NOTA_CREDITO tiene registros relacionados.');
    WHEN e_padre THEN
      RAISE_APPLICATION_ERROR(-20005, 'Una referencia no existe: revise las llaves de NOTA_CREDITO.');
    WHEN e_check THEN
      RAISE_APPLICATION_ERROR(-20006, 'Un valor no cumple las reglas de validacion de NOTA_CREDITO.');
    WHEN e_nulo THEN
      RAISE_APPLICATION_ERROR(-20007, 'Falta un dato obligatorio en NOTA_CREDITO.');
  END sp_insertar;

  PROCEDURE sp_actualizar(
      p_id_nota IN nota_credito.id_nota%TYPE,
      p_monto IN nota_credito.monto%TYPE,
      p_motivo IN nota_credito.motivo%TYPE) IS
    v_id_factura nota_credito.id_factura%TYPE;
    v_monto_actual nota_credito.monto%TYPE;
  BEGIN
    SELECT id_factura, monto INTO v_id_factura, v_monto_actual
      FROM nota_credito WHERE id_nota = p_id_nota;
    IF p_monto - v_monto_actual > fn_saldo_factura(v_id_factura) THEN
      RAISE_APPLICATION_ERROR(-20061, 'La nota de credito supera el saldo pendiente de la factura.');
    END IF;
    UPDATE nota_credito
       SET monto = p_monto,
           motivo = p_motivo
     WHERE id_nota = p_id_nota;
    IF SQL%ROWCOUNT = 0 THEN
      RAISE_APPLICATION_ERROR(-20002, 'No existe el registro buscado en NOTA_CREDITO.');
    END IF;
    sp_recalcular_factura(v_id_factura);
  EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
      RAISE_APPLICATION_ERROR(-20001, 'Ya existe un registro con ese valor unico en NOTA_CREDITO.');
    WHEN NO_DATA_FOUND THEN
      RAISE_APPLICATION_ERROR(-20002, 'No existe el registro buscado en NOTA_CREDITO.');
    WHEN e_hijos THEN
      RAISE_APPLICATION_ERROR(-20003, 'No se puede borrar: NOTA_CREDITO tiene registros relacionados.');
    WHEN e_padre THEN
      RAISE_APPLICATION_ERROR(-20005, 'Una referencia no existe: revise las llaves de NOTA_CREDITO.');
    WHEN e_check THEN
      RAISE_APPLICATION_ERROR(-20006, 'Un valor no cumple las reglas de validacion de NOTA_CREDITO.');
    WHEN e_nulo THEN
      RAISE_APPLICATION_ERROR(-20007, 'Falta un dato obligatorio en NOTA_CREDITO.');
  END sp_actualizar;

  PROCEDURE sp_eliminar(
      p_id_nota IN nota_credito.id_nota%TYPE) IS
    v_id_factura nota_credito.id_factura%TYPE;
  BEGIN
    SELECT id_factura INTO v_id_factura FROM nota_credito WHERE id_nota = p_id_nota;
    DELETE FROM nota_credito WHERE id_nota = p_id_nota;
    IF SQL%ROWCOUNT = 0 THEN
      RAISE_APPLICATION_ERROR(-20002, 'No existe el registro buscado en NOTA_CREDITO.');
    END IF;
    sp_recalcular_factura(v_id_factura);
  EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
      RAISE_APPLICATION_ERROR(-20001, 'Ya existe un registro con ese valor unico en NOTA_CREDITO.');
    WHEN NO_DATA_FOUND THEN
      RAISE_APPLICATION_ERROR(-20002, 'No existe el registro buscado en NOTA_CREDITO.');
    WHEN e_hijos THEN
      RAISE_APPLICATION_ERROR(-20003, 'No se puede borrar: NOTA_CREDITO tiene registros relacionados.');
    WHEN e_padre THEN
      RAISE_APPLICATION_ERROR(-20005, 'Una referencia no existe: revise las llaves de NOTA_CREDITO.');
    WHEN e_check THEN
      RAISE_APPLICATION_ERROR(-20006, 'Un valor no cumple las reglas de validacion de NOTA_CREDITO.');
    WHEN e_nulo THEN
      RAISE_APPLICATION_ERROR(-20007, 'Falta un dato obligatorio en NOTA_CREDITO.');
  END sp_eliminar;

  PROCEDURE sp_obtener(
      p_id_nota IN nota_credito.id_nota%TYPE,
      p_cursor OUT SYS_REFCURSOR) IS
  BEGIN
    OPEN p_cursor FOR
      SELECT id_nota, id_factura, fecha_nota, monto, motivo
        FROM nota_credito
       WHERE id_nota = p_id_nota;
  END sp_obtener;

  PROCEDURE sp_listar(
      p_cursor OUT SYS_REFCURSOR) IS
  BEGIN
    OPEN p_cursor FOR
      SELECT id_nota, id_factura, fecha_nota, monto, motivo
        FROM nota_credito
       ORDER BY id_nota;
  END sp_listar;
END pkg_nota_credito;
/

CREATE OR REPLACE PACKAGE pkg_pago AS
  PROCEDURE sp_insertar(
      p_id_cliente IN pago.id_cliente%TYPE,
      p_id_metodo_pago IN pago.id_metodo_pago%TYPE,
      p_fecha_pago IN pago.fecha_pago%TYPE,
      p_monto IN pago.monto%TYPE,
      p_referencia IN pago.referencia%TYPE,
      p_id_pago OUT pago.id_pago%TYPE);
  PROCEDURE sp_actualizar(
      p_id_pago IN pago.id_pago%TYPE,
      p_id_metodo_pago IN pago.id_metodo_pago%TYPE,
      p_fecha_pago IN pago.fecha_pago%TYPE,
      p_monto IN pago.monto%TYPE,
      p_referencia IN pago.referencia%TYPE);
  PROCEDURE sp_eliminar(
      p_id_pago IN pago.id_pago%TYPE);
  PROCEDURE sp_obtener(
      p_id_pago IN pago.id_pago%TYPE,
      p_cursor OUT SYS_REFCURSOR);
  PROCEDURE sp_listar(
      p_cursor OUT SYS_REFCURSOR);
END pkg_pago;
/

CREATE OR REPLACE PACKAGE BODY pkg_pago AS
  e_hijos EXCEPTION;
  PRAGMA EXCEPTION_INIT(e_hijos, -2292);
  e_padre EXCEPTION;
  PRAGMA EXCEPTION_INIT(e_padre, -2291);
  e_check EXCEPTION;
  PRAGMA EXCEPTION_INIT(e_check, -2290);
  e_nulo EXCEPTION;
  PRAGMA EXCEPTION_INIT(e_nulo, -1400);

  PROCEDURE sp_insertar(
      p_id_cliente IN pago.id_cliente%TYPE,
      p_id_metodo_pago IN pago.id_metodo_pago%TYPE,
      p_fecha_pago IN pago.fecha_pago%TYPE,
      p_monto IN pago.monto%TYPE,
      p_referencia IN pago.referencia%TYPE,
      p_id_pago OUT pago.id_pago%TYPE) IS
  BEGIN
    INSERT INTO pago (id_pago, id_cliente, id_metodo_pago, fecha_pago, monto, referencia, monto_sin_aplicar)
    VALUES (seq_pago.NEXTVAL, p_id_cliente, p_id_metodo_pago, NVL(p_fecha_pago, SYSDATE), p_monto, p_referencia, p_monto)
    RETURNING id_pago INTO p_id_pago;
  EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
      RAISE_APPLICATION_ERROR(-20001, 'Ya existe un registro con ese valor unico en PAGO.');
    WHEN NO_DATA_FOUND THEN
      RAISE_APPLICATION_ERROR(-20002, 'No existe el registro buscado en PAGO.');
    WHEN e_hijos THEN
      RAISE_APPLICATION_ERROR(-20003, 'No se puede borrar: PAGO tiene registros relacionados.');
    WHEN e_padre THEN
      RAISE_APPLICATION_ERROR(-20005, 'Una referencia no existe: revise las llaves de PAGO.');
    WHEN e_check THEN
      RAISE_APPLICATION_ERROR(-20006, 'Un valor no cumple las reglas de validacion de PAGO.');
    WHEN e_nulo THEN
      RAISE_APPLICATION_ERROR(-20007, 'Falta un dato obligatorio en PAGO.');
  END sp_insertar;

  PROCEDURE sp_actualizar(
      p_id_pago IN pago.id_pago%TYPE,
      p_id_metodo_pago IN pago.id_metodo_pago%TYPE,
      p_fecha_pago IN pago.fecha_pago%TYPE,
      p_monto IN pago.monto%TYPE,
      p_referencia IN pago.referencia%TYPE) IS
    v_aplicado pago.monto%TYPE;
  BEGIN
    v_aplicado := fn_monto_aplicado_pago(p_id_pago);
    IF p_monto < v_aplicado THEN
      RAISE_APPLICATION_ERROR(-20080, 'El monto no puede ser menor a lo que ya se aplico a facturas.');
    END IF;
    UPDATE pago
       SET id_metodo_pago = p_id_metodo_pago,
           fecha_pago = p_fecha_pago,
           monto = p_monto,
           referencia = p_referencia,
           monto_sin_aplicar = p_monto - v_aplicado
     WHERE id_pago = p_id_pago;
    IF SQL%ROWCOUNT = 0 THEN
      RAISE_APPLICATION_ERROR(-20002, 'No existe el registro buscado en PAGO.');
    END IF;
  EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
      RAISE_APPLICATION_ERROR(-20001, 'Ya existe un registro con ese valor unico en PAGO.');
    WHEN NO_DATA_FOUND THEN
      RAISE_APPLICATION_ERROR(-20002, 'No existe el registro buscado en PAGO.');
    WHEN e_hijos THEN
      RAISE_APPLICATION_ERROR(-20003, 'No se puede borrar: PAGO tiene registros relacionados.');
    WHEN e_padre THEN
      RAISE_APPLICATION_ERROR(-20005, 'Una referencia no existe: revise las llaves de PAGO.');
    WHEN e_check THEN
      RAISE_APPLICATION_ERROR(-20006, 'Un valor no cumple las reglas de validacion de PAGO.');
    WHEN e_nulo THEN
      RAISE_APPLICATION_ERROR(-20007, 'Falta un dato obligatorio en PAGO.');
  END sp_actualizar;

  PROCEDURE sp_eliminar(
      p_id_pago IN pago.id_pago%TYPE) IS
  BEGIN
    DELETE FROM pago WHERE id_pago = p_id_pago;
    IF SQL%ROWCOUNT = 0 THEN
      RAISE_APPLICATION_ERROR(-20002, 'No existe el registro buscado en PAGO.');
    END IF;
  EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
      RAISE_APPLICATION_ERROR(-20001, 'Ya existe un registro con ese valor unico en PAGO.');
    WHEN NO_DATA_FOUND THEN
      RAISE_APPLICATION_ERROR(-20002, 'No existe el registro buscado en PAGO.');
    WHEN e_hijos THEN
      RAISE_APPLICATION_ERROR(-20003, 'No se puede borrar: PAGO tiene registros relacionados.');
    WHEN e_padre THEN
      RAISE_APPLICATION_ERROR(-20005, 'Una referencia no existe: revise las llaves de PAGO.');
    WHEN e_check THEN
      RAISE_APPLICATION_ERROR(-20006, 'Un valor no cumple las reglas de validacion de PAGO.');
    WHEN e_nulo THEN
      RAISE_APPLICATION_ERROR(-20007, 'Falta un dato obligatorio en PAGO.');
  END sp_eliminar;

  PROCEDURE sp_obtener(
      p_id_pago IN pago.id_pago%TYPE,
      p_cursor OUT SYS_REFCURSOR) IS
  BEGIN
    OPEN p_cursor FOR
      SELECT id_pago, id_cliente, id_metodo_pago, fecha_pago, monto, referencia, monto_sin_aplicar
        FROM pago
       WHERE id_pago = p_id_pago;
  END sp_obtener;

  PROCEDURE sp_listar(
      p_cursor OUT SYS_REFCURSOR) IS
  BEGIN
    OPEN p_cursor FOR
      SELECT id_pago, id_cliente, id_metodo_pago, fecha_pago, monto, referencia, monto_sin_aplicar
        FROM pago
       ORDER BY id_pago;
  END sp_listar;
END pkg_pago;
/

CREATE OR REPLACE PACKAGE pkg_aplicacion_pago AS
  PROCEDURE sp_insertar(
      p_id_pago IN aplicacion_pago.id_pago%TYPE,
      p_id_factura IN aplicacion_pago.id_factura%TYPE,
      p_monto_aplicado IN aplicacion_pago.monto_aplicado%TYPE,
      p_fecha_aplicacion IN aplicacion_pago.fecha_aplicacion%TYPE,
      p_id_aplicacion OUT aplicacion_pago.id_aplicacion%TYPE);
  PROCEDURE sp_actualizar(
      p_id_aplicacion IN aplicacion_pago.id_aplicacion%TYPE,
      p_monto_aplicado IN aplicacion_pago.monto_aplicado%TYPE);
  PROCEDURE sp_eliminar(
      p_id_aplicacion IN aplicacion_pago.id_aplicacion%TYPE);
  PROCEDURE sp_obtener(
      p_id_aplicacion IN aplicacion_pago.id_aplicacion%TYPE,
      p_cursor OUT SYS_REFCURSOR);
  PROCEDURE sp_listar(
      p_cursor OUT SYS_REFCURSOR);
END pkg_aplicacion_pago;
/

CREATE OR REPLACE PACKAGE BODY pkg_aplicacion_pago AS
  e_hijos EXCEPTION;
  PRAGMA EXCEPTION_INIT(e_hijos, -2292);
  e_padre EXCEPTION;
  PRAGMA EXCEPTION_INIT(e_padre, -2291);
  e_check EXCEPTION;
  PRAGMA EXCEPTION_INIT(e_check, -2290);
  e_nulo EXCEPTION;
  PRAGMA EXCEPTION_INIT(e_nulo, -1400);

  PROCEDURE sp_insertar(
      p_id_pago IN aplicacion_pago.id_pago%TYPE,
      p_id_factura IN aplicacion_pago.id_factura%TYPE,
      p_monto_aplicado IN aplicacion_pago.monto_aplicado%TYPE,
      p_fecha_aplicacion IN aplicacion_pago.fecha_aplicacion%TYPE,
      p_id_aplicacion OUT aplicacion_pago.id_aplicacion%TYPE) IS
    v_cliente_pago pago.id_cliente%TYPE;
    v_cliente_factura factura.id_cliente%TYPE;
    v_sin_aplicar pago.monto_sin_aplicar%TYPE;
    v_saldo factura.saldo_pendiente%TYPE;
    v_estado factura.estado%TYPE;
  BEGIN
    SELECT id_cliente, monto_sin_aplicar INTO v_cliente_pago, v_sin_aplicar
      FROM pago WHERE id_pago = p_id_pago FOR UPDATE;
    SELECT id_cliente, saldo_pendiente, estado INTO v_cliente_factura, v_saldo, v_estado
      FROM factura WHERE id_factura = p_id_factura FOR UPDATE;
    IF v_cliente_pago <> v_cliente_factura THEN
      RAISE_APPLICATION_ERROR(-20090, 'El pago y la factura son de clientes distintos.');
    END IF;
    IF v_estado = 'ANULADA' THEN
      RAISE_APPLICATION_ERROR(-20091, 'No se puede aplicar un pago a una factura anulada.');
    END IF;
    IF p_monto_aplicado > v_sin_aplicar THEN
      RAISE_APPLICATION_ERROR(-20092, 'El monto supera lo que queda sin aplicar del pago.');
    END IF;
    IF p_monto_aplicado > v_saldo THEN
      RAISE_APPLICATION_ERROR(-20093, 'El monto supera el saldo pendiente de la factura.');
    END IF;
    INSERT INTO aplicacion_pago (id_aplicacion, id_pago, id_factura, monto_aplicado, fecha_aplicacion)
    VALUES (seq_aplicacion_pago.NEXTVAL, p_id_pago, p_id_factura, p_monto_aplicado, NVL(p_fecha_aplicacion, SYSDATE))
    RETURNING id_aplicacion INTO p_id_aplicacion;
    UPDATE pago SET monto_sin_aplicar = monto_sin_aplicar - p_monto_aplicado
     WHERE id_pago = p_id_pago;
    sp_recalcular_factura(p_id_factura);
  EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
      RAISE_APPLICATION_ERROR(-20001, 'Ya existe un registro con ese valor unico en APLICACION_PAGO.');
    WHEN NO_DATA_FOUND THEN
      RAISE_APPLICATION_ERROR(-20002, 'No existe el registro buscado en APLICACION_PAGO.');
    WHEN e_hijos THEN
      RAISE_APPLICATION_ERROR(-20003, 'No se puede borrar: APLICACION_PAGO tiene registros relacionados.');
    WHEN e_padre THEN
      RAISE_APPLICATION_ERROR(-20005, 'Una referencia no existe: revise las llaves de APLICACION_PAGO.');
    WHEN e_check THEN
      RAISE_APPLICATION_ERROR(-20006, 'Un valor no cumple las reglas de validacion de APLICACION_PAGO.');
    WHEN e_nulo THEN
      RAISE_APPLICATION_ERROR(-20007, 'Falta un dato obligatorio en APLICACION_PAGO.');
  END sp_insertar;

  PROCEDURE sp_actualizar(
      p_id_aplicacion IN aplicacion_pago.id_aplicacion%TYPE,
      p_monto_aplicado IN aplicacion_pago.monto_aplicado%TYPE) IS
    v_id_pago aplicacion_pago.id_pago%TYPE;
    v_id_factura aplicacion_pago.id_factura%TYPE;
    v_actual aplicacion_pago.monto_aplicado%TYPE;
    v_sin_aplicar pago.monto_sin_aplicar%TYPE;
    v_saldo factura.saldo_pendiente%TYPE;
  BEGIN
    SELECT id_pago, id_factura, monto_aplicado INTO v_id_pago, v_id_factura, v_actual
      FROM aplicacion_pago WHERE id_aplicacion = p_id_aplicacion FOR UPDATE;
    SELECT monto_sin_aplicar INTO v_sin_aplicar FROM pago WHERE id_pago = v_id_pago FOR UPDATE;
    SELECT saldo_pendiente INTO v_saldo FROM factura WHERE id_factura = v_id_factura FOR UPDATE;
    IF p_monto_aplicado - v_actual > v_sin_aplicar THEN
      RAISE_APPLICATION_ERROR(-20092, 'El monto supera lo que queda sin aplicar del pago.');
    END IF;
    IF p_monto_aplicado - v_actual > v_saldo THEN
      RAISE_APPLICATION_ERROR(-20093, 'El monto supera el saldo pendiente de la factura.');
    END IF;
    UPDATE aplicacion_pago
       SET monto_aplicado = p_monto_aplicado
     WHERE id_aplicacion = p_id_aplicacion;
    IF SQL%ROWCOUNT = 0 THEN
      RAISE_APPLICATION_ERROR(-20002, 'No existe el registro buscado en APLICACION_PAGO.');
    END IF;
    UPDATE pago SET monto_sin_aplicar = monto_sin_aplicar - (p_monto_aplicado - v_actual)
     WHERE id_pago = v_id_pago;
    sp_recalcular_factura(v_id_factura);
  EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
      RAISE_APPLICATION_ERROR(-20001, 'Ya existe un registro con ese valor unico en APLICACION_PAGO.');
    WHEN NO_DATA_FOUND THEN
      RAISE_APPLICATION_ERROR(-20002, 'No existe el registro buscado en APLICACION_PAGO.');
    WHEN e_hijos THEN
      RAISE_APPLICATION_ERROR(-20003, 'No se puede borrar: APLICACION_PAGO tiene registros relacionados.');
    WHEN e_padre THEN
      RAISE_APPLICATION_ERROR(-20005, 'Una referencia no existe: revise las llaves de APLICACION_PAGO.');
    WHEN e_check THEN
      RAISE_APPLICATION_ERROR(-20006, 'Un valor no cumple las reglas de validacion de APLICACION_PAGO.');
    WHEN e_nulo THEN
      RAISE_APPLICATION_ERROR(-20007, 'Falta un dato obligatorio en APLICACION_PAGO.');
  END sp_actualizar;

  PROCEDURE sp_eliminar(
      p_id_aplicacion IN aplicacion_pago.id_aplicacion%TYPE) IS
    v_id_pago aplicacion_pago.id_pago%TYPE;
    v_id_factura aplicacion_pago.id_factura%TYPE;
    v_actual aplicacion_pago.monto_aplicado%TYPE;
  BEGIN
    SELECT id_pago, id_factura, monto_aplicado INTO v_id_pago, v_id_factura, v_actual
      FROM aplicacion_pago WHERE id_aplicacion = p_id_aplicacion FOR UPDATE;
    DELETE FROM aplicacion_pago WHERE id_aplicacion = p_id_aplicacion;
    IF SQL%ROWCOUNT = 0 THEN
      RAISE_APPLICATION_ERROR(-20002, 'No existe el registro buscado en APLICACION_PAGO.');
    END IF;
    UPDATE pago SET monto_sin_aplicar = monto_sin_aplicar + v_actual
     WHERE id_pago = v_id_pago;
    sp_recalcular_factura(v_id_factura);
  EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
      RAISE_APPLICATION_ERROR(-20001, 'Ya existe un registro con ese valor unico en APLICACION_PAGO.');
    WHEN NO_DATA_FOUND THEN
      RAISE_APPLICATION_ERROR(-20002, 'No existe el registro buscado en APLICACION_PAGO.');
    WHEN e_hijos THEN
      RAISE_APPLICATION_ERROR(-20003, 'No se puede borrar: APLICACION_PAGO tiene registros relacionados.');
    WHEN e_padre THEN
      RAISE_APPLICATION_ERROR(-20005, 'Una referencia no existe: revise las llaves de APLICACION_PAGO.');
    WHEN e_check THEN
      RAISE_APPLICATION_ERROR(-20006, 'Un valor no cumple las reglas de validacion de APLICACION_PAGO.');
    WHEN e_nulo THEN
      RAISE_APPLICATION_ERROR(-20007, 'Falta un dato obligatorio en APLICACION_PAGO.');
  END sp_eliminar;

  PROCEDURE sp_obtener(
      p_id_aplicacion IN aplicacion_pago.id_aplicacion%TYPE,
      p_cursor OUT SYS_REFCURSOR) IS
  BEGIN
    OPEN p_cursor FOR
      SELECT id_aplicacion, id_pago, id_factura, monto_aplicado, fecha_aplicacion
        FROM aplicacion_pago
       WHERE id_aplicacion = p_id_aplicacion;
  END sp_obtener;

  PROCEDURE sp_listar(
      p_cursor OUT SYS_REFCURSOR) IS
  BEGIN
    OPEN p_cursor FOR
      SELECT id_aplicacion, id_pago, id_factura, monto_aplicado, fecha_aplicacion
        FROM aplicacion_pago
       ORDER BY id_aplicacion;
  END sp_listar;
END pkg_aplicacion_pago;
/

CREATE OR REPLACE PACKAGE pkg_gestion_cobro AS
  PROCEDURE sp_insertar(
      p_id_cliente IN gestion_cobro.id_cliente%TYPE,
      p_id_factura IN gestion_cobro.id_factura%TYPE,
      p_id_empleado IN gestion_cobro.id_empleado%TYPE,
      p_fecha_hora IN gestion_cobro.fecha_hora%TYPE,
      p_tipo_gestion IN gestion_cobro.tipo_gestion%TYPE,
      p_resultado IN gestion_cobro.resultado%TYPE,
      p_fecha_promesa IN gestion_cobro.fecha_promesa%TYPE,
      p_observacion IN gestion_cobro.observacion%TYPE,
      p_id_gestion OUT gestion_cobro.id_gestion%TYPE);
  PROCEDURE sp_actualizar(
      p_id_gestion IN gestion_cobro.id_gestion%TYPE,
      p_tipo_gestion IN gestion_cobro.tipo_gestion%TYPE,
      p_resultado IN gestion_cobro.resultado%TYPE,
      p_fecha_promesa IN gestion_cobro.fecha_promesa%TYPE,
      p_observacion IN gestion_cobro.observacion%TYPE);
  PROCEDURE sp_eliminar(
      p_id_gestion IN gestion_cobro.id_gestion%TYPE);
  PROCEDURE sp_obtener(
      p_id_gestion IN gestion_cobro.id_gestion%TYPE,
      p_cursor OUT SYS_REFCURSOR);
  PROCEDURE sp_listar(
      p_cursor OUT SYS_REFCURSOR);
END pkg_gestion_cobro;
/

CREATE OR REPLACE PACKAGE BODY pkg_gestion_cobro AS
  e_hijos EXCEPTION;
  PRAGMA EXCEPTION_INIT(e_hijos, -2292);
  e_padre EXCEPTION;
  PRAGMA EXCEPTION_INIT(e_padre, -2291);
  e_check EXCEPTION;
  PRAGMA EXCEPTION_INIT(e_check, -2290);
  e_nulo EXCEPTION;
  PRAGMA EXCEPTION_INIT(e_nulo, -1400);

  PROCEDURE sp_insertar(
      p_id_cliente IN gestion_cobro.id_cliente%TYPE,
      p_id_factura IN gestion_cobro.id_factura%TYPE,
      p_id_empleado IN gestion_cobro.id_empleado%TYPE,
      p_fecha_hora IN gestion_cobro.fecha_hora%TYPE,
      p_tipo_gestion IN gestion_cobro.tipo_gestion%TYPE,
      p_resultado IN gestion_cobro.resultado%TYPE,
      p_fecha_promesa IN gestion_cobro.fecha_promesa%TYPE,
      p_observacion IN gestion_cobro.observacion%TYPE,
      p_id_gestion OUT gestion_cobro.id_gestion%TYPE) IS
  BEGIN
    IF p_resultado = 'PROMESA_PAGO' AND p_fecha_promesa IS NULL THEN
      RAISE_APPLICATION_ERROR(-20100, 'Una promesa de pago necesita la fecha prometida.');
    END IF;
    INSERT INTO gestion_cobro (id_gestion, id_cliente, id_factura, id_empleado, fecha_hora, tipo_gestion, resultado, fecha_promesa, observacion)
    VALUES (seq_gestion_cobro.NEXTVAL, p_id_cliente, p_id_factura, p_id_empleado, NVL(p_fecha_hora, SYSDATE), p_tipo_gestion, p_resultado, p_fecha_promesa, p_observacion)
    RETURNING id_gestion INTO p_id_gestion;
  EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
      RAISE_APPLICATION_ERROR(-20001, 'Ya existe un registro con ese valor unico en GESTION_COBRO.');
    WHEN NO_DATA_FOUND THEN
      RAISE_APPLICATION_ERROR(-20002, 'No existe el registro buscado en GESTION_COBRO.');
    WHEN e_hijos THEN
      RAISE_APPLICATION_ERROR(-20003, 'No se puede borrar: GESTION_COBRO tiene registros relacionados.');
    WHEN e_padre THEN
      RAISE_APPLICATION_ERROR(-20005, 'Una referencia no existe: revise las llaves de GESTION_COBRO.');
    WHEN e_check THEN
      RAISE_APPLICATION_ERROR(-20006, 'Un valor no cumple las reglas de validacion de GESTION_COBRO.');
    WHEN e_nulo THEN
      RAISE_APPLICATION_ERROR(-20007, 'Falta un dato obligatorio en GESTION_COBRO.');
  END sp_insertar;

  PROCEDURE sp_actualizar(
      p_id_gestion IN gestion_cobro.id_gestion%TYPE,
      p_tipo_gestion IN gestion_cobro.tipo_gestion%TYPE,
      p_resultado IN gestion_cobro.resultado%TYPE,
      p_fecha_promesa IN gestion_cobro.fecha_promesa%TYPE,
      p_observacion IN gestion_cobro.observacion%TYPE) IS
  BEGIN
    IF p_resultado = 'PROMESA_PAGO' AND p_fecha_promesa IS NULL THEN
      RAISE_APPLICATION_ERROR(-20100, 'Una promesa de pago necesita la fecha prometida.');
    END IF;
    UPDATE gestion_cobro
       SET tipo_gestion = p_tipo_gestion,
           resultado = p_resultado,
           fecha_promesa = p_fecha_promesa,
           observacion = p_observacion
     WHERE id_gestion = p_id_gestion;
    IF SQL%ROWCOUNT = 0 THEN
      RAISE_APPLICATION_ERROR(-20002, 'No existe el registro buscado en GESTION_COBRO.');
    END IF;
  EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
      RAISE_APPLICATION_ERROR(-20001, 'Ya existe un registro con ese valor unico en GESTION_COBRO.');
    WHEN NO_DATA_FOUND THEN
      RAISE_APPLICATION_ERROR(-20002, 'No existe el registro buscado en GESTION_COBRO.');
    WHEN e_hijos THEN
      RAISE_APPLICATION_ERROR(-20003, 'No se puede borrar: GESTION_COBRO tiene registros relacionados.');
    WHEN e_padre THEN
      RAISE_APPLICATION_ERROR(-20005, 'Una referencia no existe: revise las llaves de GESTION_COBRO.');
    WHEN e_check THEN
      RAISE_APPLICATION_ERROR(-20006, 'Un valor no cumple las reglas de validacion de GESTION_COBRO.');
    WHEN e_nulo THEN
      RAISE_APPLICATION_ERROR(-20007, 'Falta un dato obligatorio en GESTION_COBRO.');
  END sp_actualizar;

  PROCEDURE sp_eliminar(
      p_id_gestion IN gestion_cobro.id_gestion%TYPE) IS
  BEGIN
    DELETE FROM gestion_cobro WHERE id_gestion = p_id_gestion;
    IF SQL%ROWCOUNT = 0 THEN
      RAISE_APPLICATION_ERROR(-20002, 'No existe el registro buscado en GESTION_COBRO.');
    END IF;
  EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
      RAISE_APPLICATION_ERROR(-20001, 'Ya existe un registro con ese valor unico en GESTION_COBRO.');
    WHEN NO_DATA_FOUND THEN
      RAISE_APPLICATION_ERROR(-20002, 'No existe el registro buscado en GESTION_COBRO.');
    WHEN e_hijos THEN
      RAISE_APPLICATION_ERROR(-20003, 'No se puede borrar: GESTION_COBRO tiene registros relacionados.');
    WHEN e_padre THEN
      RAISE_APPLICATION_ERROR(-20005, 'Una referencia no existe: revise las llaves de GESTION_COBRO.');
    WHEN e_check THEN
      RAISE_APPLICATION_ERROR(-20006, 'Un valor no cumple las reglas de validacion de GESTION_COBRO.');
    WHEN e_nulo THEN
      RAISE_APPLICATION_ERROR(-20007, 'Falta un dato obligatorio en GESTION_COBRO.');
  END sp_eliminar;

  PROCEDURE sp_obtener(
      p_id_gestion IN gestion_cobro.id_gestion%TYPE,
      p_cursor OUT SYS_REFCURSOR) IS
  BEGIN
    OPEN p_cursor FOR
      SELECT id_gestion, id_cliente, id_factura, id_empleado, fecha_hora, tipo_gestion, resultado, fecha_promesa, observacion
        FROM gestion_cobro
       WHERE id_gestion = p_id_gestion;
  END sp_obtener;

  PROCEDURE sp_listar(
      p_cursor OUT SYS_REFCURSOR) IS
  BEGIN
    OPEN p_cursor FOR
      SELECT id_gestion, id_cliente, id_factura, id_empleado, fecha_hora, tipo_gestion, resultado, fecha_promesa, observacion
        FROM gestion_cobro
       ORDER BY id_gestion;
  END sp_listar;
END pkg_gestion_cobro;
/

CREATE OR REPLACE PACKAGE pkg_bitacora AS
  PROCEDURE sp_insertar(
      p_tabla_afectada IN bitacora.tabla_afectada%TYPE,
      p_operacion IN bitacora.operacion%TYPE,
      p_detalle IN bitacora.detalle%TYPE,
      p_id_bitacora OUT bitacora.id_bitacora%TYPE);
  PROCEDURE sp_actualizar(
      p_id_bitacora IN bitacora.id_bitacora%TYPE,
      p_detalle IN bitacora.detalle%TYPE);
  PROCEDURE sp_eliminar(
      p_id_bitacora IN bitacora.id_bitacora%TYPE);
  PROCEDURE sp_obtener(
      p_id_bitacora IN bitacora.id_bitacora%TYPE,
      p_cursor OUT SYS_REFCURSOR);
  PROCEDURE sp_listar(
      p_cursor OUT SYS_REFCURSOR);
END pkg_bitacora;
/

CREATE OR REPLACE PACKAGE BODY pkg_bitacora AS
  e_hijos EXCEPTION;
  PRAGMA EXCEPTION_INIT(e_hijos, -2292);
  e_padre EXCEPTION;
  PRAGMA EXCEPTION_INIT(e_padre, -2291);
  e_check EXCEPTION;
  PRAGMA EXCEPTION_INIT(e_check, -2290);
  e_nulo EXCEPTION;
  PRAGMA EXCEPTION_INIT(e_nulo, -1400);

  PROCEDURE sp_insertar(
      p_tabla_afectada IN bitacora.tabla_afectada%TYPE,
      p_operacion IN bitacora.operacion%TYPE,
      p_detalle IN bitacora.detalle%TYPE,
      p_id_bitacora OUT bitacora.id_bitacora%TYPE) IS
  BEGIN
    INSERT INTO bitacora (id_bitacora, tabla_afectada, operacion, usuario_bd, fecha_hora, detalle)
    VALUES (seq_bitacora.NEXTVAL, p_tabla_afectada, p_operacion, SYS_CONTEXT('USERENV', 'SESSION_USER'), SYSDATE, p_detalle)
    RETURNING id_bitacora INTO p_id_bitacora;
  EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
      RAISE_APPLICATION_ERROR(-20001, 'Ya existe un registro con ese valor unico en BITACORA.');
    WHEN NO_DATA_FOUND THEN
      RAISE_APPLICATION_ERROR(-20002, 'No existe el registro buscado en BITACORA.');
    WHEN e_hijos THEN
      RAISE_APPLICATION_ERROR(-20003, 'No se puede borrar: BITACORA tiene registros relacionados.');
    WHEN e_padre THEN
      RAISE_APPLICATION_ERROR(-20005, 'Una referencia no existe: revise las llaves de BITACORA.');
    WHEN e_check THEN
      RAISE_APPLICATION_ERROR(-20006, 'Un valor no cumple las reglas de validacion de BITACORA.');
    WHEN e_nulo THEN
      RAISE_APPLICATION_ERROR(-20007, 'Falta un dato obligatorio en BITACORA.');
  END sp_insertar;

  PROCEDURE sp_actualizar(
      p_id_bitacora IN bitacora.id_bitacora%TYPE,
      p_detalle IN bitacora.detalle%TYPE) IS
  BEGIN
    UPDATE bitacora
       SET detalle = p_detalle
     WHERE id_bitacora = p_id_bitacora;
    IF SQL%ROWCOUNT = 0 THEN
      RAISE_APPLICATION_ERROR(-20002, 'No existe el registro buscado en BITACORA.');
    END IF;
  EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
      RAISE_APPLICATION_ERROR(-20001, 'Ya existe un registro con ese valor unico en BITACORA.');
    WHEN NO_DATA_FOUND THEN
      RAISE_APPLICATION_ERROR(-20002, 'No existe el registro buscado en BITACORA.');
    WHEN e_hijos THEN
      RAISE_APPLICATION_ERROR(-20003, 'No se puede borrar: BITACORA tiene registros relacionados.');
    WHEN e_padre THEN
      RAISE_APPLICATION_ERROR(-20005, 'Una referencia no existe: revise las llaves de BITACORA.');
    WHEN e_check THEN
      RAISE_APPLICATION_ERROR(-20006, 'Un valor no cumple las reglas de validacion de BITACORA.');
    WHEN e_nulo THEN
      RAISE_APPLICATION_ERROR(-20007, 'Falta un dato obligatorio en BITACORA.');
  END sp_actualizar;

  PROCEDURE sp_eliminar(
      p_id_bitacora IN bitacora.id_bitacora%TYPE) IS
    v_fecha bitacora.fecha_hora%TYPE;
  BEGIN
    SELECT fecha_hora INTO v_fecha FROM bitacora WHERE id_bitacora = p_id_bitacora;
    IF v_fecha > SYSDATE - 365 THEN
      RAISE_APPLICATION_ERROR(-20110, 'Solo se pueden borrar registros de bitacora con mas de 365 dias.');
    END IF;
    DELETE FROM bitacora WHERE id_bitacora = p_id_bitacora;
    IF SQL%ROWCOUNT = 0 THEN
      RAISE_APPLICATION_ERROR(-20002, 'No existe el registro buscado en BITACORA.');
    END IF;
  EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
      RAISE_APPLICATION_ERROR(-20001, 'Ya existe un registro con ese valor unico en BITACORA.');
    WHEN NO_DATA_FOUND THEN
      RAISE_APPLICATION_ERROR(-20002, 'No existe el registro buscado en BITACORA.');
    WHEN e_hijos THEN
      RAISE_APPLICATION_ERROR(-20003, 'No se puede borrar: BITACORA tiene registros relacionados.');
    WHEN e_padre THEN
      RAISE_APPLICATION_ERROR(-20005, 'Una referencia no existe: revise las llaves de BITACORA.');
    WHEN e_check THEN
      RAISE_APPLICATION_ERROR(-20006, 'Un valor no cumple las reglas de validacion de BITACORA.');
    WHEN e_nulo THEN
      RAISE_APPLICATION_ERROR(-20007, 'Falta un dato obligatorio en BITACORA.');
  END sp_eliminar;

  PROCEDURE sp_obtener(
      p_id_bitacora IN bitacora.id_bitacora%TYPE,
      p_cursor OUT SYS_REFCURSOR) IS
  BEGIN
    OPEN p_cursor FOR
      SELECT id_bitacora, tabla_afectada, operacion, usuario_bd, fecha_hora, detalle
        FROM bitacora
       WHERE id_bitacora = p_id_bitacora;
  END sp_obtener;

  PROCEDURE sp_listar(
      p_cursor OUT SYS_REFCURSOR) IS
  BEGIN
    OPEN p_cursor FOR
      SELECT id_bitacora, tabla_afectada, operacion, usuario_bd, fecha_hora, detalle
        FROM bitacora
       ORDER BY id_bitacora;
  END sp_listar;
END pkg_bitacora;
/
