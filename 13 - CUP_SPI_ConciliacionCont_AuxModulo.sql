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
-- Example: EXEC CUP_SPI_ConciliacionCont_AuxModulo 2016, 9
-- =============================================


CREATE PROCEDURE dbo.CUP_SPI_ConciliacionCont_AuxModulo
  @Ejercicio INT,
  @Periodo INT
AS BEGIN 

 
END