-- Considerar Anticip -GL327
-- Su ultimo tc efectivo de reevaluacion fue el 17.3993,
-- es un caso especial

SET ANSI_NULLS, ANSI_WARNINGS ON;

GO

IF EXISTS (SELECT * 
		   FROM SYSOBJECTS 
		   WHERE ID = OBJECT_ID('dbo.CUP_SPQ_ConciliacionCont_SaldosEsperados') AND 
				 TYPE = 'P')
BEGIN
  DROP PROCEDURE dbo.CUP_SPQ_ConciliacionCont_SaldosEsperados 
END	

GO

-- =============================================
-- Created by:    Enrique Sierra Gtez
-- Creation Date: 2016-10-27
--
-- Description: Obtiene los Saldos Iniciales y Finales
-- que se usaran para la conciliacion Cotable
-- 
-- Example: EXEC CUP_SPQ_ConciliacionCont_SaldosEsperados 63527, 1, 2016, 9
-- =============================================


CREATE PROCEDURE dbo.CUP_SPQ_ConciliacionCont_SaldosEsperados
  @Empleado   INT,
  @Tipo      INT,
  @Ejercicio INT,
  @Periodo   INT
AS BEGIN 

  SET NOCOUNT ON;

  DECLARE
    @TC_Inicial FLOAT,
    @TC_Final FLOAT,
    @FechaFin DATE,
    @FechaInicio DATE = CAST(CAST(@Ejercicio AS VARCHAR)
                                    + '-' 
                                    + CAST(@Periodo AS VARCHAR)
                                    + '-01' AS DATE)

  SET @FechaFin = DATEADD(DAY,-1,DATEADD(MONTH,1,@FechaInicio))

  SELECT TOP 1
    @TC_Inicial = TipoCambio 
  FROM
    MonHist
  WHERE 
    CAST(Fecha AS DATE) < @FechaInicio
  AND Moneda = 'Dlls'
  ORDER BY
    ID DESC

  SELECT TOP 1
    @TC_Final = TipoCambio 
  FROM
    MonHist
  WHERE 
    CAST(Fecha As DATE) <= @FechaFin
  AND Moneda = 'Dlls'
  ORDER BY
    ID DESC
  
  DECLARE @SaldosEsperados TABLE
  ( 
    Orden INT NOT NULL,
    Concepto VARCHAR(50) NOT NULL,
    ImporteDlls DECIMAL(18,4) NOT NULL,
    ImporteConversionMN DECIMAL(18,4) NOT NULL,
    ImporteMN   DECIMAL(18,4) NOT NULL,
    TotalMN DECIMAL(18,4) NOT NULL,
    Contabilidad DECIMAL(18,4) NOT NULL,
    Variacion DECIMAL(18,4) NOT NULL,
    PRIMARY KEY ( 
                  Orden,
                  Concepto
                )
  )
  
  DECLARE  @AntSaldosCxCorte TABLE
  (
    Mov CHAR(20) NOT NULL,
    MovID VARCHAR(20) NOT NULL,
    Moneda CHAR(10) NOT NULL,
    SaldoInicial DECIMAL(18,4) NOT NULL,
    SaldoFinal DECIMAL(18,4) NOT NULL
    PRIMARY KEY ( 
                    Mov,
                    MovID
                )
  )

  -- 1 ) Obtenemos AntigŁedad Corte Cx
  IF @Tipo = 1 
  BEGIN
     
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
                              WHEN CAST(aux.Fecha AS DATE) < @FechaInicio THEN
                                ISNULL(aux.Cargo,0) - ISNULL(aux.Abono,0) 
                              ELSE 
                                0
                            END),
        SaldoFinal = SUM(ISNULL(aux.Cargo,0) - ISNULL(aux.Abono,0))
      FROM 
        Auxiliar aux 
      JOIN Rama r On r.Rama = aux.Rama
      JOIN Prov p ON p.Proveedor = aux.Cuenta
      JOIN Movtipo t ON t.Modulo = aux.Modulo 
                   AND  t.Mov  = aux.Mov
      LEFT JOIN MovTipo at ON at.Modulo = aux.Modulo
                          AnD at.Mov = aux.Aplica
      WHERE
        r.Mayor = 'CXP'
      AND CAST(aux.Fecha AS DATE) <= @FechaFin
      AND aux.Modulo = 'CXP'
      AND aux.Cuenta <> 'SHCP'
      AND ISNULL(at.Clave,'') NOT IN ('CXP.SCH','CXP.SD')
      AND aux.Modulo = 'CXP'
      GROUP BY 
        aux.Aplica,
        aux.AplicaID,
        aux.Moneda
      HAVING  
        ROUND(
          SUM(CASE 
                WHEN CAST(aux.Fecha AS DATE) < @FechaInicio THEN
                    ISNULL(aux.Cargo,0) - ISNULL(aux.Abono,0) 
                ELSE 
                  0
              END)
        , 4, 1) <>  0
      OR ROUND( SUM( ISNULL(aux.Cargo,0) - ISNULL(aux.Abono,0) ), 4, 1)  <> 0

      -- Vacia los saldos AuxCx en un Consolidado.
      DECLARE @SaldosCx TABLE
      (
        Ejercicio INT NOT NULL, 
        Periodo INT NOT NULL,
        ImporteInicialDlls DECIMAL(18,4) NOT NULL,
        ImporteInicialConversionMN DECIMAL(18,4) NOT NULL,
        ImporteInicialMN DECIMAL(18,4) NOT NULL,
        ImporteInicialTotalMN DECIMAL(18,4) NOT NULL,
        ImporteFinalDlls DECIMAL(18,4) NOT NULL,
        ImporteFinalConversionMN DECIMAL(18,4) NOT NULL,
        ImporteFinalMN DECIMAL(18,4) NOT NULL,
        ImporteFinalTotalMN DECIMAL(18,4) NOT NULL
        PRIMARY KEY (
                      Ejercicio,
                      Periodo
                    )
      )

      INSERT INTO @SaldosCx
      (
        Ejercicio,
        Periodo,
        ImporteInicialDlls,
        ImporteInicialConversionMN,
        ImporteInicialMN,
        ImporteInicialTotalMN,
        ImporteFinalDlls,
        ImporteFinalConversionMN,
        ImporteFinalMN,
        ImporteFinalTotalMN
      )
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
      -- Factor Reevaluacion Dlls
      CROSS APPLY(
                   SELECT 
                      FactorApertura = CASE 
                                          WHEN t.Clave IN ('CXP.A') 
                                          AND @FechaInicio >= '2016-05-01' 
                                          THEN 
                                             ISNULL(doc.TipoCambio,1)
                                          ELSE 
                                             ISNULL(@TC_Inicial,1)
                                       END,
                      FactorCierre =  CASE 
                                        WHEN t.Clave IN ('CXP.A') 
                                        AND @FechaFin >= '2016-04-30' THEN 
                                           ISNULL(doc.TipoCambio,1)
                                        ELSE 
                                           ISNULL(@TC_Final,1)
                                      END
                  ) rev
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
                                                  ISNULL(aux.SaldoInicial,0) * rev.FactorApertura
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
                                                        ISNULL(aux.SaldoFinal,0) * rev.FactorCierre
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
 
  -- 2) Obtenemos los saldos Iniciales  y Finales de Cont.
  DECLARE @AuxCont TABLE
  (
    Ejercicio INT NOT NULL,
    Periodo INT NOT NULL,
    SaldoInicial DECIMAL(18,4) NOT NULL,
    SaldoFinal   DECIMAL(18,4) NOT NULL
    PRIMARY KEY (
                  Ejercicio,
                  Periodo
                )
  )
  
  INSERT INTO @AuxCont
  (
    Ejercicio,
    Periodo,
    SaldoInicial,
    SaldoFinal
  )
  SELECT 
    @Ejercicio,
    @Periodo,
    SaldoInicial =  SUM(CASE 
                          WHEN CAST(d.FechaContable AS DATE) < @FechaInicio THEN 
                            (ISNULL(d.Debe,0) - ISNULL(d.Haber,0)) * f.Factor
                          ELSE
                            0
                        END),
    SaldoFinal =  SUM((ISNULL(d.Debe,0) - ISNULL(d.Haber,0)) * f.Factor)
  FROM 
    CUP_ConciliacionCont_Tipo_CuentasContables cL
  JOIN Cta ON Cta.Cuenta = cl.Cuenta
  JOIN ContD d ON cl.Cuenta = d.Cuenta
  JOIN Cont c ON d.ID = c.ID 
  OUTER APPLY( SELECT 
                Factor = CASE ISNULL(Cta.EsAcreedora,0)
                            WHEN 1 THEN 
                                -1
                            ELSE 
                                1
                          END,
                PolizaManual = CASE 
                                  WHEN ISNULL(c.OrigenTipo,'') = '' THEN
                                    1
                                  ELSE 
                                    0
                                END
            ) f
  WHERE
    cl.Tipo = @Tipo   
  AND c.Estatus = 'CONCLUIDO'
  AND CAST(d.FechaContable AS DATE) <= @FechaFin

  -- 3 ) Integra los Saldos de Cx y Cont en el formato
  -- adecuado para su retorno.
  INSERT INTO @SaldosEsperados
  (
    Orden,
    Concepto,
    ImporteDlls,
    ImporteConversionMN,
    ImporteMN,
    TotalMN,
    Contabilidad,
    Variacion
  )
  SELECT 
    Orden = 1,
    Concepto = 'Saldo Inicial Intelisis',
    ImporteDlls = ISNULL(cx.ImporteInicialDlls,0),
    ImporteConversionMN = ISNULL(cx.ImporteInicialConversionMN,0),
    ImporteMN = ISNULL(cx.ImporteInicialMN,0),
    TotalMN = ISNULL(cx.ImporteInicialTotalMN,0),
    Contabilidad = ISNULL(cont.SaldoInicial,0),
    Variacion = ISNULL(cx.ImporteInicialTotalMN,0) - ISNULL(cont.SaldoInicial,0)
  FROM 
    @SaldosCx cx
  FULL OUTER JOIN @AuxCont cont ON cont.Ejercicio = cx.Ejercicio
                               AND cont.Periodo = cx.Periodo 
  UNION
  SELECT 
    Orden = 4,
    Concepto = 'Saldo Final Intelisis',
    ImporteDlls = ISNULL(cx.ImporteFinalDlls,0),
    ImporteConversionMN = ISNULL(cx.ImporteFinalConversionMN,0),
    ImporteMN = ISNULL(cx.ImporteFinalMN,0),
    TotalMN = ISNULL(cx.ImporteFinalTotalMN,0),
    Contabilidad = ISNULL(cont.SaldoFinal,0),
    Variacion = ISNULL(cx.ImporteFinalTotalMN,0) - ISNULL(cont.SaldoFinal,0)
  FROM 
    @SaldosCx cx
  FULL OUTER JOIN @AuxCont cont ON cont.Ejercicio = cx.Ejercicio
                               AND cont.Periodo = cx.Periodo 

  
  -- 4) Regresa la informacion en el formato requerido.
  SELECT 
    Orden,
    Concepto,
    ImporteDlls,
    ImporteConversionMN,
    ImporteMN,
    TotalMN,
    Contabilidad,
    Variacion
  FROM 
    @SaldosEsperados


END