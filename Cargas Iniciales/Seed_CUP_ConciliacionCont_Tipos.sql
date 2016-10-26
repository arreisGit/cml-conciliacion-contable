--TRUNCATE TABLE CUP_ConciliacionCont_Tipos

INSERT INTO 
  CUP_ConciliacionCont_Tipos 
( 
  Descripcion,
  Empleado 
)
VALUES
  ('Saldo Proveedores', 63527)

SELECT
  ID,
  Descripcion,
  Empleado,
  FechaAlta
FROM
  CUP_ConciliacionCont_Tipos
ORDER BY
  ID