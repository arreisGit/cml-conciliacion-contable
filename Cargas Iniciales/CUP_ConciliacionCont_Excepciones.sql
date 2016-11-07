INSERT INTO
  CUP_ConciliacionCont_Excepciones
(
  TipoConciliacion,
  TipoExcepcion,
  Valor,
  Empleado
)
VALUES
  ( 1, 1, 'SHCP',63527)
 ,( 2, 1, 'SHCP',63527)

SELECT 
  ID,
  TipoConciliacion,
  TipoExcepcion,
  Valor,
  Empleado,
  FechaAlta
FROM
  CUP_ConciliacionCont_Excepciones