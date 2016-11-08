IF OBJECT_ID('dbo.CUP_ConciliacionCont', 'U') IS NOT NULL 
  DROP TABLE dbo.CUP_ConciliacionCont 

IF OBJECT_ID('dbo.CUP_ConciliacionCont_AuxModulo', 'U') IS NOT NULL 
  DROP TABLE dbo.CUP_ConciliacionCont_AuxModulo; 

IF OBJECT_ID('dbo.CUP_ConciliacionCont_AuxCont', 'U') IS NOT NULL 
  DROP TABLE dbo.CUP_ConciliacionCont_AuxCont; 

IF OBJECT_ID('dbo.CUP_ConciliacionCont_AuxCx', 'U') IS NOT NULL 
  DROP TABLE dbo.CUP_ConciliacionCont_AuxCx; 

IF OBJECT_ID('dbo.CUP_ConciliacionCont_Excepciones', 'U') IS NOT NULL 
  DROP TABLE dbo.CUP_ConciliacionCont_Excepciones; 

IF OBJECT_ID('dbo.CUP_ConciliacionCont_ExcepcionesTipos', 'U') IS NOT NULL 
  DROP TABLE dbo.CUP_ConciliacionCont_ExcepcionesTipos; 

IF OBJECT_ID('dbo.CUP_ConciliacionCont_Tipo_CuentasContables', 'U') IS NOT NULL 
  DROP TABLE dbo.CUP_ConciliacionCont_Tipo_CuentasContables;

IF OBJECT_ID('dbo.CUP_ConciliacionCont_Tipo_OrigenContable', 'U') IS NOT NULL 
  DROP TABLE dbo.CUP_ConciliacionCont_Tipo_OrigenContable;

IF OBJECT_ID('dbo.CUP_ConciliacionCont_Tipos', 'U') IS NOT NULL 
  DROP TABLE dbo.CUP_ConciliacionCont_Tipos; 