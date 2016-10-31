SET ANSI_NULLS, ANSI_WARNINGS ON;

IF OBJECT_ID('dbo.CUP_ConciliacionCont_Tipo_CuentasContables', 'U') IS NOT NULL 
  DROP TABLE dbo.CUP_ConciliacionCont_Tipo_CuentasContables; 

GO

-- =============================================
-- Created by:    Enrique Sierra Gtez
-- Creation Date: 2016-10-27
--
-- Description: Tabla encargada de contener
-- las cuentas contables utilizadas durante
-- una conciliacion.
-- 
-- =============================================

CREATE TABLE dbo.CUP_ConciliacionCont_Tipo_CuentasContables
(
  ID INT PRIMARY KEY IDENTITY(1,1) NOT NULL,
  Tipo INT  NOT NULL
            CONSTRAINT FK_CUP_ConciliacionCont_Tipo_CuentasContables_Tipos 
            FOREIGN KEY 
            REFERENCES CUP_ConciliacionCont_Tipos ( ID ),
  Cuenta CHAR(20) NOT NULL,
  CONSTRAINT AK_CUP_ConciliacionCont_Tipo_CuentasContables_Tipo_Cuenta
  UNIQUE (
    Tipo,
    Cuenta
  )  
) 

CREATE NONCLUSTERED INDEX [IX_CUP_ConciliacionCont_Tipo_CuentasContable_Tipo]
ON [dbo].[CUP_ConciliacionCont_Tipo_CuentasContables] ( Tipo )
INCLUDE ( 
          Cuenta
        )

CREATE NONCLUSTERED INDEX [IX_CUP_ConciliacionCont_Tipo_CuentasContables_Tipo_Cuenta]
ON [dbo].[CUP_ConciliacionCont_Tipo_CuentasContables] ( Tipo, Cuenta )