SET ANSI_NULLS, ANSI_WARNINGS ON;

IF OBJECT_ID('dbo.CUP_ConciliacionCont.', 'U') IS NOT NULL 
  DROP TABLE dbo.CUP_ConciliacionCont 

GO

-- =============================================
-- Created by:    Enrique Sierra Gtez
-- Creation Date: 2016-10-26
--
-- Description: Tabla encargada de contener
-- guardar la relacion de el empleado que esta 
-- consultando la herramienta de conciliacion 
-- contable, junto con el tipo de consulta 
-- que esta realizando.
--
-- =============================================

CREATE TABLE dbo.CUP_ConciliacionCont
(
  Empleado INT PRIMARY KEY NOT NULL,
  Tipo INT  FOREIGN KEY REFERENCES CUP_ConciliacionCont_Tipos ( ID )
) 
