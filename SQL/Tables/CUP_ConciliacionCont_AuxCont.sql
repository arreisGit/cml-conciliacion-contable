SET ANSI_NULLS, ANSI_WARNINGS ON;

IF OBJECT_ID('dbo.CUP_ConciliacionCont_AuxCont', 'U') IS NOT NULL 
  DROP TABLE dbo.CUP_ConciliacionCont_AuxCont; 

GO

-- =============================================
-- Created by:    Enrique Sierra Gtez
-- Creation Date: 2016-10-26
--
-- Description: Tabla encargada de contener
-- los auxiliares contables para las conciliaciones 
-- auxiliar - cont.
-- =============================================

CREATE TABLE dbo.CUP_ConciliacionCont_AuxCont
(
  Empleado INT NOT NULL,
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
                Empleado,
                ID,
                Cuenta
              )
) 


CREATE NONCLUSTERED INDEX [IX_CUP_ConciliacionCont_AuxCont_Empleado_AuxiliarModulo_AuxiliarMov]
ON [dbo].[CUP_ConciliacionCont_AuxCont] ( Empleado, AuxiliarModulo, AuxiliarMov )
INCLUDE ( 
           Debe,
           Haber,
           Neto,
           OrigenModulo,
           OrigenModuloID,
           OrigenMov,
           OrigenMovId
        )
