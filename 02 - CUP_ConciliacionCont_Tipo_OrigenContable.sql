SET ANSI_NULLS, ANSI_WARNINGS ON;

IF OBJECT_ID('dbo.CUP_ConciliacionCont_Tipo_OrigenContable', 'U') IS NOT NULL 
  DROP TABLE dbo.CUP_ConciliacionCont_Tipo_OrigenContable; 

GO

-- =============================================
-- Created by:    Enrique Sierra Gtez
-- Creation Date: 2016-10-14
--
-- Description: Tabla encargada de contener
-- la relacion entre los Auxiliares de Cxc y Cxp
-- contra los movimientos en el modulo
-- que hacen la afectacion contable.
-- 
-- Example: Los movimientos de Cxp | Creedito 
-- Proveedor pueden venir de Devoluciones Compra,
-- Bonificaciones Compra, o inclusive directamente
-- desde cxp. Cualquiera de estos movs debe de afectar
-- el saldo del proveedor en la contabilidad.
--
-- =============================================

CREATE TABLE dbo.CUP_ConciliacionCont_Tipo_OrigenContable
(
  ID INT PRIMARY KEY IDENTITY(1,1) NOT NULL,
  Tipo INT  NOT NULL
            CONSTRAINT FK_CUP_ConciliacionCont_Tipos 
            FOREIGN KEY 
            REFERENCES CUP_ConciliacionCont_Tipos ( ID ),
	AuxModulo CHAR(5)  NOT NULL,
	AuxMov    CHAR(20) NOT NULL,
  Modulo    CHAR(5)  NOT NULL,
  Mov       CHAR(20) NOT NULL,
  Factor     SMALLINT NOT NULL,    
  UsarAuxiliarNeto BIT NOT NULL
                   CONSTRAINT [DF_CUP_ConciliacionCont_Tipo_OrigenContable_UsarAuxiliarNeto]
                   DEFAULT 0,
  ValidarOrigen BIT  NOT NULL
                CONSTRAINT [DF_CUP_ConciliacionCont_Tipo_OrigenContable_ValidarOrigen]
                DEFAULT 0,
  OrigenTipo CHAR(5) NULL,
  Origen     CHAR(20) NULL,
  CONSTRAINT AK_CUP_ConciliacionCont_Tipo_OrigenContable_Tipo_Modulo_Mov 
  UNIQUE (
    Tipo,
    Modulo,
    Mov,
    ValidarOrigen,
    OrigenTipo,
    Origen
  )  
) 

CREATE NONCLUSTERED INDEX [IX_CUP_ConciliacionCont_Tipo_OrigenContable_Tipo]
ON [dbo].[CUP_ConciliacionCont_Tipo_OrigenContable] ( Tipo )
INCLUDE ( 
          AuxModulo,
          AuxMov
        )

CREATE NONCLUSTERED INDEX [IX_CUP_ConciliacionCont_Tipo_OrigenContable_Tipo_AuxModulo_AuxMov]
ON [dbo].[CUP_ConciliacionCont_Tipo_OrigenContable] ( Tipo, AuxModulo, AuxMov )
INCLUDE ( 
          ID,
          Modulo,
          Mov,
          Factor,
          UsarAuxiliarNeto,
          ValidarOrigen,
          OrigenTipo,
          Origen
        )