SET ANSI_NULLS, ANSI_WARNINGS ON;

GO

IF EXISTS (SELECT * 
		   FROM SYSOBJECTS 
		   WHERE ID = OBJECT_ID('dbo.CUP_SPP_ConciliacionCont') AND 
				 TYPE = 'P')
BEGIN
  DROP PROCEDURE dbo.CUP_SPP_ConciliacionCont 
END	

GO

-- =============================================
-- Created by:    Enrique Sierra Gtez
-- Creation Date: 2016-10-27
-- 
-- Description: Procedimiento encargado de genera
-- toda la informacion necesaria para realizar 
-- las conciliaciones contable.
--
-- Example: EXEC CUP_SPP_ConciliacionCont 63527, 1, 2016, 9
-- =============================================


CREATE PROCEDURE dbo.CUP_SPP_ConciliacionCont
  @Empleado INT,
  @Tipo INT,
  @Ejercicio INT,
  @Periodo INT
AS BEGIN 

  SET NOCOUNT ON;

  DELETE CUP_ConciliacionCont
  WHERE Empleado = @Empleado
 
  INSERT INTO CUP_ConciliacionCont
  (
    Empleado,
    Tipo,
    Ejercicio,
    Periodo
  )
  VALUES
  (
    @Empleado,
    @Tipo,
    @Ejercicio,
    @Periodo
  )

  -- Auxiliares Cx
  EXEC CUP_SPI_ConciliacionCont_AuxCx @Empleado, @Tipo, @Ejercicio, @Periodo

  -- Auxiliares Contables
  EXEC CUP_SPI_ConciliacionCont_AuxCont @Empleado, @Tipo, @Ejercicio, @Periodo
  
  -- Auxiliares Modulo
  EXEC CUP_SPI_ConciliacionCont_AuxModulo @Empleado, @Tipo, @Ejercicio, @Periodo

  -- Devuelve la Caratula Contable de la conciliacion requerida
  EXEC CUP_SPQ_ConciliacionCont_Caratula @Empleado, @Tipo, @Ejercicio, @Periodo

END