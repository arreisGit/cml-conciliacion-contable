-- Considerar Anticip -GL327
-- Su ultimo tc efectivo de reevaluacion fue el 17.3993,
-- es un caso especial

SET ANSI_NULLS, ANSI_WARNINGS ON;

GO

IF EXISTS (SELECT * 
		   FROM SYSOBJECTS 
		   WHERE ID = OBJECT_ID('dbo.CUP_SPQ_ConciliacionCont_SaldosEsperados_IVAPorAcreditar') AND 
				 TYPE = 'P')
BEGIN
  DROP PROCEDURE dbo.CUP_SPQ_ConciliacionCont_SaldosEsperados_IVAPorAcreditar 
END	

GO

 /*=============================================
   Created by:    Enrique Sierra Gtez
   Creation Date: 2016-11-24

   Description: Obtiene los Saldos Iniciales y Finales
   que se usaran para la conciliacion Cotable del IVA Por Acreditar
 
   Example: EXEC CUP_SPQ_ConciliacionCont_SaldosEsperados_IVAPorAcreditar 2016, 10
 ============================================= */


CREATE PROCEDURE dbo.CUP_SPQ_ConciliacionCont_SaldosEsperados_IVAPorAcreditar
  @Ejercicio INT,
  @Periodo   INT
AS BEGIN 

  SET NOCOUNT ON;

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
    Mov = Aplica,
    MovId  = ISNULL(AplicaID,''),
    Moneda,
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
    CUP_v_AuxiliarCxp aux
  -- Excepciones Cuentas
  LEFT JOIN CUP_ConciliacionCont_Excepciones eX ON ex.TipoConciliacion = 1 -- Saldo Proveedores
                                                AND ex.TipoExcepcion = 1
                                                AND ex.Valor = aux.cuenta
  WHERE 
    aux.Rama <> 'REV'
  AND aux.MovClave NOT IN ('CXP.ANC','CXP.RE')
  AND (
          aux.Ejercicio < @Ejercicio
      OR (
              aux.Ejercicio = @Ejercicio 
          AND aux.Periodo <= @Periodo  
          )
      )
  AND eX.Id IS NULL
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
  LEFT JOIN Cxp doc ON doc.Mov = aux.Mov
                    AND doc.MovId = aux.MovID
  -- MovFlujo Origen
  OUTER APPLY(
                SELECT TOP 1
                  mf.OModulo,
                  mf.OID
                FROM 
                  MovFlujo mf 
                WHERE 
                  mf.DModulo = 'CXP'
                AND mf.DID = doc.ID
                AND mf.OModulo = doc.OrigenTipo
                AND mf.OMov = doc.Origen
                AND mf.OMovID = doc.OrigenID
              ) mfOrigen
  -- Datos del doc en Modulo Origen
  OUTER APPLY ( SELECT TOP 1
                  coms.TipoCambio
                FROM 
                  Compra coms
                WHERE 
                 'COMS' =  mfOrigen.OModulo 
                AND coms.ID = mfOrigen.OID
                UNION
                SELECT TOP 1
                  gas.TipoCambio
                FROM 
                  Gasto gas
                WHERE 
                 'GAS' =  mfOrigen.OModulo 
                AND gas.ID = mfOrigen.OID
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
                                            ISNULL(aux.SaldoInicial,0) * ISNULL(movEnOrigen.TipoCambio,doc.ProveedorTipoCambio)
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
                                                  ISNULL(aux.SaldoFinal,0) * ISNULL(movEnOrigen.TipoCambio,doc.ProveedorTipoCambio)
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