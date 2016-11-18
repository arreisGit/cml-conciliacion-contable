SET ANSI_NULLS, ANSI_WARNINGS ON;

GO

IF EXISTS (SELECT * 
		   FROM SYSOBJECTS 
		   WHERE ID = OBJECT_ID('dbo.CUP_SPQ_ConciliacionCont_AuxCxpIVAPorAcreditar') AND 
				 TYPE = 'P')
BEGIN
  DROP PROCEDURE dbo.CUP_SPQ_ConciliacionCont_AuxCxpIVAPorAcreditar
END	

GO

-- =============================================
-- Created by:    Enrique Sierra Gtez
-- Creation Date: 2016-11-17
--
-- Description: Regresa el auxiliar del IVA Por Acreditar
--
-- Example: EXEC CUP_SPQ_ConciliacionCont_AuxCxpIVAPorAcreditar 63527, 2, 2016, 10
-- =============================================


CREATE PROCEDURE dbo.CUP_SPQ_ConciliacionCont_AuxCxpIVAPorAcreditar
  @Empleado INT,
  @Tipo INT,
  @Ejercicio INT,
  @Periodo INT
AS BEGIN 

  SET NOCOUNT ON;

  SELECT
    Empleado = @Empleado,
    Rama = 'CXP',
    AuxID  = aux.ID,
    aux.Ejercicio,
    aux.Periodo,
    aux.Fecha,
    aux.Sucursal,
    aux.Cuenta,
    aux.Modulo,
    aux.ModuloID,
    aux.Mov,
    aux.MovID,
    aux.Moneda,
    aux.TipoCambio,
    Cargo = ISNULL(aux.Cargo,0),
    Abono = ISNULL(aux.Abono,0),
    Neto = calc.Neto,
    CargoMN = ROUND(ISNULL(aux.Cargo,0) * aux.TipoCambio * aux.IVAFiscal,4,1),
    AbonoMN = ROUND(ISNULL(aux.Abono,0) * aux.TipoCambio * aux.IVAFiscal,4,1),
    NetoMN =  ROUND(ISNULL(calc.Neto,0) * aux.TipoCambio * aux.IVAFiscal,4,1),
    FluctuacionMN  = 0 ,-- ,ROUND(calc.FluctuacionMN * -1 * ISNULL(fctorCanc.Factor,1),4,1),
    TotalMN = ROUND(  
                    (calc.Neto * aux.TipoCambio * aux.IVAFiscal)
                  + 0 --(calc.FluctuacionMN * -1 * ISNULL(fctorCanc.Factor,1))
              ,4,1),
    aux.Aplica,
    aux.AplicaID,
    aux.EsCancelacion,
    OrigenModulo = ISNULL(p.OrigenTipo,''),
    OrigenModuloID = ISNULL(CAST(ISNULL(c.ID,g.ID) AS VARCHAR),''),
    OrigenMov = ISNULL(p.Origen,''),
    OrigenMovID = ISNULL(p.OrigenID,'')
  FROM
    CUP_v_CxAuxiliarImpuestos aux
    -- Excepciones Cuentas
  LEFT JOIN CUP_ConciliacionCont_Excepciones eX ON ex.TipoConciliacion = @Tipo
                                                AND ex.TipoExcepcion = 1
                                                AND ex.Valor = aux.cuenta
  JOIN Cxp p ON 'CXP' = aux.Modulo
            AND p.ID = aux.ModuloID
  JOIN Prov ON prov.Proveedor = Aux.Cuenta
  LEFT JOIN Compra c ON 'COMS' = p.OrigenTipo
                    AND c.Mov = p.Origen
                    AND c.MovID = p.OrigenID
  LEFT JOIN Gasto g ON 'GAS' = p.OrigenTipo
                    AND g.Mov = p.Origen
                    AND g.MovID = p.OrigenID
  -- Factor Canceclacion
  CROSS APPLY(SELECT
                Factor  = CASE ISNULL(aux.EsCancelacion,0) 
                            WHEN 1 THEN
                              -1
                            ELSE 
                              1
                          END) fctorCanc 
  -- Fluctuacion Cambiaria
  LEFT JOIN CUP_v_CxDiferenciasCambiarias fc ON fc.Modulo = aux.Modulo
                                            AND fc.ModuloID = aux.ModuloId
                                            AND fc.Documento = aux.Aplica
                                            AND fc.DocumentoID = aux.AplicaID
  -- Campos Calculados
  CROSS APPLY ( SELECT   
                  Neto = (ISNULL(aux.Cargo,0) - ISNULL( aux.Abono,0)) * aux.IVAFiscal,
                  FluctuacionMN  = ISNULL(fc.Diferencia_Cambiaria_MN,0)
              ) Calc
   
  WHERE
    aux.Ejercicio = @Ejercicio 
  AND aux.Periodo = @Periodo
  -- Filtro Excepciones cuenta
  AND eX.ID IS NULL

END