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

  Example: EXEC CUP_SPQ_ConciliacionCont_AuxCxcIVATrasladado 63527, 4, 2016, 12
============================================= */

CREATE PROCEDURE dbo.CUP_SPQ_ConciliacionCont_AuxCxcIVATrasladado
  @Empleado INT,
  @Tipo INT,
  @Ejercicio INT,
  @Periodo INT
AS BEGIN 

  SET NOCOUNT ON;

  DECLARE 
    @FechaInicio DATETIME = CAST(  
                                  CAST( @Ejercicio As VARCHAR )
                                  + '-'
                                  + CAST(  @Periodo As VARCHAR )
                                  + '-'
                                  + '01'
                                 AS DATE),
    @FechaFin DATETIME
  
  SET @FechaFin = DATEADD( DAY, -1, DATEADD( MONTH, 1, @FechaInicio ) )
  
  IF OBJECT_ID('tempdb..#CUP_AuxDepositosCortesCaja') IS NOT NULL
   DROP TABLE #CUP_AuxDepositosCortesCaja

  CREATE TABLE #CUP_AuxDepositosCortesCaja
  (
    Empresa VARCHAR(5) NOT NULL,
    Sucursal INT NOT NULL,
    ID INT NOT NULL,
    Mov CHAR(20) NOT NULL,
    Movid	VARCHAR(20) NOT NULL,
    FechaEmision DATETIME NOT NULL,
    Ejercicio	INT NOT NULL,
    Periodo INT NOT NULL,
    Estatus	VARCHAR(15) NOT NULL,
    CtaDinero CHAR(10)	NOT NULL,
    CtaDineroDestino CHAR(10) NULL,
    Aplica CHAR(20) NOT NULL,
    AplicaID VARCHAR(20) NOT NULL,
    Moneda CHAR(10) NOT NULL,
    TipoCambio FLOAT NOT NULL,
    Cargo DECIMAL(18,4) NOT NULL,
    Abono DECIMAL(18,4) NOT NULL,
    Neto DECIMAL(18,4) NOT NULL,
    FormaPago	VARCHAR(50) NULL,
    IVAFiscal FLOAT NOT NULL,
    CorteID INT NOT NULL,
    CorteMov CHAR(20) NOT NULL,
    CorteMovID VARCHAR(20) NULL,
    EsCancelacion BIT NOT NULL
  )
  
  EXEC CUP_SPQ_AuxiliarDepositosCortesCaja @FechaInicio, @FechaFin, NULL

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
    Cargo = ROUND( ISNULL(calc.Cargo, 0) , 4, 1),
    Abono = ROUND( ISNULL(calc.Abono, 0) , 4, 1),
    Neto  = ROUND( ISNULL(calc.Neto,  0) , 4, 1),
    CargoMN =  ROUND(
                        ISNULL(calc.Cargo, 0)
                      * ISNULL( movEnOrigen.TipoCambio, ISNULL( primer_tc.TipoCambio, ISNULL(doc.ClienteTipoCambio, aux.TipoCambio) ) )
                    , 4, 1),
    AbonoMN = ROUND( 
                       ISNULL(calc.Abono, 0)
                     * ISNULL( movEnOrigen.TipoCambio, ISNULL( primer_tc.TipoCambio, ISNULL(doc.ClienteTipoCambio, aux.TipoCambio) ) )
                   , 4, 1),
    NetoMN = ROUND( 
                      ISNULL(calc.Neto, 0)
                    * ISNULL( movEnOrigen.TipoCambio, ISNULL( primer_tc.TipoCambio, ISNULL(doc.ClienteTipoCambio, aux.TipoCambio) ) )
                  , 4, 1),
    FluctuacionMN = 0,
    TotalMN = ROUND( 
                     ISNULL(calc.Neto, 0)
                   * ISNULL( movEnOrigen.TipoCambio, ISNULL( primer_tc.TipoCambio, ISNULL(doc.ClienteTipoCambio, aux.TipoCambio) ) )
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
   -- Primer Tc
   OUTER APPLY(SELECT TOP 1 
                 first_aux.TipoCambio
               FROM 
                 Auxiliar first_aux 
               JOIN Rama fr ON fr.Rama = first_aux.Rama 
               WHERE 
                 fr.Mayor = 'CXC'
               AND first_aux.Modulo = 'CXC'
               AND first_aux.ModuloID = doc.ID
               ORDER BY 
                first_aux.ID ASC ) primer_tc
  -- CALCULADOS
  OUTER APPLY (
               SELECT 
                Cargo = ISNULL(aux.Cargo, 0)
                      * aux.IVAFiscal,
                Abono = ISNULL(aux.Abono, 0)
                      * aux.IVAFiscal,
                Neto  =  ISNULL(aux.Neto, 0)
                      * aux.IVAFiscal  
              ) calc
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
    Rama = 'CXC',
    AuxID = NULL,
    depositos.Sucursal,
    depositos.CtaDinero,
    depositos.Mov,
    depositos.MovId,
    Modulo = 'DIN',
    depositos.ID,
    depositos.Moneda,
    depositos.TipoCambio,
    depositos.Ejercicio,
    depositos.Periodo,
    Fecha = depositos.FechaEmision,
    Cargo =  ROUND( ISNULL( calc.Cargo, 0), 4, 1),
    Abono = ROUND( ISNULL( calc.Abono, 0), 4, 1),
    Neto = ROUND( ISNULL( calc.Neto, 0) , 4, 1),
    CargoMN =  ROUND(
                       ISNULL( calc.Cargo, 0)
                     * depositos.TipoCambio
                    , 4, 1),
    AbonoMN = ROUND( 
                       ISNULL( calc.Abono, 0) 
                     * depositos.TipoCambio
                   , 4, 1),
    NetoMN = ROUND( 
                     ISNULL( calc.Neto, 0)
                   * depositos.TipoCambio
                  , 4, 1),
    FluctuacionMN = 0,
    TotalMN = ROUND( 
                     ISNULL( calc.Neto, 0)
                   * depositos.TipoCambio
                  , 4, 1),
    depositos.EsCancelacion,
    depositos.Aplica,
    depositos.AplicaID,
    OrigenTipo = 'DIN',
    Origen = depositos.CorteMov,
    OrigenID = depositos.CorteMovID
  FROM 
    #CUP_AuxDepositosCortesCaja depositos
  -- Calculados
  CROSS APPLY(
             SELECT 
               Cargo = ISNULL(depositos.Cargo, 0) 
                     * ISNULL(depositos.IVAFiscal, 0),
               Abono = ISNULL(depositos.Abono, 0) 
                     * ISNULL(depositos.IVAFiscal, 0),
               Neto  = ISNULL(depositos.Neto, 0) 
                     * ISNULL(depositos.IVAFiscal, 0)
                      
             ) calc

   
END