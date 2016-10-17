SET ANSI_NULLS, ANSI_WARNINGS ON;

IF OBJECT_ID('dbo.CUP_CxRelacionAuxiliarModulo', 'U') IS NOT NULL 
  DROP TABLE dbo.CUP_CxRelacionAuxiliarModulo; 

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

IF OBJECT_ID('dbo.CUP_CxRelacionAuxiliarModulo', 'U') IS NOT NULL 
  DROP TABLE dbo.CUP_CxRelacionAuxiliarModulo; 

CREATE TABLE dbo.CUP_CxRelacionAuxiliarModulo
(
  ID INT PRIMARY KEY IDENTITY(1,1) NOT NULL,
	AuxModulo CHAR(5)  NOT NULL,
	AuxMov    CHAR(20) NOT NULL,
  Modulo    CHAR(5)  NOT NULL,
  Mov       CHAR(20) NOT NULL,
  CONSTRAINT AK_CUP_CxRelacionAuxiliarModulo_Modulo_Mov UNIQUE 
                                                       (
                                                         Modulo,
                                                         Mov
                                                       )  
) 


CREATE NONCLUSTERED INDEX [IX_CUP_CxRelacionAuxiliarModulo_Modulo_Mov]
ON [dbo].[CUP_CxRelacionAuxiliarModulo] ( Modulo, Mov )
INCLUDE ( 
          ID,
          AuxModulo,
          AuxMov
        )

CREATE NONCLUSTERED INDEX [IX_CUP_CxRelacionAuxiliarModulo_AuxModulo_AuxMov]
ON [dbo].[CUP_CxRelacionAuxiliarModulo] ( AuxModulo, AuxMov )
INCLUDE ( 
          ID,
          Modulo,
          Mov
        )