SET ANSI_NULLS, ANSI_WARNINGS ON;

GO

IF EXISTS (SELECT * 
		   FROM SYSOBJECTS 
		   WHERE ID = OBJECT_ID('dbo.CUP_SPI_ConciliacionCont_AuxModulo') AND 
				 TYPE = 'P')
BEGIN
  DROP PROCEDURE dbo.CUP_SPI_ConciliacionCont_AuxModulo 
END	

GO

-- =============================================
-- Created by:    Enrique Sierra Gtez
-- Creation Date: 2016-10-24
--
-- Example: EXEC CUP_SPI_ConciliacionCont_AuxModulo 63527, 1, 2016, 9
-- =============================================


CREATE PROCEDURE dbo.CUP_SPI_ConciliacionCont_AuxModulo
  @Empleado INT,
  @Tipo INT,
  @Ejercicio INT,
  @Periodo INT
AS BEGIN 
  
  SET NOCOUNT ON;

  DELETE CUP_ConciliacionCont_AuxModulo
  WHERE Empleado = @Empleado
 
  IF @Tipo IN (
                1 -- Saldo Proveedores
               --,2  -- IVA X Acreeditar
               ) 
  BEGIN
    
    INSERT INTO CUP_ConciliacionCont_AuxModulo
    EXEC CUP_SPQ_ConciliacionCont_OrigenContCxp @Empleado, @Tipo, @Ejercicio, @Periodo

    INSERT INTO CUP_ConciliacionCont_AuxModulo
    EXEC CUP_SPQ_ConciliacionCont_OrigenContCOMS @Empleado, @Tipo, @Ejercicio, @Periodo

    INSERT INTO CUP_ConciliacionCont_AuxModulo
    EXEC CUP_SPQ_ConciliacionCont_OrigenContGas @Empleado, @Tipo, @Ejercicio, @Periodo

  END
 

  /* Saldo Clientes */
  IF @Tipo = 3 
  BEGIN
    
    INSERT INTO CUP_ConciliacionCont_AuxModulo
    EXEC CUP_SPQ_ConciliacionCont_OrigenContCxc @Empleado, @Tipo, @Ejercicio, @Periodo

    INSERT INTO CUP_ConciliacionCont_AuxModulo
    EXEC CUP_SPQ_ConciliacionCont_OrigenContVtas @Empleado, @Tipo, @Ejercicio, @Periodo

  END 

END