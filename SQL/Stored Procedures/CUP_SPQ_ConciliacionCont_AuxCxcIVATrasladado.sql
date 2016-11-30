SET ANSI_NULLS, ANSI_WARNINGS ON;

GO

IF EXISTS (SELECT * 
		   FROM SYSOBJECTS 
		   WHERE ID = OBJECT_ID('dbo.CUP_SPQ_ConciliacionCont_AuxCxcIVATrasladado') AND 
				 TYPE = 'P')
BEGIN
  DROP PROCEDURE dbo.CUP_SPQ_ConciliacionCont_AuxCxcIVATrasladado
END	

GO

/* =============================================
  Created by:    Enrique Sierra Gtez
  Creation Date: 2016-11-28

  Description: Regresa el auxiliar del IVA Trasladado

  Example: EXEC CUP_SPQ_ConciliacionCont_AuxCxcIVATrasladado 63527, 4, 2016, 10
============================================= */


CREATE PROCEDURE dbo.CUP_SPQ_ConciliacionCont_AuxCxcIVATrasladado
  @Empleado INT,
  @Tipo INT,
  @Ejercicio INT,
  @Periodo INT
AS BEGIN 

  SET NOCOUNT ON;

  SELECT
    Empleado = @Empleado,
    aux.Rama,
    aux.AuxID,
    aux.Sucursal,
    aux.Cuenta,
    aux.Mov,
    aux.MovId,
    aux.Modulo,
    aux.ModuloID,
    aux.Moneda,
    aux.TipoCambio,
    aux.Ejercicio,
    aux.Periodo,
    aux.Fecha,
    Cargo =  ROUND( aux.Cargo  * aux.IVAFiscal, 4, 1),
    Abono = ROUND( aux.Abono * aux.IVAFiscal, 4, 1),
    Neto = ROUND( aux.Neto * aux.IVAFiscal, 4, 1),
    CargoMN =  ROUND(
                      aux.Cargo
                      * aux.IVAFiscal 
                      * ISNULL( movEnOrigen.TipoCambio, doc.ClienteTipoCambio )
                    , 4, 1),
    AbonoMN = ROUND( 
                       aux.Abono 
                     * aux.IVAFiscal
                     * ISNULL( movEnOrigen.TipoCambio, doc.ClienteTipoCambio )
                   , 4, 1),
    NetoMN = ROUND( 
                     aux.Neto
                   * aux.IVAFiscal
                   * ISNULL( movEnOrigen.TipoCambio, doc.ClienteTipoCambio )
                  , 4, 1),
    FluctuacionMN = 0,
    TotalMN = ROUND( 
                     aux.Neto
                   * aux.IVAFiscal
                   * ISNULL( movEnOrigen.TipoCambio, doc.ClienteTipoCambio )
                  , 4, 1),
    aux.EsCancelacion,
    aux.Aplica,
    aux.AplicaID,
    aux.OrigenModulo,
    aux.OrigenMov,
    aux.OrigenMovID
  FROM
    CUP_v_AuxiliarCxc aux
  LEFT JOIN CUP_ConciliacionCont_Excepciones ex ON ex.TipoConciliacion = @Tipo 
                                               AND ex.TipoExcepcion = 1 
                                               AND ex.Valor = LTRIM(RTRIM(aux.Cuenta))
  LEFT JOIN Cxc doc ON doc.Mov = aux.Aplica
                   AND doc.MovId = aux.AplicaID
  -- MovFlujo Origen
  OUTER APPLY(
                SELECT TOP 1
                  mf.OModulo,
                  mf.OID
                FROM 
                  MovFlujo mf 
                WHERE 
                  mf.DModulo = 'CXC'
                AND mf.DID = doc.ID
                AND mf.OModulo = doc.OrigenTipo
                AND mf.OMov = doc.Origen
                AND mf.OMovID = doc.OrigenID
              ) mfOrigen
  -- Datos del doc en Modulo Origen
  OUTER APPLY ( SELECT TOP 1
                  vta.TipoCambio
                FROM 
                  Venta vta
                WHERE 
                 'VTAS'    =  mfOrigen.OModulo 
                AND vta.ID = mfOrigen.OID
              ) movEnOrigen
  WHERE 
    aux.Ejercicio = @Ejercicio
  AND aux.Periodo = @Periodo
  AND ex.ID IS NULL
  AND aux.Rama <> 'REV'
  AND aux.MovClave NOT IN ('CXC.RE')

END