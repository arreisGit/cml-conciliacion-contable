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
    Cargo =  ROUND( ISNULL(aux.Cargo, 0)  * aux.IVAFiscal, 4, 1),
    Abono = ROUND( ISNULL(aux.Abono, 0) * aux.IVAFiscal, 4, 1),
    Neto = ROUND( aux.Neto * aux.IVAFiscal, 4, 1),
    CargoMN =  ROUND(
                      aux.Cargo
                      * aux.IVAFiscal 
                      * ISNULL( movEnOrigen.TipoCambio, ISNULL(doc.ClienteTipoCambio, aux.TipoCambio) )
                    , 4, 1),
    AbonoMN = ROUND( 
                       aux.Abono 
                     * aux.IVAFiscal
                     * ISNULL( movEnOrigen.TipoCambio, ISNULL(doc.ClienteTipoCambio, aux.TipoCambio ) )
                   , 4, 1),
    NetoMN = ROUND( 
                     aux.Neto
                   * aux.IVAFiscal
                   * ISNULL( movEnOrigen.TipoCambio, ISNULL(doc.ClienteTipoCambio, aux.TipoCambio ) )
                  , 4, 1),
    FluctuacionMN = 0,
    TotalMN = ROUND( 
                     aux.Neto
                   * aux.IVAFiscal
                   * ISNULL( movEnOrigen.TipoCambio, ISNULL(doc.ClienteTipoCambio, aux.TipoCambio ) )
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
  -- Movimiento
  OUTER APPLY (
               SELECT TOP 1
                  cm.CtaDinero,
                  cm.Estatus
               FROM 
                  Cxc cm 
               WHERE 
                 aux.Modulo = 'CXC'
               AND cm.ID = aux.ModuloID 
               UNION 
               SELECT TOP 1
                  CtaDinero = NULL,
                  vm.Estatus
               FROM 
                Venta vm 
               WHERE 
                 aux.Modulo = 'VTAS'
               AND vm.ID = aux.ModuloID 
            ) mov
  LEFT JOIN Cxc doc ON doc.Mov = aux.Aplica
                   AND doc.MovId = aux.AplicaID
  LEFT JOIN CtaDinero ON CtaDinero.CtaDinero = mov.CtaDinero
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
  -- Cobros a Caja Chica no afectan el IVA TRASLADADO 
  -- hasta el deposito.
  AND NOT ( aux.MovClave = 'CXC.C' AND CtaDinero.Tipo = 'Caja')

  UNION   -- UNION DEPOSITOS QUE POVIENEN DE CAJAS CHICAS

  SELECT
    Empleado = @Empleado,
    aux.Rama,
    aux.ID,
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
    Cargo =  ROUND( ISNULL( aux.Cargo, 0)  * solDev.IVAFiscal, 4, 1),
    Abono = ROUND( ISNULL( aux.Abono, 0) * solDev.IVAFiscal, 4, 1),
    Neto = ROUND( ISNULL( calc.Neto, 0) * solDev.IVAFiscal, 4, 1),
    CargoMN =  ROUND(
                      ISNULL( aux.Cargo, 0)
                      * solDev.IVAFiscal 
                      * aux.TipoCambio
                    , 4, 1),
    AbonoMN = ROUND( 
                       ISNULL( aux.Abono, 0) 
                     * solDev.IVAFiscal
                     * aux.TipoCambio
                   , 4, 1),
    NetoMN = ROUND( 
                     calc.Neto
                   * solDev.IVAFiscal
                   * aux.TipoCambio
                  , 4, 1),
    FluctuacionMN = 0,
    TotalMN = ROUND( 
                    calc.Neto
                   * solDev.IVAFiscal
                   * aux.TipoCambio
                  , 4, 1),
    aux.EsCancelacion,
    aux.Aplica,
    aux.AplicaID,
    solDev.OrigenTipo,
    solDev.Origen,
    solDev.OrigenID
  FROM 
    Auxiliar aux
  JOIN Rama r ON r.Rama = aux.Rama
  JOIN movtipo t ON t.Modulo = 'DIN'
                AND t.Mov = aux.Mov
  JOIN Dinero solDev ON solDev.Mov  = aux.Mov
                     AND solDev.MovID = aux.MovID
  -- Corte Caja / Corte Tombola.
  CROSS APPLY(SELECT TOP 1 
                ID = mf.OID 
              FROM 
                dbo.fnCMLMovFlujo('DIN', solDev.ID, 1) mf 
              WHERE 
                mf.Indice < 0 
              AND mf.OModulo = 'DIN'
              AND mf.OMovTipo = 'DIN.CP'
              AND mf.OMovSubTipo = 'DIN.CPMULTIMONEDA') corte
  -- Calculados
  CROSS APPLY(SELECT 
                Neto = ISNULL(Cargo,0) - ISNULL(Abono,0)
              ) calc
  WHERE
    r.Mayor = 'CXC'
  AND t.Clave = 'DIN.SD'
  AND aux.Ejercicio = @Ejercicio
  AND aux.Periodo = @Periodo
  AND corte.ID IS NOT NULL

END