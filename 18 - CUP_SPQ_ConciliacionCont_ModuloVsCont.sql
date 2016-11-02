SET ANSI_NULLS, ANSI_WARNINGS ON;

GO

IF EXISTS (SELECT * 
		   FROM SYSOBJECTS 
		   WHERE ID = OBJECT_ID('dbo.CUP_SPQ_ConciliacionCont_ModuloVsCont') AND 
				 TYPE = 'P')
BEGIN
  DROP PROCEDURE dbo.CUP_SPQ_ConciliacionCont_ModuloVsCont 
END	


GO

-- =============================================
-- Created by:    Enrique Sierra Gtez
-- Creation Date: 2016-10-20
--
-- Description: Cruza los auxiliares de
-- Modulo y Contabilidad, sobre un Ejercicio/Periodo
-- y con la suficiente informacion para facilitar  
-- la conciliacion.
-- 
-- Example: EXEC CUP_SPQ_ConciliacionCont_ModuloVsCont 63527, 'Pago'
--
-- =============================================


CREATE PROCEDURE dbo.CUP_SPQ_ConciliacionCont_ModuloVsCont
  @Empleado INT,
  @Concepto  VARCHAR(20)
AS BEGIN 
    
  --SELECT 
  --  Modulo = 'COMS',
  --  Id = 0,
  --  Mov = 'Something',
  --  MovID = 'Else',
  --  PolizaId = 0,
  --  PolizaMov = 'Cont',
  --  PolizaMovID = ':D',
  --  TotalModuloMN = 0,
  --  NetoCont  = 0,
  --  Variacion  = 0

  
  ---- 3) Cruzamos los auxiliares de Modulo y Contabilidad entre si
  SELECT
    modulo.Modulo,
    Id = CAST(modulo.ID AS VARCHAR),
    modulo.Mov,
    modulo.MovId,
    modulo.Estatus,
    modulo.PolizaID,
    ConciliacionPolizaID    = cont.Id,
    ConciliacionPolizaMov   = cont.Mov,
    ConciliacionPolizaMovID = cont.Movid,
    TotalModuloMN = CAST(ISNULL(modulo.ImporteTotalMN,0) AS FLOAT),
    NetoCont =  CAST(ISNULL(cont.Neto,0) AS FLOAT),
    Variacion = CAST(ISNULL(modulo.ImporteTotalMN,0)  - ISNULL(cont.Neto,0) AS FLOAT)
  FROM 
    CUP_ConciliacionCont_AuxModulo modulo
  FULL OUTER JOIN CUP_ConciliacionCont_AuxCont cont ON modulo.PolizaID = cont.ID
                                                  AND modulo.AuxiliarMov = cont.AuxiliarMov
  WHERE 
    ISNULL(modulo.AuxiliarMov, cont.AuxiliarMov ) = @Concepto
  AND ABS(ISNULL(modulo.ImporteTotalMN,0)  - ISNULL(cont.Neto,0)) >= 1
END