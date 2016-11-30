SET ANSI_NULLS, ANSI_WARNINGS ON;

GO

IF EXISTS (SELECT * 
		   FROM SYSOBJECTS 
		   WHERE ID = OBJECT_ID('dbo.CUP_SPQ_ConciliacionCont_SaldosEsperados_AuxCxc') AND 
				 TYPE = 'P')
BEGIN
  DROP PROCEDURE dbo.CUP_SPQ_ConciliacionCont_SaldosEsperados_AuxCxc 
END	

GO

 /*=============================================
   Created by:    Enrique Sierra Gtez
   Creation Date: 2016-11-30

   Description: Obtiene los Saldos Iniciales y Finales
   que se usaran para la conciliacion Contable de Clientes
 
   Example: EXEC CUP_SPQ_ConciliacionCont_SaldosEsperados_AuxCxc 2016, 10
 ============================================= */


CREATE PROCEDURE dbo.CUP_SPQ_ConciliacionCont_SaldosEsperados_AuxCxc
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
                            ISNULL(aux.Cargo,0) - ISNULL(aux.Abono,0) 
                          ELSE 
                            0
                        END),
    SaldoFinal = SUM(ISNULL(aux.Cargo,0) - ISNULL(aux.Abono,0))
  FROM
    CUP_v_AuxiliarCxc aux
  LEFT JOIN CUP_ConciliacionCont_Excepciones ex ON ex.TipoConciliacion = 3 -- Saldo Clientes.
                                                AND ex.TipoExcepcion = 1 
                                                AND ex.Valor = LTRIM(RTRIM(aux.Cuenta))
  WHERE
    aux.Rama <> 'REV'
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
              ISNULL(aux.Cargo,0) - ISNULL(aux.Abono,0) 
            ELSE 
              0
          END)
    , 4, 1) <>  0
  OR ROUND( SUM( ISNULL(aux.Cargo,0) - ISNULL(aux.Abono,0) ), 4, 1)  <> 0

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
  LEFT JOIN MovTipo t ON t.Modulo = 'CXC'
                      AND t.Mov = aux.Mov
  LEFT JOIN Cxc doc ON doc.Mov = aux.Mov
                    AND doc.MovId = aux.MovID
  -- Factor Reevaluacion Dlls
  CROSS APPLY(
                SELECT 
                  FactorApertura = CASE 
                                      WHEN t.Clave IN ('CXC.A','CXC.FA')
                                      AND @FechaInicio >= '2016-05-01' 
                                      AND 1 = 2 
                                      THEN 
                                          ISNULL(doc.TipoCambio,1)
                                      ELSE 
                                          ISNULL(@TC_Inicial,1)
                                    END,
                  FactorCierre =  CASE 
                                    WHEN t.Clave IN ('CXC.A','CXC.FA') 
                                    AND @FechaFin >= '2016-04-30' 
                                    AND 1 = 2 THEN 
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