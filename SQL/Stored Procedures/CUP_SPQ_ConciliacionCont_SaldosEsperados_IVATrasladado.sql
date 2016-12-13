SET ANSI_NULLS, ANSI_WARNINGS ON;

GO

IF EXISTS (SELECT * 
		   FROM SYSOBJECTS 
		   WHERE ID = OBJECT_ID('dbo.CUP_SPQ_ConciliacionCont_SaldosEsperados_IVATrasladado') AND 
				 TYPE = 'P')
BEGIN
  DROP PROCEDURE dbo.CUP_SPQ_ConciliacionCont_SaldosEsperados_IVATrasladado
END	

GO

 /*=============================================
   Created by:    Enrique Sierra Gtez
   Creation Date: 2016-11-30

   Description: Obtiene los Saldos Iniciales y Finales
   que se usaran para la conciliacion Cotable del IVA Por Acreditar
 
   Example: EXEC CUP_SPQ_ConciliacionCont_SaldosEsperados_IVATrasladado 2016, 10
 ============================================= */


CREATE PROCEDURE dbo.CUP_SPQ_ConciliacionCont_SaldosEsperados_IVATrasladado
  @Ejercicio INT,
  @Periodo   INT
AS BEGIN 

  SET NOCOUNT ON;

  DECLARE
    @OnceUponATime DATETIME = '1900-01-01',
    @FechaInicio DATETIME = CAST(  
                                  CAST( @Ejercicio As VARCHAR )
                                  + '-'
                                  + CAST(  @Periodo As VARCHAR )
                                  + '-'
                                  + '01'
                                 AS DATE),
    @FechaFin DATETIME
  
  SET @FechaFin = DATEADD( DAY, -1, DATEADD( MONTH, 1, @FechaInicio ) )
  
  IF OBJECT_ID('tempdb..##CUP_AuxDepositosCortesCajaHist') IS NOT NULL
    DROP TABLE #CUP_AuxDepositosCortesCajaHist

  CREATE TABLE #CUP_AuxDepositosCortesCajaHist
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

  INSERT INTO #CUP_AuxDepositosCortesCajaHist 
  (
    Empresa,
    Sucursal,
    ID,
    Mov,
    Movid,
    FechaEmision,
    Ejercicio,
    Periodo,
    Estatus,
    CtaDinero,
    CtaDineroDestino,
    Aplica,
    AplicaID,
    Moneda,
    TipoCambio,
    Cargo,
    Abono,
    Neto,
    FormaPago,
    IVAFiscal,
    CorteID,
    CorteMov,
    CorteMovID,
    EsCancelacion
  )
  EXEC CUP_SPQ_AuxiliarDepositosCortesCaja @OnceUponATime, @FechaFin, NULL

  DECLARE @AntSaldosCxCorte TABLE
  (
    Mov CHAR(20) NOT NULL,
    MovID VARCHAR(20) NOT NULL,
    Moneda CHAR(10) NOT NULL,
    SaldoInicial DECIMAL(18,4) NOT NULL,
    SaldoFinal DECIMAL(18,4) NOT NULL
    PRIMARY KEY ( 
                    Mov,
                    MovID,
                    Moneda
                )
  )

  INSERT INTO @AntSaldosCxCorte
  (
    Mov,
    MovID,
    Moneda,
    SaldoInicial,
    SaldoFinal
  )
  SELECT 
    Mov = aux.Aplica,
    MovId  = ISNULL(aux.AplicaID,''),
    aux.Moneda,
    SaldoInicial = SUM(CASE 
                          WHEN aux.Ejercicio < @Ejercicio
                            OR (    
                                    aux.Ejercicio = @Ejercicio
                                ANd aux.Periodo < @Periodo
                                ) THEN 
                            ( ISNULL(aux.Cargo,0) - ISNULL(aux.Abono,0) ) * aux.IVAFiscal 
                          ELSE 
                            0
                        END),
    SaldoFinal = SUM( ( ISNULL(aux.Cargo,0) - ISNULL(aux.Abono,0) ) * aux.IVAFiscal )
  FROM 
    CUP_v_AuxiliarCxc aux
  -- Excepciones Cuentas
  LEFT JOIN CUP_ConciliacionCont_Excepciones eX ON ex.TipoConciliacion = 4 -- IVA Trasladado
                                                AND ex.TipoExcepcion = 1
                                                AND ex.Valor = aux.cuenta
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
  LEFT JOIN CtaDinero ON CtaDinero.CtaDinero = mov.CtaDinero
  WHERE 
    aux.Rama <> 'REV'
  AND aux.MovClave NOT IN ('CXC.RE')
  AND (
          aux.Ejercicio < @Ejercicio
      OR (
              aux.Ejercicio = @Ejercicio 
          AND aux.Periodo <= @Periodo  
          )
      )
  AND eX.Id IS NULL
  -- Cobros a Caja Chica no afectan el IVA TRASLADADO 
  -- hasta el deposito.
  AND NOT ( aux.MovClave = 'CXC.C' AND CtaDinero.Tipo = 'Caja')
  GROUP BY 
    aux.Aplica,
    aux.AplicaID,
    aux.Moneda
  HAVING  
    ROUND(
      SUM(CASE 
            WHEN aux.Ejercicio < @Ejercicio
              OR (    
                      aux.Ejercicio = @Ejercicio
                  AND aux.Periodo < @Periodo
                  ) THEN
                ( ISNULL(aux.Cargo,0) - ISNULL(aux.Abono,0) ) * aux.IVAFiscal 
            ELSE 
              0
          END)
    , 4, 1) <>  0
  OR ROUND( SUM(  ( ISNULL(aux.Cargo,0) - ISNULL(aux.Abono,0) ) * aux.IVAFiscal  ), 4, 1)  <> 0

  UNION

  SELECT 
    aux.Mov,
    aux.MovID,
    aux.Moneda,
    SaldoInicial = SUM(CASE 
                          WHEN aux.Ejercicio < @Ejercicio
                            OR (    
                                    aux.Ejercicio = @Ejercicio
                                ANd aux.Periodo < @Periodo
                                ) THEN 
                              ISNULL(aux.Neto,0) 
                          ELSE
                            0
                        END),
    SaldoFinal = SUM( ISNULL(aux.Neto,0))
  FROM 
    #CUP_AuxDepositosCortesCajaHist aux
  GROUP BY 
    aux.Mov,
    aux.MovID,
    aux.Moneda

  -- Regresa el saldo inicial y final en un formato lineal.
  SELECT 
    @Ejercicio,
    @Periodo,
    ImporteInicialDlls = SUM(ISNULL(calc.ImporteInicialDlls,0)),
    ImporteInicialConversionMN = SUM(ISNULL(calc.ImporteInicialConversionMN,0)),
    ImporteInicialMN = SUM(ISNULL(calc.ImporteInicialMN,0)),
    ImporteInicialTotalMN  =  SUM( ISNULL(calc.ImporteInicialConversionMN,0) + ISNULL(calc.ImporteInicialMN,0)),
    ImporteFinalDlls = SUM(ISNULL(calc.ImporteFinalDlls,0)),
    ImporteFinalConversionMN = SUM(ISNULL(calc.ImporteFinalConversionMN,0)),
    ImporteFinalMN = SUM(ISNULL(calc.ImporteFinalMN,0)),
    ImporteFinalTotalMN  =  SUM( ISNULL(calc.ImporteFinalConversionMN,0) + ISNULL(calc.ImporteFinalMN,0))                          
  FROM 
    @AntSaldosCxCorte aux
  LEFT JOIN MovTipo t ON t.Modulo = 'CXP'
                      AND t.Mov = aux.Mov
  LEFT JOIN Cxc doc ON doc.Mov = aux.Mov
                   AND doc.MovId = aux.MovID
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
  -- Calculados
  CROSS APPLY (
                SELECT
                  ImporteInicialDlls = CASE aux.Moneda
                                          WHEN 'Dlls' THEN 
                                            ISNULL(aux.SaldoInicial,0)
                                          ELSE 
                                            0
                                        END,
                  ImporteInicialConversionMN = CASE aux.Moneda
                                          WHEN 'Dlls' THEN 
                                            ISNULL(aux.SaldoInicial,0) * ISNULL(movEnOrigen.TipoCambio,doc.ClienteTipoCambio)
                                          ELSE 
                                            0
                                        END,  
                  ImporteInicialMN = CASE aux.Moneda
                                        WHEN 'Pesos' THEN 
                                          ISNULL(aux.SaldoInicial,0)
                                        ELSE 
                                          0
                                      END,
                  ImporteFinalDlls = CASE aux.Moneda
                                          WHEN 'Dlls' THEN 
                                            ISNULL(aux.SaldoFinal,0)
                                          ELSE 
                                            0
                                        END,
                  ImporteFinalConversionMN = CASE aux.Moneda
                                                WHEN 'Dlls' THEN 
                                                  ISNULL(aux.SaldoFinal,0) * ISNULL(movEnOrigen.TipoCambio,doc.ClienteTipoCambio)
                                                ELSE 
                                                  0
                                              END,  
                  ImporteFinalMN = CASE aux.Moneda
                                      WHEN 'Pesos' THEN 
                                        ISNULL(aux.SaldoFinal,0)
                                      ELSE 
                                        0
                                    END
              ) calc    
END