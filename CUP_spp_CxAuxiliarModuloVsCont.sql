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
-- Creation Date: 2016-10-13
-- Last Modified: 2016-10-13 
--
-- Description: Cruza los auxiliares de
-- Modulo y Contabilidad, sobre un Ejercicio/Periodo
-- y con la suficiente informacion para facilitar  
-- la conciliacion.
-- 
-- Example: EXEC CUP_spp_CxAuxiliarModuloVsCont 'CXP', 2016, 9
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
      AuxID INT NULL,
      Fecha DATE NOT NULL,
      Sucursal INT NOT NULL,
      Proveedor CHAR(10) NOT NULL,
      ProvNombre VARCHAR(100) NULL,
      ProvCta VARCHAR(20) NULL,
      Modulo CHAR(5) NOT NULL,
      ModuloID INT NOT NULL,
      Mov CHAR(20) NOT NULL,
      MovID VARCHAR(20) NOT NULL,
      Moneda CHAR(10) NOT NULL,
      TipoCambio FLOAT NOT NULL,
      Cargo DECIMAL(18,4) NOT NULL,
      Abono DECIMAL(18,4) NOT NULL,
      Neto DECIMAL(18,4) NOT NULL,
      CargoMN DECIMAL(18,4) NOT NULL,
      AbonoMN DECIMAL(18,4) NOT NULL,
      NetoMN DECIMAL(18,4) NOT NULL,
      FluctuacionMN DECIMAL(18,4) NOT NULL,
      ReevaluacionMN DECIMAL(18,4) NOT NULL,
      TotalMN DECIMAL(18,4) NOT NULL,
      Aplica CHAR(20) NOT NULL,
      AplicaID VARCHAR(20) NULL,
      EsCancelacion BIT NOT NULL,
      OrigenModulo CHAR(5) NULL,
      OrigenModuloID INT NULL,
      OrigenMov   CHAR(20) NULL,
      OrigenMovID VARCHAR(20) NULL,
      OrigenPoliza CHAR(5) NULL,
      PolizaID INT NULL,
      PolizaMov CHAR(20) NULL,
      PolizaMovId VARCHAR(20) NULL
    )

    
  CREATE NONCLUSTERED INDEX [IX_#CxAuxiliarModulo_PolizaID]
  ON [dbo].[#CxAuxiliarModulo] ( PolizaID )
  INCLUDE ( 
            AuxID,
            Modulo, 
            ModuloID,
            Mov,
            Movid,
            Proveedor,
            Aplica,
            AplicaID,
            EsCancelacion,
            Moneda,
            TipoCambio,
            Neto,
            NetoMN,
            FluctuacionMN,
            ReevaluacionMN,
            TotalMN
          )

  INSERT INTO #CxAuxiliarModulo
  EXEC CUP_spq_CxAuxiliarModulo @Modulo, @Ejercicio, @Periodo

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
            OrigenMovID
          )

  INSERT INTO #CxAuxiliarCont
  EXEC CUP_spq_CxAuxiliarCont @Modulo, @Ejercicio, @Periodo

  -- 3) Cruzamos los auxiliares de Modulo y Contabilidad entre si
  ;WITH modulo AS ( 
  SELECT
    AuxID,
    EsCancelacion,
    Modulo, 
    ModuloID,
    Mov,
    Movid,
    Proveedor,
    Moneda,
    Neto = SUM(ISNULL(Neto,0)),
    NetoMN = SUM(ISNULL(NetoMN,0)),
    Fluctuacionmn = SUM(ISNULL(FluctuacionMN,0)),
    ReevaluacionMN = SUM(ISNULL(ReevaluacionMN,0)),
    TotalMN = SUM(ISNULL(TotalMN,0)),
    PolizaID
  FROM
    #CxAuxiliarModulo
  GROUP BY
    AuxID,
    EsCancelacion,
    Modulo, 
    ModuloID,
    Mov,
    Movid,
    Proveedor,
    Moneda,
    PolizaID   
  )
  SELECT
    modulo.AuxID,
    modulo.EsCancelacion,
    modulo.Modulo, 
    modulo.ModuloID,
    modulo.Mov,
    modulo.Movid,
    modulo.Proveedor,
    modulo.Moneda,
    modulo.Neto,
    modulo.NetoMN,
    modulo.FluctuacionMN,
    modulo.ReevaluacionMN,
    modulo.TotalMN,
    modulo.PolizaID,
    cont.OrigenModulo,
    cont.Neto,
    cont.Debe,
    cont.Haber,
    cont.Id,
    cont.Cuenta,
    cont.Descripcion,
    cont.Mov,
    cont.Movid,
    cont.OrigenMov,
    cont.OrigenMovId
  FROM 
    modulo
  FULL OUTER JOIN #CxAuxiliarCont cont ON modulo.PolizaID = cont.ID
  ORDER BY  
    modulo.ModuloID,
    cont.ID,
    cont.Cuenta

END