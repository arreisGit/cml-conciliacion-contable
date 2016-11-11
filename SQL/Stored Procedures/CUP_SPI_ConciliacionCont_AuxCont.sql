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
--
-- Description: Obtiene los auxiliares de
-- Cont con suficiente informacion para
-- poder hacer el cruce contra los auxiliares
-- CX  en un ejercicio/periodo especifico
-- 
-- Example: EXEC CUP_SPI_ConciliacionCont_AuxCont 63527, 3, 2016, 10
-- =============================================


CREATE PROCEDURE dbo.CUP_SPI_ConciliacionCont_AuxCont
  @Empleado INT,
  @Tipo INT,
  @Ejercicio INT,
  @Periodo INT
AS BEGIN 

  SET NOCOUNT ON;

  DELETE CUP_ConciliacionCont_AuxCont
  WHERE Empleado = @Empleado

  INSERT INTO CUP_ConciliacionCont_AuxCont
  (
    Empleado,
    ID,
    Cuenta,
    Descripcion,
    CentroCostos,
    Debe,
    Haber,
    Neto,
    Sucursal,
    FechaContable,
    Mov,
    MovId,
    Referencia,
    OrigenModulo,
    OrigenModuloID,
    OrigenMov,
    OrigenMovId,
    AuxiliarModulo,
    AuxiliarMov
  )
  SELECT 
    Empleado = @Empleado,
    c.ID,
    d.Cuenta,
    Descripcion = ISNULL(Cta.Descripcion,''),
    CentroCostos = ISNULL(d.Subcuenta,''),
    Debe  = SUM(ISNULL(d.Debe,0)),
    Haber = SUM(ISNULL(d.Haber,0)), 
    Neto = SUM(CASE
                WHEN @Tipo <> 3 -- Saldos CXC  
                AND ISNULL(Cta.EsAcreedora,0) =  1 THEN 
                  ISNULL(d.Haber,0) - ISNULL(d.Debe,0)
                ELSE
                  ISNULL(d.Debe,0) - ISNULL(Haber,0)
              END),
    Sucursal = d.SucursalContable,
    d.FechaContable,
    c.Mov,
    c.MovId,
    Referencia = cf.Referencia,
    OrigenModulo = c.OrigenTipo,
    OrigenModuloID = mf.OID,
    c.Origen,
    c.OrigenId,
    AuxiliarModulo = ISNULL(origenCont.AuxModulo,''),
    AuxiliarMov = ISNULL(origenCont.AuxMov,'')
  FROM 
    CUP_ConciliacionCont_Tipo_CuentasContables cL
  JOIN Cta ON Cta.Cuenta = cL.Cuenta
  JOIN ContD d On d.Cuenta = cL.Cuenta
  JOIN Cont c ON c.ID = d.ID
  LEFT JOIN MovFlujo mf ON mf.DModulo = 'CONT'
                       AND mf.DID  = c.ID
                       AND mf.OModulo = c.OrigenTipo
                       AND mf.OMov = c.Origen
                       AND mf.OMovID = c.OrigenID
  LEFT JOIN CUP_ConciliacionCont_Tipo_OrigenContable origenCont ON origenCont.Tipo = @Tipo
                                                               AND origenCont.Modulo = c.OrigenTipo
                                                               AND origenCont.Mov   = c.Origen
  -- Clean Fields
  OUTER APPLY (
                 SELECT 
                   Referencia = ISNULL(REPLACE(REPLACE(REPLACE(c.Referencia,CHAR(13),''),CHAR(10),''),CHAR(9),''),'')
              ) cf

  WHERE 
    cl.Tipo = @Tipo
  AND c.Estatus = 'CONCLUIDO'
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
    cf.Referencia,
    c.OrigenTipo,
    mf.OID,
    c.Origen,
    c.OrigenId,
    ISNULL(origenCont.AuxModulo,''),
    ISNULL(origenCont.AuxMov,'')

END