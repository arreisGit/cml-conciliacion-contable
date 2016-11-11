TRUNCATE TABLE CUP_ConciliacionCont_Tipo_CuentasContables

INSERT INTO 
  CUP_ConciliacionCont_Tipo_CuentasContables
(
  Tipo,
  Cuenta
)
VALUES
  /* Saldo Proveedores */
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
  /* Iva Por Acreditar */
  ,( 2, '119-210-000-0000') -- IVA 16% Por Acreditar,
  /* Saldo Clientes */
  ,( 3, '113-100-000-0000') -- Clientes GDL
  ,( 3, '113-200-000-0000') -- Clientes MEX
  ,( 3, '113-300-000-0000') -- Clientes MTY
  ,( 3, '113-400-000-0000') -- Clientes SNG
  ,( 3, '113-401-000-0000') -- Clientes CHIH
  ,( 3, '113-402-000-0000') -- Clientes QRO
  ,( 3, '113-403-000-0000') -- Clientes TORR
  ,( 3, '113-404-000-0000') -- Clientes  Alutodo Fusion TORR,CHIH,QRO
  ,( 3, '113-405-000-0000') -- Clientes CD.Juarez
  ,( 3, '113-601-000-0000') -- Metales Diaz SA de CV
  ,( 3, '113-602-000-0000') -- Tiendas Cuprum SA de CV
  ,( 3, '113-603-000-0000') -- Cuprum SA de CV
  ,( 3, '113-604-000-0000') -- Alutodo (NFX) SA de CV
  ,( 3, '113-605-000-0000') -- Carga Inicial de Clientes Alutodo
  ,( 3, '113-701-000-0000') -- Cuenta X Cobrar a DAISA
  ,( 3, '113-800-600-0000') -- Clientes Nacionales QRO
  ,( 3, '213-100-000-0000') -- Anticipo Clientes GDL
  ,( 3, '213-200-000-0000') -- Anticipo Clientes MEX
  ,( 3, '213-300-000-0000') -- Anticipo Clientes MTY
  ,( 3, '213-400-000-0000') -- Anticipo Clientes SNG
  ,( 3, '213-500-000-0000') -- Anticipo Clientes CHIH
  ,( 3, '213-600-000-0000') -- Anticipo Clientes TORR
  ,( 3, '213-700-000-0000') -- Anticipo Clientes QRO
  ,( 3, '213-701-000-0000') -- Anticipo Clientes CD.Juarez

SELECT 
  ID,
  Tipo,
  Cuenta
FROM 
  CUP_ConciliacionCont_Tipo_CuentasContables