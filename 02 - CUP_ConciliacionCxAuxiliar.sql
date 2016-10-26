SET ANSI_NULLS, ANSI_WARNINGS ON;

IF OBJECT_ID('dbo.CUP_ConciliacionCxAuxiliar', 'U') IS NOT NULL 
  DROP TABLE dbo.CUP_ConciliacionCxAuxiliar; 

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

CREATE TABLE dbo.CUP_ConciliacionCxAuxiliar
(
  Empleado INT NOT NULL,
  AuxID INT NULL,
  Fecha DATE NOT NULL,
  Sucursal INT NOT NULL,
  Cuenta CHAR(10) NOT NULL,
  Nombre VARCHAR(100) NULL, 
  Modulo CHAR(5) NOT NULL,
  ModuloID INT NOT NULL,
  Mov  CHAR(20) NOT NULL,
  MovID VARCHAR(20)  NULL,
  Moneda  CHAR(10) NOT NULL,
  TipoCambio FLOAT NOT NULL,
  Cargo DECIMAL(18,4) NOT NULL,
  Abono DECIMAL(18,4) NOT NULL, 
  CargoMN DECIMAL(18,4) NOT NULL,
  AbonoMN DECIMAL(18,4) NOT NULL,
  FluctuacionMN DECIMAL(18,4) NOT NULL,
  Aplica CHAR(20) NOT NULL,
  AplicaID VARCHAR(20) NULL,
  EsCancelacion BIT NOT NULL,  
  OrigenModulo CHAR(5) NULL,
  OrigenModuloID INT NULL,
  OrigenMov CHAR(20) NULL,
  OrigenMovID VARCHAR(20) NULL
) 

CREATE NONCLUSTERED INDEX [IX_CUP_ConciliacionCxAuxiliar_Empleado]
ON [dbo].[CUP_ConciliacionCxAuxiliar] ( Empleado )
INCLUDE ( 
          AuxId,
          Fecha,
          Sucursal,
          Cuenta,
          Nombre,
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
          OrigenModuloID,
          OrigenMov,
          OrigenMovID
        )


CREATE NONCLUSTERED INDEX [IX_CUP_ConciliacionCxAuxiliar_Modulo_Mov]
ON [dbo].[CUP_ConciliacionCxAuxiliar] ( Modulo, Mov )
INCLUDE ( 
          Fecha,
          Sucursal,
          Cuenta,
          Nombre,
          MovID,
          Moneda,
          Cargo,
          Abono,
          CargoMN,
          AbonoMN,
          FluctuacionMN,
          OrigenModulo,
          OrigenModuloID,
          OrigenMov,
          OrigenMovID
        )