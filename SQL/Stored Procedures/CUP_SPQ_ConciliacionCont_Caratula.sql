SET ANSI_NULLS, ANSI_WARNINGS ON;

GO

IF EXISTS (SELECT * 
		   FROM SYSOBJECTS 
		   WHERE ID = OBJECT_ID('dbo.CUP_SPQ_ConciliacionCont_Caratula') AND 
				 TYPE = 'P')
BEGIN
  DROP PROCEDURE dbo.CUP_SPQ_ConciliacionCont_Caratula
END	

GO

-- =============================================
-- Created by:    Enrique Sierra Gtez
-- Creation Date: 2016-10-27
--
-- Description: Procesa la informacion
-- de la conciliacion contable en una tabla
-- que pueda ser interpretada como su caratula principal
-- 
-- Basicamente debe regresar algo  como lo siguiente: 
--
-- _______Concepto__________| _ImporteDlls_| _ConversionMN_|_ImporteMn_|_TotalMN_|_Contabilidad_|_Variacion_
-- Saldo Inicial            |
-- Movs                     |
-- Saldo Final Calculado    |
-- Saldo Final              |
-- Variacion                |
--
-- Example: EXEC CUP_SPQ_ConciliacionCont_Caratula 63527, 3 , 2016, 10
-- =============================================


CREATE PROCEDURE dbo.CUP_SPQ_ConciliacionCont_Caratula
  @Empleado   INT, 
  @Tipo       INT,
  @Ejercicio  INT,
  @Periodo    INT
AS BEGIN 

  SET NOCOUNT ON;
  
  DECLARE @Caratula TABLE
  (
    Orden               INT NOT NULL,
    Concepto            VARCHAR(50) NOT NULL,
    ImporteDlls         DECIMAL(18,4) NOT NULL,
    ImporteConversionMN DECIMAL(18,4) NOT NULL,
    ImporteMN           DECIMAL(18,4) NOT NULL,
    TotalMN             DECIMAL(18,4) NOT NULL,
    Contabilidad        DECIMAL(18,4) NOT NULL,
    Variacion           DECIMAL(18,4) NULL,
    PRIMARY KEY ( 
                  Orden,
                  Concepto
                )
  )

  -- 1) Saldo Iniciales y Finales Esperados
  INSERT INTO @Caratula
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
  EXEC CUP_SPQ_ConciliacionCont_SaldosEsperados @Empleado, @Tipo, @Ejercicio, @Periodo


  -- Movimientos Auxiliar 
  DECLARE @ImportesAuxCx TABLE
  (
    Mov VARCHAR(20) NOT NULL,
    ImporteDlls DECIMAL(18,4) NOT NULL,
    ImporteConversionMN DECIMAL(18,4) NOT NULL,
    ImporteMN DECIMAL(18, 4) NOT NULL,
    TotalMN DECIMAL(18, 4) NOT NULL
    PRIMARY KEY (
                  Mov
                 )
  )

  INSERT INTO @ImportesAuxCx
  (
    Mov,
    ImporteDlls,
    ImporteConversionMN,
    ImporteMN,
    TotalMN
  )
  SELECT 
    Mov ,
    ImporteDlls = SUM( CASE aux.Moneda 
                          WHEN 'Dlls' THEN
                            ISNULL(aux.Neto,0)
                          ELSE 
                            0
                        END),
    ImporteConversionMN = SUM(CASE aux.Moneda 
                                WHEN 'Dlls' THEN
                                  ISNULL(aux.TotalMN,0)
                                ELSE 
                                    0
                              END),
    ImporteMN = SUM(CASE aux.Moneda 
                      WHEN 'Pesos' THEN
                        ISNULL(aux.TotalMN,0)
                      ELSE 
                        0
                    END),
    TotalMN = SUM(ISNULL(aux.TotalMN,0))
  FROM 
    CUP_ConciliacionCont_AuxCx aux
  WHERE 
    Empleado = @Empleado
  GROUP BY
    Mov
  ORDER BY  
    Mov ASC

 

  -- Movimientos Cont 
  DECLARE @ImportesAuxCont TABLE
  (
    AuxModulo CHAR(5) NOT NULL,
    AuxMov VARCHAR(20) NOT NULL,
    Neto DECIMAL(18,4) NOT NULL
    PRIMARY KEY (
                  AuxModulo,
                  AuxMov
                 )
  )

  INSERT INTO 
    @ImportesAuxCont
  (
    AuxModulo,
    AuxMov,
    Neto
  )
  SELECT 
    AuxModulo = ISNULL(AuxiliarModulo,''),
    AuxMov = ISNULL(AuxiliarMov,''),
    Neto = SUM(ISNULL(Neto,0))
  FROM 
    CUP_ConciliacionCont_AuxCont
  WHERE 
    Empleado = @Empleado
  GROUP BY 
    ISNULL(AuxiliarModulo,''),
    ISNULL(AuxiliarMov,'')


  ;WITH AllMovs AS 
  (
    SELECT DISTINCT
      Mov 
    FROM 
      @ImportesAuxCx
    UNION
    SELECT 
      Mov = AuxMov
    FROM 
      CUP_ConciliacionCont_Tipo_OrigenContable
    WHERE 
      Tipo = @Tipo
  ), DistinctMovs AS (
  SELECT DISTINCT
    Mov
  FROM 
    AllMovs am
 )
 INSERT INTO 
  @Caratula
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
    Orden =  2,
    dm.Mov,
    ImporteDlls = ISNULL(aux.ImporteDlls,0) ,
    ImporteConversionMN = ISNULL(aux.ImporteConversionMN,0),
    ImporteMN = ISNULL(aux.ImporteMN,0),
    TotalMN = ISNULL(aux.TotalMN,0),
    Contabilidad = ISNULL(cont.Neto,0),
    Variacion  = ISNULL(aux.TotalMN,0) - ISNULL(cont.Neto,0)
  FROM 
    DistinctMovs dm
  LEFT JOIN @ImportesAuxCx aux ON LTRIM(RTRIM(aux.Mov)) = LTRIM(RTRIM(dm.Mov))
  LEFT JOIN @ImportesAuxCont cont ON LTRIM(RTRIM(cont.AuxMov)) = LTRIM(RTRIM(dm.Mov))

    -- Total Mes 
   INSERT INTO 
    @Caratula
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
      Orden =  3,
      Concepto = 'Total Mes',
      ImporteDlls = SUM(ISNULL(ImporteDlls,0)),
      ImporteConversionMN = SUM(ISNULL(ImporteConversionMN,0)),
      ImporteMN = SUM(ISNULL(ImporteMN,0)),
      TotalMN = SUM(ISNULL(TotalMN,0)),
      Contabilidad = SUM(ISNULL(Contabilidad,0)),
      Variacion  = SUM(ISNULL(Variacion,0))
    FROM 
      @Caratula
    WHERE 
      Orden IN (2)

  -- Saldo Final Calculado 
   INSERT INTO 
    @Caratula
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
      Orden =  5,
      Concepto = 'Saldo Final Calculado',
      ImporteDlls = SUM(ISNULL(ImporteDlls,0)),
      ImporteConversionMN = SUM(ISNULL(ImporteConversionMN,0)),
      ImporteMN = SUM(ISNULL(ImporteMN,0)),
      TotalMN = SUM(ISNULL(TotalMN,0)),
      Contabilidad = SUM(ISNULL(Contabilidad,0)),
      Variacion  = SUM(ISNULL(Variacion,0))
    FROM 
      @Caratula
    WHERE 
      Orden IN (1,3) -- Saldos Iniciales + Total Mes
 
  -- Variacion  
   INSERT INTO 
    @Caratula
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
      Orden =  6,
      'Variacion',
      ImporteDlls = ISNULL(esperado.ImporteDlls,0) 
                  - ISNULL(calc.ImporteDlls,0),
      ImporteConversionMN = ISNULL(esperado.ImporteConversionMN,0) 
                  - ISNULL(calc.ImporteConversionMN,0),
      ImporteMN = ISNULL(esperado.ImporteMN,0) 
                  - ISNULL(calc.ImporteMN,0),
      TotalMN = ISNULL(esperado.TotalMN,0) 
                  - ISNULL(calc.TotalMN,0),
      Contabilidad = ISNULL(esperado.Contabilidad,0) 
                  - ISNULL(calc.Contabilidad,0),
      Variacion  = NULL
    FROM 
      @Caratula esperado
    LEFT JOIN @Caratula calc ON calc.Orden = 5
    WHERE 
      esperado.Orden = 4 

  
  -- Regresa La Caratula Final
  SELECT 
    Orden,
    Concepto,
    ImporteDlls= CAST(ImporteDlls AS FLOAT),
    ImporteConversionMN =  CAST(ImporteConversionMN AS FLOAT),
    ImporteMN = CAST(ImporteMN AS FLOAT),
    TotalMN = CAST(TotalMN AS FLOAT),
    Contabilidad = CAST(Contabilidad AS FLOAT),
    Variacion = CAST(Variacion AS FLOAT)
  FROM 
    @Caratula  
  ORDER BY
    Orden,
    Concepto

END
