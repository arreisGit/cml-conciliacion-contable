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
-- Example: EXEC CUP_SPQ_ConciliacionCont_ModuloVsCont 63527, 'Ajuste'
--
-- =============================================


CREATE PROCEDURE dbo.CUP_SPQ_ConciliacionCont_ModuloVsCont
  @Empleado INT,
  @Concepto  VARCHAR(20)
AS BEGIN 

  SELECT
    modulo.Modulo,
    modulo.ID,
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
                                                  AND modulo.Empleado = cont.Empleado
  WHERE 
    ISNULL(modulo.Empleado,cont.Empleado) = @Empleado
  AND ISNULL(modulo.AuxiliarMov, cont.AuxiliarMov ) = @Concepto
  AND ABS(ISNULL(modulo.ImporteTotalMN,0)  - ISNULL(cont.Neto,0)) >= 0.01

END