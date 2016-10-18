SET ANSI_NULLS, ANSI_WARNINGS ON;

GO

IF EXISTS (SELECT * 
		   FROM SYSOBJECTS 
		   WHERE ID = OBJECT_ID('dbo.CUP_spq_CxAuxiliarModuloCxp') AND 
				 TYPE = 'P')
BEGIN
  DROP PROCEDURE dbo.CUP_spq_CxAuxiliarModuloCxp 
END	


GO

-- =============================================
-- Created by:    Enrique Sierra Gtez
-- Creation Date: 2016-10-17
-- Last Modified: 2016-10-17 
--
-- Description: Obtiene los movimientos que componen
-- el origen contable de los Auxiliares de Cx/Cxp
-- 
-- Example: EXEC CUP_spq_CxAuxiliarOrigenContable 'CXP', 2016, 9
-- =============================================


CREATE PROCEDURE dbo.CUP_spq_CxAuxiliarOrigenContable
  @Modulo CHAR(5),
  @Ejercicio INT,
  @Periodo INT
AS BEGIN 

   -- LLena Tabla de Origenes Contables


   --  Liga los origenes con su poliza correspondiente y regresa el resultado.
    
END