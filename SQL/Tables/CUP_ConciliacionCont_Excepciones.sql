SET ANSI_NULLS, ANSI_WARNINGS ON;

IF OBJECT_ID('dbo.CUP_ConciliacionCont_Excepciones', 'U') IS NOT NULL 
  DROP TABLE dbo.CUP_ConciliacionCont_Excepciones; 

GO

-- =============================================
-- Created by:    Enrique Sierra Gtez
-- Creation Date: 2016-11-04
--
-- Description: Tabla encargada de contener
-- los excepciones que la herramienta de conciliacion
-- debe tener en cuenta a la hora de preparar la informacion
-- =============================================

CREATE TABLE dbo.CUP_ConciliacionCont_Excepciones
(
  ID INT PRIMARY KEY NOT NULL IDENTITY(1,1), 
  TipoConciliacion INT NOT NULL 
                   CONSTRAINT FK_CUP_ConciliacionCont_Excepciones_TipoConciliacion 
                   FOREIGN KEY 
                   REFERENCES CUP_ConciliacionCont_Tipos ( ID ),
  TipoExcepcion INT 
                CONSTRAINT FK_CUP_ConciliacionCont_Excepciones_TipoExcepcion
                FOREIGN KEY 
                REFERENCES CUP_ConciliacionCont_ExcepcionesTipos ( ID ),
  Valor VARCHAR(100) NOT NULL,
  Empleado INT NOT NULL,
  FechaAlta DATETIME NOT NULL
            CONSTRAINT [DF_CUP_ConciliacionCont_Excepciones_FechaAlta] DEFAULT GETDATE() 
 CONSTRAINT AK_CUP_ConciliacionCont_Excepciones 
 UNIQUE (
    TipoConciliacion,
    TipoExcepcion,
    Valor
  )  
) 


CREATE NONCLUSTERED INDEX [IX_CUP_ConciliacionCont_Excepciones_TipoConciliacion_TipoExcepcion]
ON [dbo].[CUP_ConciliacionCont_Excepciones] ( TipoConciliacion, TipoExcepcion )
INCLUDE ( 
           ID,
           Valor
        )

CREATE NONCLUSTERED INDEX [IX_CUP_ConciliacionCont_Excepciones_Valor]
ON [dbo].[CUP_ConciliacionCont_Excepciones] ( Valor)
INCLUDE ( 
           ID,
           TipoConciliacion,
           TipoExcepcion
        )