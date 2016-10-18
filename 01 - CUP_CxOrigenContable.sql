SET ANSI_NULLS, ANSI_WARNINGS ON;

IF OBJECT_ID('dbo.CUP_CxOrigenContable', 'U') IS NOT NULL 
  DROP TABLE dbo.CUP_CxOrigenContable; 

GO

-- =============================================
-- Created by:    Enrique Sierra Gtez
-- Creation Date: 2016-10-14
-- Last Modified: 2016-10-14 
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

CREATE TABLE dbo.CUP_CxOrigenContable
(
  ID INT PRIMARY KEY IDENTITY(1,1) NOT NULL,
	AuxModulo CHAR(5)  NOT NULL,
	AuxMov    CHAR(20) NOT NULL,
  Modulo    CHAR(5)  NOT NULL,
  Mov       CHAR(20) NOT NULL,
  ValidarOrigen BIT  NOT NULL
                CONSTRAINT [DF_CUP_CxOrigenContable_ValidarOrigen]
                DEFAULT 0,
  OrigenTipo CHAR(5) NULL,
  Origen     CHAR(20) NULL,
  CONSTRAINT AK_CUP_CxOrigenContable_Modulo_Mov UNIQUE 
                                                       (
                                                         Modulo,
                                                         Mov,
                                                         ValidarOrigen,
                                                         OrigenTipo,
                                                         Origen
                                                       )  
) 


CREATE NONCLUSTERED INDEX [IX_CUP_CxOrigenContable_Modulo_Mov]
ON [dbo].[CUP_CxOrigenContable] ( Modulo, Mov )
INCLUDE ( 
          ID,
          AuxModulo,
          AuxMov,
          ValidarOrigen,
          OrigenTipo,
          Origen
        )

CREATE NONCLUSTERED INDEX [IX_CUP_CxOrigenContable_AuxModulo_AuxMov]
ON [dbo].[CUP_CxOrigenContable] ( AuxModulo, AuxMov )
INCLUDE ( 
          ID,
          Modulo,
          Mov,
          ValidarOrigen,
          OrigenTipo,
          Origen
        )