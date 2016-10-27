SET ANSI_NULLS, ANSI_WARNINGS ON;

GO

IF EXISTS (SELECT * 
		   FROM SYSOBJECTS 
		   WHERE ID = OBJECT_ID('dbo.CUP_ConciliacionCont_SaldosEsperados') AND 
				 TYPE = 'P')
BEGIN
  DROP PROCEDURE dbo.CUP_ConciliacionCont_SaldosEsperados 
END	

GO

-- =============================================
-- Created by:    Enrique Sierra Gtez
-- Creation Date: 2016-10-27
--
-- Description: Obtiene los Saldos Iniciales y Finales
-- que se usaran para la conciliacion Cotable
-- 
-- Example: EXEC CUP_SPQ_ConciliacionCont_OrigenContGas 63527, 1, 2016, 9
-- =============================================


CREATE PROCEDURE dbo.CUP_ConciliacionCont_SaldosEsperados
  @Empleado   INT,
  @Tipo      INT,
  @Ejercicio INT,
  @Periodo   INT
AS BEGIN 

  DECLARE
    @FechaFin DATE,
    @FechaInicio DATE = CAST(CAST(@Ejercicio AS VARCHAR)
                                    + '-' 
                                    + CAST(@Periodo AS VARCHAR)
                                    + '-01' AS DATE)

  SET @FechaFin = DATEADD(DAY,-1,DATEADD(MONTH,1,@FechaInicio))

  SELECT TOP 1
    @TipoCambio = TipoCambio 
  FROM
    MonHist
  WHERE 
    Fecha <= @FechaInicio
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
  VALUES
    ( 1, 'Saldo Inicial', 0, 0, 0, 0, 0, 0),
    ( 5, 'Saldo Final', 0, 0, 0, 0, 0, 0)

  
  UPDATE 
  
  FROM 
    @SaldosEsperados se 
  JOIN 
-- Auxiliar
SELECT 
   aux.Moneda,
   SaldoInicial = SUM(CASE 
                       WHEN aux.Ejercicio < @Ejercicio 
                          OR ( 
                                aux.Ejercicio = @Ejercicio
                             AND aux.Periodo < @Periodo
                             ) THEN
                         ISNULL(aux.Cargo,0) - ISNULL(aux.Abono,0) 
                       ELSE 
                         0
                     END),
    SaldoInicialMN =  SUM(CASE 
                         WHEN aux.Ejercicio < @Ejercicio 
                            OR ( 
                                  aux.Ejercicio = @Ejercicio
                               AND aux.Periodo < @Periodo
                               ) THEN
                           (ISNULL(aux.Cargo,0) - ISNULL(aux.Abono,0)) * tc.tipoCambio 
                         ELSE 
                           0
                       END),
    NeteMes =  SUM(CASE 
                      WHEN aux.Ejercicio = @Ejercicio 
                      AND aux.Periodo = @Periodo THEN
                        (ISNULL(aux.Cargo,0) - ISNULL(aux.Abono,0))
                      ELSE 
                        0
                    END),
    NetoMesMN =  SUM(CASE 
                      WHEN aux.Ejercicio = @Ejercicio 
                      AND aux.Periodo = @Periodo THEN
                        (ISNULL(aux.Cargo,0) - ISNULL(aux.Abono,0)) * tc.tipoCambio
                      ELSE 
                        0
                    END),
    SaldoFinal =  SUM(ISNULL(aux.Cargo,0) - ISNULL(aux.Abono,0)),
    SaldoFInalMN =   SUM(ISNULL(aux.Cargo,0) - ISNULL(aux.Abono,0)) * tc.tipoCambio
  
FROM 
  Auxiliar aux 
JOIN Rama r On r.Rama = aux.Rama
JOIN Prov p ON p.Proveedor = aux.Cuenta
JOIN Movtipo t ON t.Modulo = aux.Modulo 
             AND  t.Mov  = aux.Mov
LEFT JOIN MovTipo at ON at.Modulo = aux.Modulo
                    AnD at.Mov = aux.Aplica
CROSS APPLY(
             SELECT 
                tipoCambio =CASE aux.Moneda
                              WHEN 'Dlls' THEn
                                @TipoCambio
                              ELSE
                                1
                              END
           ) tc
WHERE
  r.Mayor = 'CXP'
AND ( 
      (   
           aux.Ejercicio = @Ejercicio  
       AND aux.Periodo <= @Periodo
      )
    OR aux.Ejercicio < @Ejercicio
    )
  --AND aux.Ejercicio = @Ejercicio
  --AND aux.Periodo = @Periodo
AND aux.Modulo = 'CXP'
AND aux.Cuenta <> 'SHCP'
AND ISNULL(at.Clave,'') NOT IN ('CXP.SCH','CXP.SD')
AND aux.Modulo = 'CXP'
GROUP BY 
  aux.Moneda,
  tc.tipoCambio
   	     
-- Polizas 
SELECT 
  SaldoInicial =  SUM(CASE 
                        WHEN CAST(d.FechaContable AS DATE) < @FechaInicio THEN 
                          (ISNULL(d.Debe,0) - ISNULL(d.Haber,0)) * f.Factor
                        ELSE
                          0
                      END),
  NetoMesMovs = SUM(CASE 
                      WHEN CAST(d.FechaContable AS DATE) >= @FechaInicio
                       AND f.PolizaManual = 0  THEN 
                        (ISNULL(d.Debe,0) - ISNULL(d.Haber,0)) * f.Factor
                      ELSE
                        0
                    END),
  NetoMesManual = SUM(CASE 
                        WHEN CAST(d.FechaContable AS DATE) >= @FechaInicio
                        AND f.PolizaManual = 1 THEN 
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


END