SET ANSI_NULLS, ANSI_WARNINGS ON;

IF OBJECT_ID('dbo.CUP_ConciliacionCont_AuxCx', 'U') IS NOT NULL 
  DROP TABLE dbo.CUP_ConciliacionCont_AuxCx; 

GO

-- =============================================
-- Created by:    Enrique Sierra Gtez
-- Creation Date: 2016-10-26
--
-- Description: Tabla encargada de contener
-- los auxiliares de Cxc/Cxp para un ejercicio
-- y periodo especifico. Con el fin de poder utilizr
-- la informacion en la conciliacion contable.
--
-- =============================================

CREATE TABLE dbo.CUP_ConciliacionCont_AuxCx
(
  Empleado INT NOT NULL,
  Rama     CHAR(5) NOT NULL,
  AuxID    INT NULL,
  Ejercicio INT NOT NULL,
  Periodo  INT NOT NULL,
  Fecha    DATE NOT NULL,
  Sucursal INT NOT NULL,
  Cuenta   CHAR(10) NOT NULL,
  Modulo  CHAR(5) NOT NULL,
  ModuloID INT NOT NULL,
  Mov  CHAR(20) NOT NULL,
  MovID VARCHAR(20)  NULL,
  Moneda  CHAR(10) NOT NULL,
  TipoCambio FLOAT NOT NULL,
  Cargo DECIMAL(18,4) NOT NULL,
  Abono DECIMAL(18,4) NOT NULL, 
  Neto DECIMAL(18,4) NOT NULL,
  CargoMN DECIMAL(18,4) NOT NULL,
  AbonoMN DECIMAL(18,4) NOT NULL,
  NetoMN DECIMAL(18,4) NOT NULL,
  FluctuacionMN DECIMAL(18,4) NOT NULL,
  TotalMN DECIMAL(18,4) NOT NULL,
  Aplica            CHAR(20) NOT NULL,
  AplicaID          VARCHAR(20) NULL,
  EsCancelacion     BIT NOT NULL,  
  OrigenModulo      VARCHAR(10) NULL,
  OrigenMov         CHAR(20) NULL,
  OrigenMovID       VARCHAR(20) NULL
) 

CREATE NONCLUSTERED INDEX [IX_CUP_ConciliacionCont_AuxCx_Empleado]
ON [dbo].[CUP_ConciliacionCont_AuxCx] ( Empleado )
INCLUDE ( 
          AuxId,
          Fecha,
          Sucursal,
          Cuenta,
          Modulo,
          ModuloId,
          Mov,
          MovId,
          Moneda,
          Cargo,
          Abono,
          CargoMN,
          AbonoMN,
          FluctuacionMN,
          OrigenModulo,
          OrigenMov,
          OrigenMovID
        )

CREATE NONCLUSTERED INDEX [IX_CUP_ConciliacionCont_AuxCx_Modulo_Mov]
ON [dbo].[CUP_ConciliacionCont_AuxCx] ( Modulo, Mov )
INCLUDE ( 
          Fecha,
          Sucursal,
          Cuenta,
          MovID,
          Moneda,
          Cargo,
          Abono,
          CargoMN,
          AbonoMN,
          FluctuacionMN,
          OrigenModulo,
          OrigenMov,
          OrigenMovID
        )