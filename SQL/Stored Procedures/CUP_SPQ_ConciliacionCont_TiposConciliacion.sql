SET ANSI_NULLS, ANSI_WARNINGS ON;

GO

IF EXISTS (SELECT * 
		   FROM SYSOBJECTS 
		   WHERE ID = OBJECT_ID('dbo.CUP_SPQ_ConciliacionCont_TiposConciliacion') AND 
				 TYPE = 'P')
BEGIN
  DROP PROCEDURE dbo.CUP_SPQ_ConciliacionCont_TiposConciliacion 
END	


GO

-- =============================================
-- Created by:    Enrique Sierra Gtez
-- Creation Date: 2016-11-01
--
-- Description: Devuelve los tipos
-- de conciliacion Contable que estan configurados en el sistema.
-- 
-- Example: EXEC CUP_SPQ_ConciliacionCont_TiposConciliacion
--
-- =============================================


CREATE PROCEDURE dbo.CUP_SPQ_ConciliacionCont_TiposConciliacion
AS BEGIN 
  
  SET NOCOUNT ON;
  
  SELECT 
    ID,
    Descripcion
  FROM 
    CUP_ConciliacionCont_Tipos
  ORDER BY
    ID ASC
END