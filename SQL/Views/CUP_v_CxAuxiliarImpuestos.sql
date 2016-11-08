SET ANSI_NULLS, ANSI_WARNINGS ON;

GO 

-- =============================================
-- Created by:    Enrique Sierra Gtez
-- Creation Date: 2016-11-07
--
-- Description: Desglosa el flujo auxiliares
-- junto con los impuestos correspondientes.
-- 
-- Example: SELECT * 
--         FROM  CUP_v_CxAuxiliarImpuestos
--         WHERE Modulo = 'CXP'
--         AND ModuloID = 108192
-- =============================================


IF EXISTS(SELECT * FROM sysobjects WHERE name='CUP_v_CxAuxiliarImpuestos')
	DROP VIEW CUP_v_CxAuxiliarImpuestos
GO
CREATE VIEW CUP_v_CxAuxiliarImpuestos
AS
SELECT 
  aux.Id,
  aux.Empresa,
  aux.Sucursal,
  aux.Cuenta,
  aux.Fecha,
  aux.Ejercicio,
  aux.Periodo,
  aux.Modulo,
  aux.ModuloID,
  aux.Mov,
  aux.Movid,
  aux.Moneda,
  aux.TipoCambio,
  aux.Cargo,
  aux.Abono,
  aux.Aplica,
  aux.AplicaID,
  aux.EsCancelacion,
  IVAFiscal  = ISNULL(doc.IvaFiscal,0)
FROM 
  Auxiliar aux
JOIN Movtipo t ON t.Modulo = aux.Modulo 
              AND t.Mov = aux.Mov
JOIN Rama r ON r.Rama = aux.Rama
JOIN Movtipo at ON at.Modulo = 'CXP' 
               AND at.Mov = aux.Aplica
JOIN Cxp doc ON doc.Mov = aux.Aplica
            AND doc.MovID = aux.AplicaID
WHERE   
  r.Mayor = 'CXP'
AND ISNULL(at.Clave,'') NOT IN ('CXP.SCH','CXP.SD')
AND aux.Modulo = 'CXP'
