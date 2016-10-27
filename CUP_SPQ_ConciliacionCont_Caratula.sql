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
-- Creation Date: 2016-10-37
--
-- Description: Procesa la informacion
-- de la conciliacion contable en una tabla
-- que pueda ser interpretada como su caratula principal
-- 
-- Basicamente debe regresar algo  como lo siguiente: 
--
-- _______Concepto__________| _Dlls_| _ConversionMN_|_Pesos_|_TotalMN_|_Contabilidad_|_Variacion_
-- Saldo Inicial            |
-- Movs                     |
-- Saldo Final Calculado    |
-- Saldo Final              |
-- Variacion                |
--
-- Example: EXEC CUP_SPQ_ConciliacionCont_Caratula 63527, 1 , 2016, 9
-- =============================================


CREATE PROCEDURE dbo.CUP_SPQ_ConciliacionCont_Caratula
  @Empleado   INT,
  @Tipo       INT,
  @Ejercicio  INT,
  @Periodo    INT
AS BEGIN 
  
  DECLARE @Caratula TABLE
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

  ---- Saldo Iniciales
  --INSERT INTO @Caratula
  --(
  --  Orden,
  --  Concepto,
  --  ImporteDlls,
  --  ImporteConversionMN,
  --  ImporteMN,
  --  TotalMN,
  --  Contabilidad,
  --  Variacion
  --)
  --EXEC CUP_ConciliacionCont_SaldosEsperados @Tipo,  @Ejercicio, @Periodo


  -- Movimientos Auxiliar 
  ;WITH AllMovs AS 
  (
    SELECT DISTINCT 
      Mov 
    FROM 
      CUP_ConciliacionCont_AuxCx
    WHERE 
      Empleado = @Empleado
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
    ImporteDlls = 0 ,
    ImporteConversionMN = 0,
    ImporteMN = 0,
    TotalMN = 0,
    Contabilidad = 0,
    Variacion  = 0
  FROM 
    DistinctMovs dm
  

  -- Saldo Final Calculado


  -- Saldo Final Esperado
  

  -- Vaiacion

  SELECT 
    *
  FROM 
    @Caratula
  ORDER BY
    Orden,
    Concepto
END
