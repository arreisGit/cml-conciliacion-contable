INSERT INTO 
  CUP_ConciliacionCont_Tipo_CuentasContables
(
  Tipo,
  Cuenta
)
VALUES
  ( 1, '211-100-000-0000'), -- Proveedores Nacionales	
  ( 1, '211-200-000-0000'), -- Proveedores de Importacion	
  ( 1, '211-500-000-0000'), -- Proveedores Interempresas( 1, No Usar)	
  ( 1, '211-600-001-0000'), -- Alutodo SA de CV	
  ( 1, '211-600-002-0000'), -- Metales Diaz SA de CV   	
  ( 1, '211-600-003-0000'), -- Servicios Cuprum SA de CV	
  ( 1, '211-600-004-0000'), -- Cuprum SA de CV
  ( 1, '211-600-005-0000'), -- Tiendas Cuprum SA de CV	
  ( 1, '211-600-006-0000'), -- Grupo Cuprum SA de CV   	
  ( 1, '211-600-009-0000')  -- Cuprum Fab SA de CV	

SELECT 
  ID,
  Tipo,
  Cuenta
FROM 
  CUP_ConciliacionCont_Tipo_CuentasContables