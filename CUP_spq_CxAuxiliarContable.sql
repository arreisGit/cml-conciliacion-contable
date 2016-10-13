DECLARE 
  @Ejercicio INT = 2016,
  @Periodo INT = 9,
  @Modulo CHAR(5)  = 'CXP',
  @FechaInicio DATE

  SET @FechaInicio = CAST((CAST(@Ejercicio AS VARCHAR) + '-' + CAST(@Periodo AS VARCHAR) + '-01') AS DATE)

BEGIN

  -- Contiene las cuentas contables de las que se obtendra
  -- el auxiliar.
  DECLARE @CtasCont  TABLE
  (
    Cuenta CHAR(20) NOT NULL  PRIMARY KEY
              
  )

  IF @Modulo = 'CXP'
  BEGIN

    INSERT INTO @CtasCont ( Cuenta)
    VALUES
      ('211-100-000-0000'), -- Proveedores Nacionales	
      ('211-200-000-0000'), -- Proveedores de Importacion	
      ('211-500-000-0000'), -- Proveedores Interempresas(No Usar)	
      ('211-600-001-0000'), -- Alutodo SA de CV	
      ('211-600-002-0000'), -- Metales Diaz SA de CV   	
      ('211-600-003-0000'), -- Servicios Cuprum SA de CV	
    	('211-600-004-0000'), -- Cuprum SA de CV
    	('211-600-005-0000'), -- Tiendas Cuprum SA de CV	
      ('211-600-006-0000'), -- Grupo Cuprum SA de CV   	
    	('211-600-009-0000')  -- Cuprum Fab SA de CV	
    	
  END


  SELECT 
    d.Cuenta,
    Cta.Descripcion,
    CentroCostos = ISNULL(d.Subcuenta,''),
    Debe  = ISNULL(d.Debe,0),
    Haber = ISNULL(d.Haber,0), 
    Sucursal = d.SucursalContable,
    d.FechaContable,
    c.ID,
    c.Mov,
    c.MovId,
    c.Referencia,
    OrigenModulo = c.OrigenTipo,
    OrigenModuloID = mf.OID,
    c.Origen,
    c.OrigenId
  FROM 
    @CtasCont cL
  JOIN Cta ON Cta.Cuenta = cL.Cuenta
  JOIN ContD d On d.Cuenta = cL.Cuenta
  JOIN Cont c ON c.ID = d.ID
  LEFT JOIN MovFlujo mf ON mf.DModulo = 'CONT'
                       AND mf.DID  = c.ID
                       AND mf.OModulo = c.OrigenTipo
                       AND mf.OMov = c.Origen
                       AND mf.OMovID = c.OrigenID  

  WHERE 
    c.Estatus = 'CONCLUIDO'
  AND YEAR(d.FechaContable) = @Ejercicio
  AND MONTH(d.FechaContable) = @Periodo


END