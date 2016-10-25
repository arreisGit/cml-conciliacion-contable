SET ANSI_NULLS, ANSI_WARNINGS ON;

GO

IF EXISTS (SELECT * 
		   FROM SYSOBJECTS 
		   WHERE ID = OBJECT_ID('dbo.CUP_spp_CxAuxiliarModuloVsCont') AND 
				 TYPE = 'P')
BEGIN
  DROP PROCEDURE dbo.CUP_spp_CxAuxiliarModuloVsCont 
END	


GO

-- =============================================
-- Created by:    Enrique Sierra Gtez
-- Creation Date: 2016-10-20
--
-- Description: Cruza los auxiliares de
-- Modulo y Contabilidad, sobre un Ejercicio/Periodo
-- y con la suficiente informacion para facilitar  
-- la conciliacion.
-- 
-- Example: EXEC CUP_spp_CxAuxiliarModuloVsCont 'CXP', 2016, 9
--
-- =============================================


CREATE PROCEDURE dbo.CUP_spp_CxAuxiliarModuloVsCont
  @Modulo CHAR(5),
  @Ejercicio INT,
  @Periodo INT
AS BEGIN 
    
    -- 1) Obtenemos el Auxiliar de Modulo
    IF OBJECT_ID('tempdb..#CxAuxiliarModulo') IS NOT NULL
      DROP TABLE #CxAuxiliarModulo

    CREATE TABLE #CxAuxiliarModulo
    (
      Modulo CHAR(5) NOT NULL ,
      ID INT NOT NULL,
      Mov CHAR(20) NOT NULL,
      MovId VARCHAR(20) NULL,
      Sucursal INT NOT NULL,
      FechaEmision DATE  NOT NULL,
      Proveedor CHAR(10) NOT NULL,
      ProvNombre VARCHAR(100) NULL,
      ProvCuenta VARCHAR(20) NULL,
      Estatus VARCHAR(15) NOT NULL,
      EsCancelacion BIT NOT NULL,
      Moneda CHAR(10) NOT NULL,
      TipoCambio FLOAT NOT NULL,
      ImporteTotal DECIMAL(18,4) NOT  NULL,
      FluctuacionCambiariaMN DECIMAL(18,4) NOT NULL,
      ImporteTotalMN DECIMAL(18,4) NOT NULL,
      AuxiliarModulo CHAR(5) NOT NULL,
      AuxiliarMov CHAR(20) NOT NULL,
      PolizaID INT NULL
    )

    
  CREATE NONCLUSTERED INDEX [IX_#CxAuxiliarModulo_PolizaID]
  ON [dbo].[#CxAuxiliarModulo] ( PolizaID )
  INCLUDE
  ( 
    AuxiliarModulo,
    AuxiliarMov,
    Modulo,
    ID,
    Sucursal,
    FechaEmision,
    Proveedor,
    ProvNombre,
    ProvCuenta, 
    Estatus,
    EsCancelacion,
    Moneda,
    TipoCambio,
    ImporteTotal,
    FluctuacionCambiariaMN,
    ImporteTotalMN
  )
          
  INSERT INTO #CxAuxiliarModulo
  EXEC CUP_spq_CxAuxiliarOrigenContableCxp @Ejercicio, @Periodo

  -- 2) Obtenemos el Auxiliar de Contabilidad
  IF OBJECT_ID('tempdb..##CxAuxiliarCont') IS NOT NULL
    DROP TABLE #CxAuxiliarCont

  CREATE TABLE #CxAuxiliarCont
  (
    ID INT NOT NULL,
    Cuenta     CHAR(20) NOT NULL,
    Descripcion VARCHAR(100) NULL ,
    CentroCostos VARCHAR(50) NULL,
    Debe DECIMAL(18,4) NOT NULL,
    Haber DECIMAL(18,4) NOT NULL,
    Neto DECIMAL(18,4) NOT NULL,
    Sucursal INT NULL,
    FechaContable DATE NOT NULL,
    Mov CHAR(20) NOT NULL,
    MovId VARCHAR(20) NULL,
    Referencia VARCHAR(50) NULL,
    OrigenModulo CHAR(5) NULL,
    OrigenModuloID INT NULL,
    OrigenMov CHAR(20) NULL,
    OrigenMovId VARCHAR(20) NULL,
    AuxiliarModulo CHAR(5) NULL,
    AuxiliarMov VARCHAR(20) NULL,
    PRIMARY KEY ( 
                  ID,
                  Cuenta
                )
  )

    
  CREATE NONCLUSTERED INDEX [IX_#CxAuxiliarCont_OrigenModulo_OrigenModuloID]
  ON [dbo].[#CxAuxiliarCont] ( OrigenModulo, OrigenModuloID )
  INCLUDE ( 
            ID,
            Cuenta,
            Debe,
            Haber,
            Neto,
            OrigenMov,
            OrigenMovID,
            AuxiliarModulo,
            AuxiliarMov
          )

  INSERT INTO #CxAuxiliarCont
  EXEC CUP_spq_CxAuxiliarCont @Modulo, @Ejercicio, @Periodo

  -- 3) Cruzamos los auxiliares de Modulo y Contabilidad entre si
  SELECT
    modulo.Modulo,
    modulo.ID,
    modulo.Mov,
    modulo.MovId,
    modulo.AuxiliarModulo,
    modulo.AuxiliarMov,    
    modulo.Sucursal,
    modulo.FechaEmision,
    modulo.Proveedor,
    modulo.ProvNombre,
    modulo.ProvCuenta,
    modulo.Estatus,
    modulo.EsCancelacion,
    modulo.PolizaID,
    modulo.Moneda,
    modulo.TipoCambio,
    modulo.ImporteTotal,
    modulo.FluctuacionCambiariaMN,    
    modulo.ImporteTotalMN,
    Diferencia = ISNULL(modulo.ImporteTotalMN,0)  - ISNULL(cont.Neto,0),
    ContNeto =  cont.Neto,
    ContDebe =  cont.Debe,
    ContHaber = cont.Haber,
    cont.Cuenta,
    cont.Descripcion,
    ContID =cont.Id,
    PolizaMov = cont.Mov,
    PolizaMovID =cont.Movid,
    cont.OrigenMov,
    cont.OrigenMovId,
    ContAuxMod = cont.AuxiliarModulo,
    ContAuxMov = cont.AuxiliarMov
  FROM 
    #CxAuxiliarModulo modulo
  FULL OUTER JOIN #CxAuxiliarCont cont ON modulo.PolizaID = cont.ID
  ORDER BY
    cont.AuxiliarModulo,
    cont.AuxiliarMov  
END