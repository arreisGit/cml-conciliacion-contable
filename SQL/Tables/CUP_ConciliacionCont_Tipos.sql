SET ANSI_NULLS, ANSI_WARNINGS ON;

IF OBJECT_ID('dbo.CUP_ConciliacionCont_Tipos', 'U') IS NOT NULL 
  DROP TABLE dbo.CUP_ConciliacionCont_Tipos; 

GO

-- =============================================
-- Created by:    Enrique Sierra Gtez
-- Creation Date: 2016-10-26
--
-- Description: Tabla encargada de contener
-- los tipos de Conciliaciones Contables
-- para los cuales esta preparado el sistema
-- de realizar una consulta.
--
-- =============================================

CREATE TABLE dbo.CUP_ConciliacionCont_Tipos
(
  ID INT PRIMARY KEY NOT NULL IDENTITY(1,1),
  Descripcion VARCHAR(100) NOT NULL,
  Empleado INT NOT NULL,
  FechaAlta DATETIME NOT NULL
            CONSTRAINT [DF_CUP_ConciliacionCont_Tipos_FechaAlta] DEFAULT GETDATE() 
) 