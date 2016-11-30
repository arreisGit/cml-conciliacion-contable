SET ANSI_NULLS, ANSI_WARNINGS ON;

IF OBJECT_ID('dbo.CUP_ConciliacionCont_ExcepcionesTipos', 'U') IS NOT NULL 
  DROP TABLE dbo.CUP_ConciliacionCont_ExcepcionesTipos; 

GO

/* =============================================
  Created by:    Enrique Sierra Gtez
  Creation Date: 2016-11-04

  Description: Tabla encargada de contener
  los tipos de excepciones disponibles para 
  su consideracion en el proceso de conciliacion
  contable
 ============================================= */

CREATE TABLE dbo.CUP_ConciliacionCont_ExcepcionesTipos
(
  ID INT PRIMARY KEY NOT NULL IDENTITY(1,1), 
  Descripcion VARCHAR(100) NOT NULL,
  Empleado INT NOT NULL,
  FechaAlta DATETIME NOT NULL
            CONSTRAINT [DF_CUP_ConciliacionCont_ExcepcionesTipos_FechaAlta] DEFAULT GETDATE() 
 CONSTRAINT AK_CUP_ConciliacionCont_ExcepcionesTipos
 UNIQUE (
    Descripcion
  )  
) 