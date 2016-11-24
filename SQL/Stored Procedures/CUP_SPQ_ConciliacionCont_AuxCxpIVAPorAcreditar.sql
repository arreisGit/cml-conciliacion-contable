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

/* =============================================
  Created by:    Enrique Sierra Gtez
  Creation Date: 2016-11-17

  Description: Regresa el auxiliar del IVA Por Acreditar

  Example: EXEC CUP_SPQ_ConciliacionCont_AuxCxpIVAPorAcreditar 63527, 2, 2016, 10
============================================= */


CREATE PROCEDURE dbo.CUP_SPQ_ConciliacionCont_AuxCxpIVAPorAcreditar
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
    CargoMN = ROUND( aux.CargoMN * aux.IVAFiscal, 4, 1),
    AbonoMN = ROUND( aux.AbonoMN * aux.IVAFiscal, 4, 1),
    NetoMN = ROUND( aux.NetoMN * aux.IVAFiscal, 4, 1),
    FluctuacionMN = ROUND( calc.FluctuacionMN * aux.IVAFiscal ,4 ,1 ),
    TotalMN = ROUND(  
                    ( aux.NetoMN + calc.FluctuacionMN )
                    * aux.IVAFiscal
              ,4,1),
    aux.EsCancelacion,
    aux.Aplica,
    aux.AplicaID,
    aux.OrigenModulo,
    aux.OrigenMov,
    aux.OrigenMovID
  FROM
    CUP_v_AuxiliarCxp aux
  LEFT JOIN CUP_ConciliacionCont_Excepciones ex ON ex.TipoConciliacion = @Tipo 
                                               AND ex.TipoExcepcion = 1 
                                               AND ex.Valor = LTRIM(RTRIM(aux.Cuenta))
  LEFT JOIN CUP_v_CxDiferenciasCambiarias fc ON fc.Modulo = aux.Modulo
                                          AND fc.ModuloID = aux.ModuloId
                                          AND fc.Documento = aux.Aplica
                                          AND fc.DocumentoID = aux.AplicaID
  -- Factores
  CROSS APPLY(SELECT
                FactorCanc  = CASE ISNULL(aux.EsCancelacion,0) 
                                WHEN 1 THEN
                                  -1
                                ELSE 
                                  1
                              END) f 
  -- Campos Calculados
CROSS APPLY ( SELECT
                FluctuacionMN =  ROUND( -ISNULL(fc.Diferencia_Cambiaria_MN,0) * ISNULL(f.FactorCanc,1),4,1)
            ) Calc
  WHERE 
    aux.Ejercicio = @Ejercicio
  AND aux.Periodo = @Periodo
  AND ex.ID IS NULL
  AND aux.Rama <> 'REV'
  AND aux.MovClave NOT IN ('CXP.ANC','CXP.RE')

END