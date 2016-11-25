TRUNCATE TABLE CUP_ConciliacionCont_Excepciones

INSERT INTO
  CUP_ConciliacionCont_Excepciones
(
  TipoConciliacion,
  TipoExcepcion,
  Valor,
  Empleado
)
VALUES
/* Conicliacion Saldo Proveedores*/
  ( 1, 1, 'SHCP',63527)
/* Conciliacion IVA Por Acreditar */
 ,( 2, 1, 'SHCP',63527)
 /* Conciliacion Saldos Cxc */
 ,( 3, 1, 'DD011',63527)
 ,( 3, 1, 'DD006',63527)
 ,( 3, 1, 'DD007',63527)
 ,( 3, 1, 'DD23',63527)
 ,( 3, 1, '2016',63527)
 /* Conciliacion IVA trasladado */
 ,( 4, 1, 'DD011',63527)
 ,( 4, 1, 'DD006',63527)
 ,( 4, 1, 'DD007',63527)
 ,( 4, 1, 'DD23',63527)
 ,( 4, 1, '2016',63527)

SELECT 
  ID,
  TipoConciliacion,
  TipoExcepcion,
  Valor,
  Empleado,
  FechaAlta
FROM
  CUP_ConciliacionCont_Excepciones