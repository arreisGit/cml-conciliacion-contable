SET ANSI_NULLS, ANSI_WARNINGS ON;

GO

IF EXISTS (SELECT * 
		   FROM SYSOBJECTS 
		   WHERE ID = OBJECT_ID('dbo.CUP_SPI_ConciliacionCont_AuxCont') AND 
				 TYPE = 'P')
BEGIN
  DROP PROCEDURE dbo.CUP_SPI_ConciliacionCont_AuxCont 
END	


GO

-- =============================================
-- Created by:    Enrique Sierra Gtez
-- Creation Date: 2016-10-13
-- Last Modified: 2016-10-20
--
-- Description: Obtiene los auxiliares de
-- Cont con suficiente informacion para
-- poder hacer el cruce contra el Modulo de un
-- ejercicio/periodo
-- 
-- Example: EXEC CUP_SPI_ConciliacionCont_AuxCont 'CXP', 2016, 9
-- =============================================


CREATE PROCEDURE dbo.CUP_SPI_ConciliacionCont_AuxCont
  @Modulo CHAR(5),
  @Ejercicio INT,
  @Periodo INT
AS BEGIN 

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
    c.ID,
    d.Cuenta,
    Descripcion = ISNULL(Cta.Descripcion,''),
    CentroCostos = ISNULL(d.Subcuenta,''),
    Debe  = SUM(ISNULL(d.Debe,0)),
    Haber = SUM(ISNULL(d.Haber,0)), 
    Neto = SUM(CASE ISNULL(Cta.EsAcreedora,0)
              WHEN 1 THEN 
                ISNULL(d.Haber,0) - ISNULL(d.Debe,0)
              ELSE
                ISNULL(d.Debe,0) - ISNULL(Haber,0)
            END),
    Sucursal = d.SucursalContable,
    d.FechaContable,
    c.Mov,
    c.MovId,
    Referencia= ISNULL(c.Referencia,''),
    OrigenModulo = c.OrigenTipo,
    OrigenModuloID = mf.OID,
    c.Origen,
    c.OrigenId,
    AuxiliarModulo = ISNULL(origenCont.AuxModulo,''),
    AuxiliarMov = ISNULL(origenCont.AuxMov,'')
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
  LEFT JOIN CUP_CxOrigenContable origenCont ON origenCont.Modulo = c.OrigenTipo
                                           AND origenCont.Mov   = c.Origen

  WHERE 
    c.Estatus = 'CONCLUIDO'
  AND YEAR(d.FechaContable) = @Ejercicio
  AND MONTH(d.FechaContable) = @Periodo
  GROUP BY
    c.ID,
    d.Cuenta,
    ISNULL(Cta.Descripcion,''),
    ISNULL(d.Subcuenta,''),
    d.SucursalContable,
    d.FechaContable,
    c.Mov,
    c.MovId,
    ISNULL(c.Referencia,''),
    c.OrigenTipo,
    mf.OID,
    c.Origen,
    c.OrigenId,
    ISNULL(origenCont.AuxModulo,''),
    ISNULL(origenCont.AuxMov,'')
END