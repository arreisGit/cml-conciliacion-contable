SET ANSI_NULLS, ANSI_WARNINGS ON;

IF OBJECT_ID('dbo.CUP_ConciliacionCont_AuxModulo', 'U') IS NOT NULL 
  DROP TABLE dbo.CUP_ConciliacionCont_AuxModulo; 

GO

/* =============================================
   Created by:    Enrique Sierra Gtez
   Creation Date: 2016-10-26

   Description: Tabla encargada de contener
   los auxiliares del modulo necesarios
   para poder realizar las conciliaciones contables
 ============================================= */

CREATE TABLE dbo.CUP_ConciliacionCont_AuxModulo
(
  Empleado INT NOT NULL,
  Modulo CHAR(5) NOT NULL ,
  ID INT NOT NULL,
  Mov CHAR(20) NOT NULL,
  MovId VARCHAR(20) NULL,
  Sucursal INT NOT NULL,
  FechaEmision DATE  NOT NULL,
  Cuenta CHAR(10) NOT NULL,
  Nombre VARCHAR(100) NULL,
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

CREATE NONCLUSTERED INDEX [IX_CUP_ConciliacionCont_AuxModulo_Empleado]
ON [dbo].[CUP_ConciliacionCont_AuxModulo] ( Empleado )
INCLUDE ( 
          Modulo,
          Id,
          Mov,
          MovID,
          Sucursal,
          FechaEmision,
          Cuenta,
          Nombre,
          Estatus,
          EsCancelacion,
          Moneda,
          TipoCambio,
          ImporteTotal,
          FluctuacionCambiariaMN,
          ImporteTotalMN,
          AuxiliarModulo,
          AuxiliarMov,
          PolizaID
        )


CREATE NONCLUSTERED INDEX [IX_CUP_ConciliacionCont_AuxModulo_Empleado_PolizaID]
ON [dbo].[CUP_ConciliacionCont_AuxModulo] ( Empleado, PolizaID )
INCLUDE ( 
          Modulo,
          Id,
          Mov,
          MovID,
          Sucursal,
          FechaEmision,
          Cuenta,
          Nombre,
          Estatus,
          EsCancelacion,
          Moneda,
          TipoCambio,
          ImporteTotal,
          FluctuacionCambiariaMN,
          ImporteTotalMN,
          AuxiliarModulo,
          AuxiliarMov
        )